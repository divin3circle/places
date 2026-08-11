//
//  ItineraryChatViewModel.swift
//  Places
//
//  Drives the itinerary chat: builds the system prompt from the TripConfig,
//  streams the structured itinerary (then follow-up text) through the selected
//  ItineraryEngine, and exposes `isGenerating` so the view can hide the input bar
//  mid-stream. Persistence is added in a later milestone.
//

import Foundation
import Observation
import SwiftData

struct ItineraryChatItem: Identifiable {
    enum Role { case user, assistant }
    enum Kind {
        case text(String)
        case itinerary(ItineraryDisplay?)
    }

    let id: UUID
    let role: Role
    var kind: Kind

    init(id: UUID = UUID(), role: Role, kind: Kind) {
        self.id = id
        self.role = role
        self.kind = kind
    }
}

@Observable
@MainActor
final class ItineraryChatViewModel {
    let config: TripConfig
    var items: [ItineraryChatItem] = []
    var isGenerating = false
    var errorMessage: String?

    // "Convert to trip" state
    var isSaving = false
    var savedTripID: UUID?
    /// The persisted trip for THIS conversation, so re-saving after an edit updates
    /// it in place instead of inserting a duplicate.
    private var savedTrip: SavedTrip?

    let registry = PlaceRegistry()
    private var engine: ItineraryEngine?
    private var task: Task<Void, Never>?
    private var started = false
    /// The most recent complete itinerary snapshot.
    private var lastFullItinerary: GeneratedItinerary?
    /// Every completed itinerary version (original + each edit), captured for saving.
    private var itineraryVersions: [(itinerary: GeneratedItinerary, note: String?)] = []

    private let grounding: GroundingProviding
    /// The grounding palette for this session (place names → coords/images/prices).
    private var catalog: GroundingCatalog = .empty
    /// Restored engine session memory when resuming a saved trip (nil for new trips).
    private var resumeTranscript: Data?
    /// True when editing an existing trip — skip the initial generation.
    private var isResumed = false
    /// Bookmarked place names to bias generation toward (when config.useSavedPlaces).
    /// Set by the view before `start()`.
    var preferredPlaceNames: [String] = []

    init(config: TripConfig, grounding: GroundingProviding = SupabaseGroundingRepository()) {
        self.config = config
        self.grounding = grounding
    }

    /// Resume an existing saved trip for editing: seed the chat with its current
    /// itinerary + version history and restore the engine's session memory so the
    /// next message refines this trip in place.
    convenience init(resuming trip: SavedTrip, grounding: GroundingProviding = SupabaseGroundingRepository()) {
        let config = trip.config ?? TripConfig(
            travelers: 2, hasKids: false, expectation: "",
            multipleCountries: false,
            durationDays: trip.latestItinerary?.days.count ?? 3, durationLabel: "")
        self.init(config: config, grounding: grounding)
        savedTrip = trip
        savedTripID = trip.id
        resumeTranscript = trip.transcriptData
        isResumed = true
        itineraryVersions = trip.versions
            .sorted { $0.order < $1.order }
            .compactMap { version in version.itinerary.map { ($0, version.note) } }
        lastFullItinerary = itineraryVersions.last?.itinerary
        if let latest = lastFullItinerary {
            items = [ItineraryChatItem(role: .assistant, kind: .itinerary(ItineraryDisplay(full: latest)))]
        }
    }

