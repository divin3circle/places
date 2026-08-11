//
//  DiscoveryCollection.swift
//  Places
//
//  A curated, themed grouping surfaced in the Explore "Collections" row
//  (Matter-style editorial tiles). Each collection is a fixed editorial concept
//  that filters the live `destinations` by overlapping `interest_tags` — no new
//  table, purely a lens over existing content.
//

import SwiftUI

nonisolated struct DiscoveryCollection: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let systemImage: String
    /// Destination `interest_tags` this collection gathers (any-overlap match).
    let tags: [String]
    /// Cover gradient — keeps the tile rich without depending on a remote image.
    let gradient: [Color]

    /// The curated launch set. Tags mirror the values seeded on `destinations`.
    static let all: [DiscoveryCollection] = [
        .init(
            id: "great_migration",
            title: "Great Migration season",
            subtitle: "Big cats, big herds, big skies",
            systemImage: "binoculars.fill",
            tags: ["great_migration", "big_five", "game_drive", "wildlife_core", "elephants"],
            gradient: [Color(red: 0.78, green: 0.45, blue: 0.16), Color(red: 0.45, green: 0.25, blue: 0.10)]
        ),
        .init(
            id: "beaches_coast",
            title: "Beaches & coast",
            subtitle: "Warm water, white sand, dhows",
            systemImage: "sun.max.fill",
            tags: ["beaches", "coastal_relaxation", "snorkeling", "watersports", "honeymoon"],
            gradient: [Color(red: 0.12, green: 0.58, blue: 0.62), Color(red: 0.06, green: 0.32, blue: 0.55)]
        ),
        .init(
            id: "culture_heritage",
            title: "Culture & heritage",
            subtitle: "Old towns, arts & living history",
            systemImage: "building.columns.fill",
            tags: ["history_culture", "heritage", "arts_culture"],
            gradient: [Color(red: 0.45, green: 0.28, blue: 0.62), Color(red: 0.24, green: 0.14, blue: 0.40)]
        ),
        .init(
            id: "adventure_adrenaline",
            title: "Adventure & adrenaline",
            subtitle: "Peaks, gorges & long trails",
            systemImage: "figure.hiking",
            tags: ["hiking", "mountaineering", "adventure_camping", "cycling", "trekking_primates"],
            gradient: [Color(red: 0.16, green: 0.52, blue: 0.34), Color(red: 0.08, green: 0.30, blue: 0.22)]
        ),
    ]
}
