//
//  GroundingBucket.swift
//  Places
//
//  Maps Supabase content categories into the 5 PlaceCategory buckets the
//  on-device findPlaces tool groups by. (Cloud grounds on the full name set.)
//

import Foundation

nonisolated enum GroundingBucket {
    static func forDestination(category: String) -> PlaceCategory {
        switch category {
        case "national_park", "conservancy", "mountain": .wildlife
        case "beach": .beach
        case "cultural": .culture
        default: .city
        }
    }

    static func forExperience(tag: String) -> PlaceCategory {
        switch tag {
        case "wildlife_safaris", "nature_hiking": .wildlife
        case "cultural_heritage", "arts_crafts": .culture
        case "wellness_relaxation": .beach
        default: .city   // food_coffee_tours, adventure_sports, nightlife_music
        }
    }
}