    /// Called once, after the model preference is known. Generation stays in
    /// memory — nothing is persisted until the user taps "Convert to trip".
    func start(kind: AIModelKind) {
        guard !started else { return }
        started = true

        Task {
            // Fetch the live grounding palette before generating; degrade to an
            // empty catalog on failure (generation still runs, just without pins).
            let catalog: GroundingCatalog
            do { catalog = GroundingCatalog(places: try await grounding.fetchGroundingPlaces()) }
            catch {
                catalog = .empty
                ItineraryLog.debug("grounding fetch failed: \(error)")
            }
            catalog.resolvedPlaces.forEach(registry.register)
            self.catalog = catalog

            // When "use saved places" is on, fold the bookmarks into the trip's
            // wish so BOTH engines prioritise them (the on-device prompt and the
            // cloud edge function both read config.expectation).
            var effectiveConfig = config
            if config.useSavedPlaces, !preferredPlaceNames.isEmpty {
                let pref = "Prioritise these saved places where they fit: \(preferredPlaceNames.joined(separator: ", "))."
                effectiveConfig.expectation = config.trimmedExpectation.isEmpty
                    ? pref : "\(config.trimmedExpectation) \(pref)"
            }

            // Trip-context tool: fold static local context (weather / getting around /
            // money) into the wish so both engines use it. Best-effort — never blocks.
            let region = config.multipleCountries ? "East Africa" : "Kenya"
            let month = config.startDate.map { $0.formatted(.dateTime.month(.wide)) }
            if let intel = try? await TripIntelClient.fetch(destination: region, month: month) {
                effectiveConfig.expectation = effectiveConfig.trimmedExpectation.isEmpty
                    ? intel.promptContext : "\(effectiveConfig.expectation) \(intel.promptContext)"
            }

            engine = ItineraryEngineFactory.make(
                kind: kind,
                config: effectiveConfig,
                systemPrompt: Self.systemPrompt(for: effectiveConfig),
                registry: registry,
                catalog: catalog,
                resumeTranscript: resumeTranscript
            )
            engine?.prewarm()
            // Resumed trips already have an itinerary — wait for the user's edit.
            if !isResumed { generateInitial() }
        }
    }

    private func generateInitial() {
        guard let engine else { return }
        let request = """
        Create a \(config.durationDays)-day itinerary now, based on the trip details in your instructions. \
        Use findPlaces to look up places by kind (e.g. wildlife, city, beach), then build the itinerary \
        using only the exact place names it returns. \
        Produce exactly \(config.durationDays) day(s).
        """
        let assistantId = UUID()
        items.append(ItineraryChatItem(id: assistantId, role: .assistant, kind: .itinerary(nil)))
        isGenerating = true
        errorMessage = nil
        task = Task {
            do {
                for try await itinerary in engine.generateItinerary(request: request) {
                    lastFullItinerary = itinerary
                    setKind(id: assistantId, .itinerary(ItineraryDisplay(full: itinerary)))
                }
                groundFinalPrices(id: assistantId)
                recordVersion(note: "Original")
            } catch is CancellationError {
                // dropped intentionally
            } catch {
                errorMessage = error.localizedDescription
                setKind(id: assistantId, .text("Couldn't generate the itinerary: \(error.localizedDescription)"))
            }
            isGenerating = false
        }
    }

