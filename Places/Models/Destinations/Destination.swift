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
    func getUIFriendlyTag(_ tag: String) -> String {
        return tag.split(separator: "_").joined(separator: " ")
    }
}
