//
//  UpcomingTrip.swift
//  Places
//
//  Created by Sylus Abel on 03/08/2026.
//

import Foundation

/// The user's next confirmed trip, surfaced at the top of Explore with a live
/// countdown. Dummy data for now — no backend yet.
struct UpcomingTrip: Identifiable {
    let id = UUID()
    var title: String
    var subtitle: String
    var coverImageName: String
    var days: Int
    var placesCount: Int
    var countdownTarget: Date
}

extension UpcomingTrip {
    // Computed so `Date()` is evaluated fresh each launch.
    static var sample: UpcomingTrip {
        UpcomingTrip(
            title: "Maasai Mara Safari",
            subtitle: "Golden plains and Big Five mornings.",
            coverImageName: "sample",
            days: 8,
            placesCount: 12,
            countdownTarget: Calendar.current.date(byAdding: .day, value: 120, to: Date()) ?? Date()
        )
    }
}
