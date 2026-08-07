//
//  Features.swift
//  Places
//
//  Created by Sylus Abel on 27/07/2026.
//

import Foundation
import SwiftUI

struct Feature: Identifiable {
    var id: String
    var icon: String
    var title: String
    var subtitle: String
    var color: Color
}

enum Features {
    static var list: [Feature] {
        [
            Feature(id: "0", icon: "person.3.sequence.fill", title: "Collaborative Lounge", subtitle: "Invite your travel squad to plan and enjoy together.", color: .blue),
            Feature(id: "1", icon: "wand.and.stars", title: "Instant AI Itineraries", subtitle: "Let our smart concierge build your itinerary route.", color: .accent),
            Feature(id: "2", icon: "bolt.shield.fill", title: "True Off-Grid Utilities", subtitle: "Lose reception without losing your traveling plans.", color: .blue),
            Feature(id: "3", icon: "map.fill", title: "Visual Route Radars", subtitle: "Chronologically traced paths across map boards.", color: .red)
        ]
    }
}
