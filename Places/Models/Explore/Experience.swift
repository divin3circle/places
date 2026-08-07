//
//  Experience.swift
//  Places
//
//  A bookable local experience (Airbnb-style). Surfaced in the "Popular
//  experiences in <city>" feed row and in a category's filtered list. Dummy data
//  for now — no backend yet.
//

import Foundation

struct Experience: Identifiable, Hashable {
    let id = UUID()
    var title: String
    /// Gallery images; the first is the cover.
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

    /// e.g. "KSh 14,230"
    var priceLabel: String {
        "\(currency) \(pricePerGuest.formatted(.number.grouping(.automatic)))"
    }
    var coverImage: String { imageNames.first ?? "sample" }
}

extension Experience {
    static let samples: [Experience] = [
        .init(
            title: "Visit Nairobi National Park",
            imageNames: ["onboarding1", "onboarding4", "sample"],
            categoryTag: "wildlife", categoryLabel: "Wildlife", city: .nairobi,
            pricePerGuest: 14_230, rating: 4.98, reviewsCount: 603, isTrending: true,
            hostName: "David", hostTagline: "Wildlife conservationist and guide",
            hostImageName: "profile",
            locationName: "KICC", locationArea: "Nairobi, Nairobi County",
            durationLabel: "Around 5 hr experience", language: "Hosted in English",
            description: "Drive through the park, spotting black rhinos, lions, leopards, and diverse birdlife."
        ),
        .init(
            title: "Wander Kibera with a local nonprofit founder",
            imageNames: ["onboarding2", "card-2"],
            categoryTag: "cultural_tours", categoryLabel: "Cultural tours", city: .nairobi,
            pricePerGuest: 3_105, rating: 4.96, reviewsCount: 214, isTrending: true,
            hostName: "Amara", hostTagline: "Community organizer and storyteller",
            hostImageName: "profile",
            locationName: "Kibera", locationArea: "Nairobi, Nairobi County",
            durationLabel: "Around 3 hr experience", language: "Hosted in English & Swahili",
            description: "Walk the neighbourhood with a founder building youth programs, and meet the artisans behind them."
        ),
        .init(
            title: "Swahili Cooking Class in Nairobi",
            imageNames: ["card-3", "card-1"],
            categoryTag: "cooking", categoryLabel: "Cooking", city: .nairobi,
            pricePerGuest: 7_244, rating: 5.0, reviewsCount: 41,
            hostName: "Zawadi", hostTagline: "Home cook and coastal-cuisine specialist",
            hostImageName: "profile",
            locationName: "Kilimani", locationArea: "Nairobi, Nairobi County",
            durationLabel: "Around 5 hr experience", language: "Hosted in English",
            description: "Cook a full Swahili spread — pilau, coconut greens, and mahamri — then share the table together."
        ),
        .init(
            title: "Cook Kenyan street food in a local home",
            imageNames: ["card-1", "card-4"],
            categoryTag: "cooking", categoryLabel: "Cooking", city: .nairobi,
            pricePerGuest: 5_175, rating: 4.9, reviewsCount: 88,
            hostName: "Otieno", hostTagline: "Street-food obsessive",
            hostImageName: "profile",
            locationName: "Westlands", locationArea: "Nairobi, Nairobi County",
            durationLabel: "Around 2.5 hr experience", language: "Hosted in English",
            description: "Fry up smokies, mutura, and kachumbari the way Nairobi eats after dark."
        ),
        .init(
            title: "Ankara fabric market tour",
            imageNames: ["card-4", "onboarding3"],
            categoryTag: "shopping_fashion", categoryLabel: "Shopping & fashion", city: .nairobi,
            pricePerGuest: 2_600, rating: 4.85, reviewsCount: 57, isTrending: true,
            hostName: "Njeri", hostTagline: "Fashion designer and stylist",
            hostImageName: "profile",
            locationName: "Toi Market", locationArea: "Nairobi, Nairobi County",
            durationLabel: "Around 2 hr experience", language: "Hosted in English",
            description: "Hunt for the boldest Ankara prints with a designer, and learn how to spot quality wax cloth."
        ),
        .init(
            title: "Karura Forest walk & waterfall",
            imageNames: ["onboarding4", "onboarding5"],
            categoryTag: "outdoors", categoryLabel: "Outdoors", city: .nairobi,
            pricePerGuest: 3_900, rating: 4.92, reviewsCount: 129,
            hostName: "Mwangi", hostTagline: "Trail guide and birder",
            hostImageName: "profile",
            locationName: "Karura Forest", locationArea: "Nairobi, Nairobi County",
            durationLabel: "Around 3 hr experience", language: "Hosted in English",
            description: "A shaded walk to the waterfall and caves, with plenty of stops for birds and butterflies."
        ),
        .init(
            title: "Nairobi Gallery & street-art crawl",
            imageNames: ["card-2", "onboarding6"],
            categoryTag: "art_workshops", categoryLabel: "Art workshops", city: .nairobi,
            pricePerGuest: 4_450, rating: 4.88, reviewsCount: 73,
            hostName: "Sanaa", hostTagline: "Painter and muralist",
            hostImageName: "profile",
            locationName: "CBD", locationArea: "Nairobi, Nairobi County",
            durationLabel: "Around 3 hr experience", language: "Hosted in English",
            description: "Meet muralists in their element and try your hand at a small canvas to take home."
        ),
        .init(
            title: "Old Town food tour",
            imageNames: ["card-1", "card-3"],
            categoryTag: "food_tours", categoryLabel: "Food tours", city: .nairobi,
            pricePerGuest: 5_600, rating: 4.95, reviewsCount: 162,
            hostName: "Halima", hostTagline: "Food writer",
            hostImageName: "profile",
            locationName: "River Road", locationArea: "Nairobi, Nairobi County",
            durationLabel: "Around 3.5 hr experience", language: "Hosted in English & Swahili",
            description: "Graze your way through samosas, viazi karai, and chai at the stalls locals actually queue for."
        ),
        .init(
            title: "KICC rooftop & landmarks walk",
            imageNames: ["onboarding6", "card-2"],
            categoryTag: "landmarks", categoryLabel: "Landmarks", city: .nairobi,
            pricePerGuest: 3_300, rating: 4.8, reviewsCount: 98,
            hostName: "Baraka", hostTagline: "City historian",
            hostImageName: "profile",
            locationName: "KICC", locationArea: "Nairobi, Nairobi County",
            durationLabel: "Around 2 hr experience", language: "Hosted in English",
            description: "Take in the skyline from the KICC helipad, then trace the stories behind downtown's landmarks."
        ),
        .init(
            title: "Kampala boda-boda city ride",
            imageNames: ["onboarding3", "onboarding7"],
            categoryTag: "cultural_tours", categoryLabel: "Cultural tours", city: .kampala,
            pricePerGuest: 2_900, rating: 4.9, reviewsCount: 64,
            hostName: "Ssebunya", hostTagline: "Lifelong Kampala local",
            hostImageName: "profile",
            locationName: "Old Kampala", locationArea: "Kampala, Uganda",
            durationLabel: "Around 3 hr experience", language: "Hosted in English",
            description: "See the city the way it moves — by boda — from markets to hilltop viewpoints."
        ),
    ]

    static func samples(in city: EACity) -> [Experience] {
        samples.filter { $0.city == city }
    }

    static func samples(tag: String, city: EACity? = nil) -> [Experience] {
        samples.filter { $0.categoryTag == tag && (city == nil || $0.city == city) }
    }
}
