//
//  TripViewModel.swift
//  Places
//
//  Backs the full-screen TripView for a saved itinerary. Decodes the trip's
//  latest itinerary and re-resolves its place names to coordinates + imagery via
//  the same Supabase grounding layer used at generation time — so the map and
//  place thumbnails work even though resolved places aren't persisted.
//

import Foundation

@Observable @MainActor
final class TripViewModel {
    let trip: SavedTrip
    let itinerary: GeneratedItinerary
    let registry = PlaceRegistry()

    private let grounding: GroundingProviding
    private(set) var resolvedPlaces: [ResolvedPlace] = []
    private var didResolve = false

    init(trip: SavedTrip, grounding: GroundingProviding = SupabaseGroundingRepository()) {
        self.trip = trip
        self.itinerary = trip.latestItinerary
            ?? GeneratedItinerary(title: trip.title, summary: "", rationale: "", days: [])
        self.grounding = grounding
    }

    // MARK: Display

    var title: String { itinerary.title.isEmpty ? trip.title : itinerary.title }
    var summary: String { itinerary.summary }
    var rationale: String { itinerary.rationale }
    var days: [ItineraryDay] { itinerary.days }

    /// Prefer a resolved place image (matches the hero map), else the stored cover.
    var coverImage: String {
        resolvedPlaces.first?.imageURL?.absoluteString
            ?? trip.coverImageName
            ?? "onboarding1"
    }

    var durationDays: Int { trip.config?.durationDays ?? itinerary.days.count }
    var travelers: Int { trip.config?.travelers ?? 0 }
    var placeCount: Int { distinctPlaceNames.count }
    var editCount: Int { max(0, trip.versions.count - 1) }
    var createdLabel: String {
        trip.createdAt.formatted(.dateTime.month(.wide).day().year())
    }

    /// A compact meta line, e.g. "8 days · 2 travelers · 12 places".
    var metaLine: String {
        var parts = ["\(durationDays) day\(durationDays == 1 ? "" : "s")"]
        if travelers > 0 { parts.append("\(travelers) traveler\(travelers == 1 ? "" : "s")") }
        if placeCount > 0 { parts.append("\(placeCount) place\(placeCount == 1 ? "" : "s")") }
        return parts.joined(separator: " · ")
    }

    // MARK: Place resolution (map + thumbnails)

    /// Fetch the grounding palette once and register it, so `registry.resolve` can
    /// map the itinerary's place names to coordinates + imagery. Degrades quietly.
    func resolvePlaces() async {
        guard !didResolve else { return }
        didResolve = true
        do {
            let catalog = GroundingCatalog(places: try await grounding.fetchGroundingPlaces())
            catalog.resolvedPlaces.forEach(registry.register)
        } catch {
            ItineraryLog.debug("trip grounding failed: \(error)")
        }
        var seen = Set<String>()
        resolvedPlaces = distinctPlaceNames.compactMap { registry.resolve($0) }
            .filter { seen.insert($0.id).inserted }
    }

    /// Distinct place names in itinerary order.
    private var distinctPlaceNames: [String] {
        var seen = Set<String>()
        var out: [String] = []
        for day in itinerary.days {
            for activity in day.activities where !activity.placeName.isEmpty {
                if seen.insert(activity.placeName).inserted { out.append(activity.placeName) }
            }
        }
        return out
    }

    // MARK: Share

    /// A plain-text summary of the itinerary for the share sheet.
    var shareText: String {
        var lines = [title]
        if !summary.isEmpty { lines.append(summary) }
        lines.append("")
        for (i, day) in itinerary.days.enumerated() {
            lines.append("Day \(i + 1): \(day.title)")
            for activity in day.activities {
                let place = activity.placeName.isEmpty ? "" : " — \(activity.placeName)"
                lines.append("  • \(activity.title)\(place)")
            }
        }
        lines.append("")
        lines.append("Planned with Places.")
        return lines.joined(separator: "\n")
    }
}
