//
//  CuratedTrip.swift
//  Places
//
//  Created by Sylus Abel on 03/08/2026.
//

import Foundation

/// A curated trip shown in "Places worth slowing down for". `category` matches a
/// `TravelInterest.category` so the filter pills can filter this list.
struct CuratedTrip: Identifiable {
    let id = UUID()
    var title: String
    var imageName: String
    var durationLabel: String
    var category: String
}

extension CuratedTrip {
    static let samples: [CuratedTrip] = [
        .init(title: "Kilimanjaro Trek", imageName: "onboarding3", durationLabel: "7 Days", category: "trekking_primates"),
        .init(title: "Diani Beach Escape", imageName: "onboarding6", durationLabel: "5 Days", category: "coastal_relaxation"),
        .init(title: "Serengeti Migration", imageName: "onboarding4", durationLabel: "6 Days", category: "wildlife_core"),
        .init(title: "Lamu Old Town", imageName: "onboarding7", durationLabel: "3 Days", category: "arts_culture"),
        .init(title: "Bwindi Gorillas", imageName: "onboarding1", durationLabel: "4 Days", category: "trekking_primates"),
        .init(title: "Ngorongoro Crater", imageName: "onboarding5", durationLabel: "2 Days", category: "wildlife_core"),
        .init(title: "Nakuru Flamingos", imageName: "sample", durationLabel: "2 Days", category: "eco_conservation")
    ]

    /// A small set of interests used as the filter row (label + icon + category).
    static let filters: [TravelInterest] = [
        .init(label: "Safari", icon: "binoculars.fill", categoryTag: "wildlife_core"),
        .init(label: "Trekking", icon: "figure.hiking", categoryTag: "trekking_primates"),
        .init(label: "Beaches", icon: "sun.max.fill", categoryTag: "coastal_relaxation"),
        .init(label: "Culture", icon: "building.columns.fill", categoryTag: "arts_culture"),
        .init(label: "Nature", icon: "leaf.fill", categoryTag: "eco_conservation")
    ]
}