    /// A follow-up message is an EDIT: regenerate the whole itinerary (new version).
    func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let engine, !isGenerating, let current = lastFullItinerary else { return }
        items.append(ItineraryChatItem(role: .user, kind: .text(trimmed)))
        let assistantId = UUID()
        items.append(ItineraryChatItem(id: assistantId, role: .assistant, kind: .itinerary(nil)))
        isGenerating = true
        task = Task {
            do {
                for try await itinerary in engine.refine(current: current, instruction: trimmed) {
                    lastFullItinerary = itinerary
                    setKind(id: assistantId, .itinerary(ItineraryDisplay(full: itinerary)))
                }
                groundFinalPrices(id: assistantId)
                recordVersion(note: trimmed)
            } catch is CancellationError {
                // dropped intentionally
            } catch {
                setKind(id: assistantId, .text("Sorry — couldn't update the itinerary: \(error.localizedDescription)"))
            }
            isGenerating = false
        }
    }

    /// Once a stream finishes, replace model price estimates with grounded DB
    /// prices where the place is known, and refresh the shown message.
    private func groundFinalPrices(id: UUID) {
        guard let final = lastFullItinerary else { return }
        let grounded = final.withGroundedPrices { catalog.groundedPriceUSD(for: $0) }
        lastFullItinerary = grounded
        setKind(id: id, .itinerary(ItineraryDisplay(full: grounded)))
    }

    func stop() {
        task?.cancel()
        engine?.stop()
        isGenerating = false
    }

    private func setKind(id: UUID, _ kind: ItineraryChatItem.Kind) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].kind = kind
    }

    /// Capture a completed itinerary as a new version; invalidates any prior save.
    private func recordVersion(note: String?) {
        guard let itinerary = lastFullItinerary,
              !(itinerary.title.isEmpty && itinerary.days.isEmpty) else { return }
        itineraryVersions.append((itinerary, note))
        savedTripID = nil   // content changed since any earlier save
    }

    // MARK: Convert to trip (on-demand persistence)

    var canSave: Bool { !isGenerating && !itineraryVersions.isEmpty && savedTripID == nil }

    func saveAsTrip(context: ModelContext) async {
        guard canSave, let latest = itineraryVersions.last?.itinerary else { return }
        isSaving = true
        // Let the saving UI render before the write.
        await Task.yield()

        let title = latest.title.isEmpty ? "New trip" : latest.title
        let cover = coverImageName(for: latest)
        let subtitle = "\(config.durationDays) day\(config.durationDays == 1 ? "" : "s")"

        let trip: SavedTrip
        if let existing = savedTrip {
            // Re-save after an edit → update the same trip in place (no duplicate).
            trip = existing
            trip.title = title
            trip.coverImageName = cover
            trip.subtitle = subtitle
            trip.transcriptData = engine?.transcriptData
            for old in trip.versions { context.delete(old) }
            trip.versions.removeAll()
        } else {
            trip = SavedTrip(
                title: title,
                coverImageName: cover,
                subtitle: subtitle,
                configData: (try? JSONEncoder().encode(config)) ?? Data(),
                transcriptData: engine?.transcriptData
            )
            context.insert(trip)
            savedTrip = trip
        }

        for (index, version) in itineraryVersions.enumerated() {
            let json = (try? JSONEncoder().encode(version.itinerary)) ?? Data()
            let saved = SavedItineraryVersion(order: index, itineraryJSON: json, note: version.note)
            saved.trip = trip
            trip.versions.append(saved)
            context.insert(saved)
        }
        try? context.save()

        savedTripID = trip.id
        isSaving = false
    }

    /// First resolvable place image across the itinerary, for the trip cover.
    /// Prefers the grounded remote URL (RemoteImage renders it); falls back to a
    /// local asset name only if a place somehow carries one instead.
    private func coverImageName(for itinerary: GeneratedItinerary) -> String? {
        for day in itinerary.days {
            for activity in day.activities {
                if let place = registry.resolve(activity.placeName),
                   let image = place.imageURL?.absoluteString ?? place.imageName {
                    return image
                }
            }
        }
        return nil
    }

    static func systemPrompt(for config: TripConfig) -> String {
        var lines = [
            "You are a warm, expert East-Africa travel concierge for the Places app.",
            "Design a practical, exciting day-by-day itinerary, then help the traveler refine it in conversation.",
            "Use the findPlaces tool to look up real, mappable places by kind (wildlife, city, beach, lake, culture) — call it at most once per kind you actually need. Then use ONLY the exact names it returns as each activity's placeName. Do not repeat a call for a kind you already looked up.",
            "",
            "Trip details:",
            "- Travelers: \(config.travelers)",
            "- Traveling with kids: \(config.hasKids ? "yes" : "no")",
            "- Duration: \(config.durationLabel) (\(config.durationDays) days)",
            config.multipleCountries
                ? "- Scope: may span multiple East-African countries"
                : "- Scope: keep to a single country",
        ]
        if !config.trimmedExpectation.isEmpty {
            lines.append("- Traveler's wish: \"\(config.trimmedExpectation)\"")
        }
        lines.append(contentsOf: [
            "",
            "For EACH activity include: a realistic local start time (24-hour HH:mm), a rough durationMinutes, one short practical note, and a price estimate for the whole party (\(config.travelers) traveler\(config.travelers == 1 ? "" : "s")) in USD — real ballpark figures for East Africa (park fees, meals, activities); amount 0 when free. List activities in time order.",
            "For EACH day add a one-line travelNote covering drive time or transfers.",
            "Add 3–5 short, practical trip tips (weather, getting around, money, what to pack).",
        ])
        return lines.joined(separator: "\n")
    }
}
