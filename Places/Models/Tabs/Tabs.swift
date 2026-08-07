//
//  Tabs.swift
//  Places
//
//  Created by Sylus Abel on 30/07/2026.
//

import Foundation

enum AppTabs: String, CaseIterable {
    case home = "Feed"
    case explore = "Explore"
    case lounges = "Lounges"
    case profile = "Profile"
    
    var tabImage: String {
        switch self {
        case .home:
            "house.fill"
        case .explore:
            "magnifyingglass"
        case .lounges:
            "person.crop.circle.badge.ellipsis"
        case .profile:
            "person.crop.circle.fill"
        }
    }
}
