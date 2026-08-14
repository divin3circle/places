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
            Feature(id: "0", icon: "mappin.and.ellipse", title: "Grounded in Real Places", subtitle: "Every stop is a real destination — with real prices and tips.", color: .blue),
            Feature(id: "1", icon: "wand.and.stars", title: "Instant AI Itineraries", subtitle: "Let our smart concierge build your itinerary route.", color: .accent),
            Feature(id: "2", icon: "bolt.shield.fill", title: "Plan Even Offline", subtitle: "On-device AI builds your trips and keeps them — no signal needed.", color: .blue),
            Feature(id: "3", icon: "map.fill", title: "Your Trip on the Map", subtitle: "See every stop, day by day, on an interactive map.", color: .red)
        ]
    }
}
