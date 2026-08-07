//
//  Destination.swift
//  Places
//
//  Created by Sylus Abel on 31/07/2026.
//

import Foundation
import CoreLocation

struct Destination: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let category: String
    let countryCode: String
    let latitude: Double
    let longitude: Double
    let description: String
    let bannerUrl: String
    let images: [String]
    let nonResidentFeeUsd: Double
    let vehicleFeeGuidelines: String
    let paymentInfrastructure: String
    let interestTags: [String]
    let extraLogistics: ExtraLogistics

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case category
        case countryCode = "country_code"
        case latitude
        case longitude
        case description
        case bannerUrl = "banner_url"
        case images
        case nonResidentFeeUsd = "non_resident_fee_usd"
        case vehicleFeeGuidelines = "vehicle_fee_guidelines"
        case paymentInfrastructure = "payment_infrastructure"
        case interestTags = "interest_tags"
        case extraLogistics = "extra_logistics"
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Destination, rhs: Destination) -> Bool {
        lhs.id == rhs.id
    }
}

struct ExtraLogistics: Codable, Hashable {
    let bestSeason: String
    let closestHub: String

    enum CodingKeys: String, CodingKey {
        case bestSeason = "best_season"
        case closestHub = "closest_hub"
    }
}

extension Destination {
    static let samples: [Destination] = [
        Destination(
            id: "ke_maasai_mara_national_reserve",
            name: "Maasai Mara National Reserve",
            category: "national_park",
            countryCode: "KE",
            latitude: -1.4931,
            longitude: 35.1439,
            description: "Kenya's most iconic wildlife reserve, renowned for the Great Wildebeest Migration, exceptional Big Five sightings, expansive savannah landscapes, and year-round safari experiences. The reserve borders Tanzania's Serengeti National Park, forming one of Africa's richest wildlife ecosystems.",
            bannerUrl: "",
            images: [],
            nonResidentFeeUsd: 200.00,
            vehicleFeeGuidelines: "Vehicle entry fees are charged separately. Typical safari vehicles (6–12 seats) are charged approximately KES 1,500 per day. Larger vehicles attract higher fees.",
            paymentInfrastructure: "Card payments are accepted at all major gates. Some gates also accept cash (USD or KES). Tour operators typically prepay park fees. Online payment is recommended where available.",
            interestTags: [
                "big_five",
                "great_migration",
                "wildlife_core",
                "photography",
                "game_drive",
                "luxury_safari",
                "birdwatching",
                "family_friendly"
            ],
            extraLogistics: ExtraLogistics(
                bestSeason: "July - October (Great Migration); December - February for excellent wildlife viewing.",
                closestHub: "Keekorok Airstrip (within reserve); Nairobi (approximately 45 minutes by scheduled flight or 5-6 hours by road)."
            )
        )
    ]
    
    func getUIFriendlyTag(_ tag: String) -> String {
        return tag.split(separator: "_").joined(separator: " ")
    }
}
