//
//  UserProfile.swift
//  Places
//
//  Created by Sylus Abel on 03/08/2026.
//

import SwiftUI

/// The subscription tier a user is on.
enum UserPlan: String {
    case free = "Free"
    case pro = "Pro"

    /// Badge tint used in the profile settings.
    var tint: Color {
        switch self {
        case .free: .secondary
        case .pro: .accent
        }
    }
}

/// Lightweight account model. Currently backed by dummy data (`.current`) since
/// there is no auth/backend layer yet — replace `.current` when one exists.
struct UserProfile {
    var name: String
    var email: String
    var avatarImageName: String
    var plan: UserPlan
}

extension UserProfile {
    static let current = UserProfile(
        name: "Sylus Abel",
        email: "sylusabl@icloud.com",
        avatarImageName: "profile",
        plan: .pro
    )
}
