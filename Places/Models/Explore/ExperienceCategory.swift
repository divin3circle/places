//
//  ExperienceCategory.swift
//  Places
//
//  A browsable collection shown in the "Explore experiences nearby" row. Tapping
//  one opens a filtered list of experiences with the matching `tag`. Built from
//  `ExperienceCategoryDTO`; identity is the stable server `tag`.
//

import Foundation

nonisolated struct ExperienceCategory: Identifiable, Hashable {
    let label: String
    let imageName: String
    /// Matches `Experience.categoryTag` for filtering. Also the stable identity.
    let tag: String

    var id: String { tag }
}

extension ExperienceCategory {
    /// Preview-only fixture. Not used at runtime.
    static let preview = ExperienceCategory(
        label: "Wildlife safaris", imageName: "onboarding1", tag: "wildlife_safaris"
    )
}
