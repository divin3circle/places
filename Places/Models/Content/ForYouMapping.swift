//
//  ForYouMapping.swift
//  Places
//
//  Maps the 8 experience-category interest tags (profiles.interests) to the
//  destinations.interest_tags vocabulary, so For You can pull matching destinations.
//

import Foundation

nonisolated enum ForYouMapping {
    private static let map: [String: [String]] = [
        "wildlife_safaris": ["wildlife_core", "big_five", "game_drive", "rhino", "elephants",
                             "birdwatching", "great_migration", "luxury_safari", "photography"],
        "nature_hiking": ["hiking", "nature", "mountaineering", "trekking_primates",
                          "kilimanjaro_views", "eco_conservation"],
        "cultural_heritage": ["arts_culture", "heritage", "history_culture"],
        "arts_crafts": ["arts_culture"],
        "adventure_sports": ["adventure_camping", "watersports", "cycling"],
        "wellness_relaxation": ["coastal_relaxation", "beaches", "honeymoon", "snorkeling"],
        "food_coffee_tours": [],
        "nightlife_music": [],
    ]

    /// Deduped union of destination tags for the given interest tags (order preserved).
    static func destinationTags(for interests: [String]) -> [String] {
        var seen = Set<String>()
        var out: [String] = []
        for interest in interests {
            for tag in map[interest] ?? [] where seen.insert(tag).inserted {
                out.append(tag)
            }
        }
        return out
    }
}
