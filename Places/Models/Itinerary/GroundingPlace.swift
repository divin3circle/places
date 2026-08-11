//
//  GroundingPlace.swift
//  Places
//
//  A real place the AI can reference + pin, built from Supabase destinations and
//  experiences. Resolves to a ResolvedPlace (coord + remote image) for the map.
//

import Foundation
import CoreLocation

nonisolated struct GroundingPlace: Identifiable {
    let name: String
    let latitude: Double
    let longitude: Double
    let imageURL: String
    let subtitle: String
    let bucket: PlaceCategory
    /// Grounded price in USD (destination entry fee / experience price), if known.
    var priceUSD: Double? = nil

    var id: String { name }

    var resolvedPlace: ResolvedPlace {
        ResolvedPlace(
            name: name,
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            imageURL: URL(string: imageURL),
            subtitle: subtitle
        )
    }
}

nonisolated extension GroundingPlace {
    init(destination d: DestinationDTO) {
        self.init(name: d.name, latitude: d.latitude, longitude: d.longitude,
                  imageURL: d.bannerUrl, subtitle: d.category,
                  bucket: GroundingBucket.forDestination(category: d.category),
                  priceUSD: d.nonResidentFeeUsd)
    }

    init?(experience e: ExperienceDTO) {
        guard let lat = e.latitude, let lng = e.longitude else { return nil }
        // Experience prices are stored per guest in KES → USD for grounding.
        self.init(name: e.title, latitude: lat, longitude: lng,
                  imageURL: e.images.first ?? "", subtitle: e.categoryLabel,
                  bucket: GroundingBucket.forExperience(tag: e.categoryTag),
                  priceUSD: Double(e.pricePerGuest) / Currency.usdToKes)
    }
}
