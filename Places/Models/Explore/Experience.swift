//
//  Experience.swift
//  Places
//
//  A bookable local experience (Airbnb-style). Surfaced in the "Popular
//  experiences in <city>" feed row and in a category's filtered list. Built from
//  `ExperienceDTO` (see ContentMapping); `id` is seeded from the DB row.
//

import Foundation

nonisolated struct Experience: Identifiable, Hashable {
    let id: UUID
    var title: String
    /// Gallery images; the first is the cover. Remote URLs from Supabase.
    var imageNames: [String]
    /// Matches `ExperienceCategory.tag`.
    var categoryTag: String
    var categoryLabel: String
    var city: EACity
    var pricePerGuest: Int
    var currency: String = "KSh"
    var rating: Double
    var reviewsCount: Int
    var isTrending: Bool = false

    var hostName: String
    var hostTagline: String
    var hostImageName: String
    var locationName: String
    var locationArea: String
    var durationLabel: String
    var language: String
    var description: String
    var freeCancellation: Bool = true
    /// Booking/reserve link from the DB (nil → app derives a search fallback).
    var bookingURL: String? = nil

    /// e.g. "KSh 14,230"
    var priceLabel: String {
        "\(currency) \(pricePerGuest.formatted(.number.grouping(.automatic)))"
    }
    var coverImage: String { imageNames.first ?? "sample" }

    /// The booking/reserve link — the DB value, or a Google search fallback.
    var bookingLink: URL {
        if let s = bookingURL, !s.isEmpty, let url = URL(string: s) { return url }
        let q = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? title
        return URL(string: "https://www.google.com/search?q=\(q)+book")!
    }
}

#if DEBUG
extension Experience {
    /// Preview-only fixture (Xcode canvases). Not used at runtime.
    static let preview = Experience(
        id: UUID(),
        title: "Nairobi National Park Game Drive",
        imageNames: ["onboarding1", "onboarding4"],
        categoryTag: "wildlife_safaris", categoryLabel: "Wildlife safaris", city: .nairobi,
        pricePerGuest: 6_500, rating: 4.9, reviewsCount: 820, isTrending: true,
        hostName: "Samuel", hostTagline: "Certified safari guide", hostImageName: "profile",
        locationName: "Nairobi National Park", locationArea: "Nairobi, Nairobi County",
        durationLabel: "Around 4 hr experience", language: "Hosted in English",
        description: "Explore the world's only wildlife park within a capital city."
    )
}
#endif
