//
//  ExperienceCategory.swift
//  Places
//
//  A browsable collection shown in the "Explore experiences nearby" row. Tapping
//  one opens a filtered list of experiences with the matching `tag`.
//

import Foundation

struct ExperienceCategory: Identifiable, Hashable {
    let id = UUID()
    let label: String
    let imageName: String
    /// Matches `Experience.categoryTag` for filtering.
    let tag: String
}

extension ExperienceCategory {
    static let all: [ExperienceCategory] = [
        .init(label: "Cultural tours", imageName: "onboarding2", tag: "cultural_tours"),
        .init(label: "Outdoors", imageName: "onboarding4", tag: "outdoors"),
        .init(label: "Food tours", imageName: "card-1", tag: "food_tours"),
        .init(label: "Art workshops", imageName: "card-2", tag: "art_workshops"),
        .init(label: "Wildlife", imageName: "onboarding1", tag: "wildlife"),
        .init(label: "Landmarks", imageName: "onboarding6", tag: "landmarks"),
        .init(label: "Cooking", imageName: "card-3", tag: "cooking"),
        .init(label: "Shopping & fashion", imageName: "card-4", tag: "shopping_fashion"),
    ]
}
