//
//  Trip.swift
//  Places
//
//  Created by Sylus Abel on 03/08/2026.
//

import Foundation

/// A saved generated itinerary, surfaced in the Instagram-style "My Trips" grid
/// and the Home carousel. Built from `SavedTrip.displayTrip`.
struct Trip: Identifiable {
  var id: String = UUID().uuidString
  var title: String
  var coverImageName: String
  var dateLabel: String
  /// Short tagline shown on the Home "My Trips" card. Unused by the profile grid.
  var subtitle: String = ""
}

#if DEBUG
extension Trip {
  /// Preview-only fixtures. Not used by any shipping screen.
  static let previews: [Trip] = [
    .init(title: "Serengeti Loop", coverImageName: "onboarding1", dateLabel: "Jul 2026",
          subtitle: "6 days · Great Migration"),
    .init(title: "Zanzibar Coast", coverImageName: "onboarding2", dateLabel: "Jun 2026",
          subtitle: "5 days · Beaches & spice"),
    .init(title: "Amboseli", coverImageName: "onboarding3", dateLabel: "May 2026",
          subtitle: "4 days · Kilimanjaro views"),
  ]
}
#endif
