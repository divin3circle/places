//
//  Profile.swift
//  Places
//
//  Backend-backed user profile, mapped to the Supabase `profiles` table.
//

import Foundation

nonisolated struct Profile: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String?
    var email: String?
    var avatarURL: String?
    var interests: [String]
    var plan: String
    var onboardingComplete: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, email, interests, plan
        case avatarURL = "avatar_url"
        case onboardingComplete = "onboarding_complete"
    }
}
