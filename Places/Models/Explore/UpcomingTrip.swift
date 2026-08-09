//
//  UpcomingTrip.swift
//  Places
//
//  Created by Sylus Abel on 03/08/2026.
//

import Foundation

/// The user's most recently planned trip, surfaced at the top of Explore.
/// Derived from their saved itineraries (no booking dates yet, so no countdown).
struct UpcomingTrip: Identifiable {
    let id: UUID
    var title: String
    var subtitle: String
    var coverImageName: String
    var days: Int
    var placesCount: Int
}

extension UpcomingTrip {
    /// Map a saved itinerary to the Explore hero: duration from its config, place
    /// count from the distinct grounded places across the latest version.
    init(savedTrip t: SavedTrip) {
        let places = t.latestItinerary.map { itinerary in
            Set(itinerary.days
                .flatMap { $0.activities.map(\.placeName) }
                .filter { !$0.isEmpty }).count
        } ?? 0
        self.init(
            id: t.id,
            title: t.title,
            subtitle: t.subtitle,
            coverImageName: t.coverImageName ?? "onboarding1",
            days: t.config?.durationDays ?? 0,
            placesCount: places
        )
    }
}
