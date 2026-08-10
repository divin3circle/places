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
import CoreLocation

/// A rough, offline travel estimate between two grounded places (straight-line
/// distance → a walk/drive guess). Clearly approximate ("~").
nonisolated struct TravelLeg {
    let kilometers: Double
    let minutes: Int
    let isWalk: Bool

    var label: String {
        let dist = kilometers < 1
            ? "\(Int((kilometers * 1000).rounded())) m"
            : String(format: "%.0f km", kilometers)
        let time = minutes < 60 ? "~\(minutes) min" : "~\(minutes / 60)h \(minutes % 60)m"
        return "\(isWalk ? "Walk" : "Drive") · \(dist) · \(time)"
    }
    var symbol: String { isWalk ? "figure.walk" : "car.fill" }
}

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

    /// Straight-line travel estimate between two activities' resolved places.
    /// nil when either place is unknown or they're essentially the same spot.
    func leg(from: ItineraryActivity, to: ItineraryActivity) -> TravelLeg? {
        guard let a = registry.resolve(from.placeName),
              let b = registry.resolve(to.placeName),
              a.id != b.id else { return nil }
        let da = CLLocation(latitude: a.coordinate.latitude, longitude: a.coordinate.longitude)
        let db = CLLocation(latitude: b.coordinate.latitude, longitude: b.coordinate.longitude)
        let km = da.distance(from: db) / 1000
        guard km > 0.08 else { return nil }
        let isWalk = km <= 1.2
        // ~4.8 km/h walking, ~38 km/h effective driving (urban + regional blend).
        let minutes = max(1, Int(((km / (isWalk ? 4.8 : 38)) * 60).rounded()))
        return TravelLeg(kilometers: km, minutes: minutes, isWalk: isWalk)
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

    // MARK: Deep itinerary (times, prices, tips, budget)

    /// Display currency (USD until TripConfig carries a preference).
    var currency: Currency { .usd }

    var tips: [String] { itinerary.tips ?? [] }

    /// Formatted trip budget total, nil if nothing is priced.
    var tripTotal: String? {
        itinerary.estimatedTotal(in: currency).map { currency.format($0) }
    }

    func dayTotal(_ day: ItineraryDay) -> String? {
        day.estimatedTotal(in: currency).map { currency.format($0) }
    }

    /// "09:30 · 2h 30m" from an activity's start time + duration (nil if neither).
    func timeLabel(_ a: ItineraryActivity) -> String? {
        var parts: [String] = []
        if let t = a.startTime, !t.isEmpty { parts.append(t) }
        if let m = a.durationMinutes, m > 0 { parts.append(Self.durationText(m)) }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    func priceLabel(_ a: ItineraryActivity) -> String? { a.displayPrice(in: currency) }

    private static func durationText(_ minutes: Int) -> String {
        if minutes < 60 { return "\(minutes)m" }
        let h = minutes / 60, m = minutes % 60
        return m > 0 ? "\(h)h \(m)m" : "\(h)h"
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
