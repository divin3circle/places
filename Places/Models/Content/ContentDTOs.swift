//
//  ContentDTOs.swift
//  Places
//
//  Codable transport types matching the Supabase content tables. Mapped to the
//  UI structs at render (see ContentMapping.swift). Pure transport — no UI state.
//

import Foundation

nonisolated struct DestinationDTO: Codable, Identifiable {
    let id: String
    let name: String
    let category: String
    let countryCode: String
    let latitude: Double
    let longitude: Double
    let description: String
    let bannerUrl: String
    let images: [String]
    let nonResidentFeeUsd: Double?
    let feeLabel: String?
    let vehicleFeeGuidelines: String?
    let paymentInfrastructure: String?
    let interestTags: [String]
    let bestSeason: String?
    let closestHub: String?
    let rating: Double?
    let bestTimeToVisit: String?
    let priceRange: String?
    let isPopular: Bool
    var bookingUrl: String? = nil

    enum CodingKeys: String, CodingKey {
        case id, name, category, latitude, longitude, description, images, rating
        case bookingUrl = "booking_url"
        case countryCode = "country_code"
        case bannerUrl = "banner_url"
        case nonResidentFeeUsd = "non_resident_fee_usd"
        case feeLabel = "fee_label"
        case vehicleFeeGuidelines = "vehicle_fee_guidelines"
        case paymentInfrastructure = "payment_infrastructure"
        case interestTags = "interest_tags"
        case bestSeason = "best_season"
        case closestHub = "closest_hub"
        case bestTimeToVisit = "best_time_to_visit"
        case priceRange = "price_range"
        case isPopular = "is_popular"
    }
}

nonisolated struct ExperienceDTO: Codable, Identifiable {
    let id: UUID
    let title: String
    let images: [String]
    let categoryTag: String
    let categoryLabel: String
    let cityId: String
    let pricePerGuest: Int
    let currency: String
    let rating: Double
    let reviewsCount: Int
    let isTrending: Bool
    let hostName: String
    let hostTagline: String
    let hostImageUrl: String?
    let locationName: String
    let locationArea: String
    let durationLabel: String
    let language: String
    let description: String
    let latitude: Double?
    let longitude: Double?
    var bookingUrl: String? = nil

    enum CodingKeys: String, CodingKey {
        case id, title, images, currency, rating, language, description, latitude, longitude
        case bookingUrl = "booking_url"
        case categoryTag = "category_tag"
        case categoryLabel = "category_label"
        case cityId = "city_id"
        case pricePerGuest = "price_per_guest"
        case reviewsCount = "reviews_count"
        case isTrending = "is_trending"
        case hostName = "host_name"
        case hostTagline = "host_tagline"
        case hostImageUrl = "host_image_url"
        case locationName = "location_name"
        case locationArea = "location_area"
        case durationLabel = "duration_label"
    }
}

nonisolated struct ExperienceCategoryDTO: Codable, Identifiable {
    let tag: String
    let label: String
    let imageUrl: String?
    let sortOrder: Int

    var id: String { tag }

    enum CodingKeys: String, CodingKey {
        case tag, label
        case imageUrl = "image_url"
        case sortOrder = "sort_order"
    }
}

nonisolated struct SponsoredDTO: Codable, Identifiable {
    let id: UUID
    let imageUrl: String
    let accentHex: String?
    let category: String
    let title: String
    let subtitle: String
    let location: String
    let ctaLabel: String
    let cityId: String?
    let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case id, category, title, subtitle, location
        case imageUrl = "image_url"
        case accentHex = "accent_hex"
        case ctaLabel = "cta_label"
        case cityId = "city_id"
        case sortOrder = "sort_order"
    }
}
