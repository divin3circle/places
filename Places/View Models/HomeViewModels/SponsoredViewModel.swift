//
// SponsoredViewModel.swift
// Places
//
// Created by Sylus Abel on 06/08/2026
//

import SwiftUI

/// UI interaction state for the sponsored-card detail morph. Card DATA comes from
/// `ContentStore.sponsored`; `cards` is reserved for the (currently unused) swipe carousel.
@Observable @MainActor
final class SponsoredViewModel {
    var cards: [Sponsored] = []
    var swippedCard = 0
    var showCard = false
    var selectedCard = Sponsored(
        image: "", accentColor: .clear, category: "", title: "", subtitle: "",
        location: "", ctaLabel: ""
    )
}
