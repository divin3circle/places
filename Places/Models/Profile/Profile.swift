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
    /// The active RevenueCat/App Store product id (e.g. `piea_249_1m`, `piea_pro_lifetime`).
    var planProduct: String?
    /// Subscription/lifetime expiry as returned by Postgres (ISO string); nil = none.
    var proExpiresAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, email, interests, plan
        case avatarURL = "avatar_url"
        case onboardingComplete = "onboarding_complete"
        case planProduct = "plan_product"
        case proExpiresAt = "pro_expires_at"
    }
}
