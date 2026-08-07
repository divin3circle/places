//
//  RecommendedDestination.swift
//  Places
//
//  Created by Sylus Abel on 03/08/2026.
//

import Foundation

/// A recommended East-African destination, shown as a fanned stack of photos in
/// the Explore "Recommendations" carousel. Dummy data for now.
struct RecommendedDestination: Identifiable {
    let id = UUID()
    var name: String
    /// Up to three images used for the fanned-stack effect.
    var imageNames: [String]
}

extension RecommendedDestination {
    static let samples: [RecommendedDestination] = [
        .init(name: "Maasai Mara", imageNames: ["onboarding1", "sample", "onboarding3"]),
        .init(name: "Serengeti", imageNames: ["onboarding2", "onboarding4", "onboarding5"]),
        .init(name: "Zanzibar", imageNames: ["onboarding6", "onboarding7", "sample"]),
        .init(name: "Bwindi", imageNames: ["onboarding3", "onboarding1", "onboarding2"]),
        .init(name: "Ngorongoro", imageNames: ["onboarding5", "onboarding6", "onboarding4"])
    ]
}
