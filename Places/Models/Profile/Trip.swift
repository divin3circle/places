//
//  Trip.swift
//  Places
//
//  Created by Sylus Abel on 03/08/2026.
//

import Foundation

/// A past generated / used itinerary, surfaced in the Instagram-style
/// "My Trips" grid. Dummy data for now — no backend yet.
struct Trip: Identifiable {
  var id: String = UUID().uuidString
  var title: String
  var coverImageName: String
  var dateLabel: String
  /// Short tagline shown on the Home "My Trips" card. Unused by the profile grid.
  var subtitle: String = ""
}

extension Trip {
  static let dummyTrips: [Trip] = [
//    .init(
//      title: "Maasai Mara", coverImageName: "sample", dateLabel: "Aug 2026",
//      subtitle: "8 days · Big Five safari"),
    .init(
      title: "Serengeti Loop", coverImageName: "onboarding1", dateLabel: "Jul 2026",
      subtitle: "6 days · Great Migration"),
    .init(
      title: "Zanzibar Coast", coverImageName: "onboarding2", dateLabel: "Jun 2026",
      subtitle: "5 days · Beaches & spice"),
    .init(
      title: "Amboseli", coverImageName: "onboarding3", dateLabel: "May 2026",
      subtitle: "4 days · Kilimanjaro views"),
    .init(
      title: "Ngorongoro", coverImageName: "onboarding4", dateLabel: "Apr 2026",
      subtitle: "3 days · Crater floor"),
    .init(
      title: "Lake Nakuru", coverImageName: "onboarding5", dateLabel: "Mar 2026",
      subtitle: "2 days · Flamingo shores"),
    .init(
      title: "Mount Kenya", coverImageName: "onboarding1", dateLabel: "Dec 2025",
      subtitle: "4 days · Alpine trek"),
  ]
}
