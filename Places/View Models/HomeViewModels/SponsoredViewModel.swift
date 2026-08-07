//
// SponsoredViewModel.swift
// Places
//
// Created by Sylus Abel on 06/08/2026
//

import Combine
import SwiftUI

class SponsoredViewModel: ObservableObject {
  @Published var cards = [
    Sponsored(
      image: "onboarding7", accentColor: Color(.systemGray4),
      category: "Food Joint", title: "Mama Oliech",
      subtitle: "Nairobi's legendary whole-fried tilapia and ugali.",
      location: "Kileleshwa, Nairobi", ctaLabel: "Get Directions"
    ),
    Sponsored(
      image: "onboarding6", accentColor: Color(.systemGray4),
      category: "Car Rental", title: "Cars 360",
      subtitle: "4x4 Land Cruisers, self-drive or with a driver.",
      location: "Westlands, Nairobi", ctaLabel: "Book a Car"
    ),
    Sponsored(
      image: "onboarding2", accentColor: Color(.systemGray4),
      category: "Tour Guide", title: "Viusasa Tours",
      subtitle: "Guided Mara & Serengeti safaris, tailor-made.",
      location: "Karen, Nairobi", ctaLabel: "Plan a Tour"
    ),
    Sponsored(
      image: "onboarding3", accentColor: Color(.systemGray4),
      category: "Local Market", title: "Maasai Market",
      subtitle: "Handmade beadwork, kikoys and curios from local artisans.",
      location: "Village Market, Nairobi", ctaLabel: "See Vendors"
    ),
    Sponsored(
      image: "onboarding4", accentColor: Color(.systemGray4),
      category: "Beach Resort", title: "Diani Sands",
      subtitle: "Beachfront villas steps from the white sands of Diani.",
      location: "Diani Beach, Kwale", ctaLabel: "Check Rates"
    ),
  ]

  @Published var swippedCard = 0
  @Published var showCard = false
  @Published var selectedCard = Sponsored(
    image: "", accentColor: .clear, category: "", title: "", subtitle: "",
    location: "", ctaLabel: ""
  )
}
