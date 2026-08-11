//
//  ContentMapping.swift
//  Places
//
//  DTO → existing UI struct mappers, plus small display helpers. DestinationDTO
//  is consumed directly by the card / detail views.
//

import SwiftUI

extension Sponsored {
    init(dto: SponsoredDTO) {
        self.init(
            id: dto.id,
            image: dto.imageUrl,
            accentColor: Color(hex: dto.accentHex) ?? .accent,
            offset: 0,
            category: dto.category,
            title: dto.title,
            subtitle: dto.subtitle,
            location: dto.location,
            ctaLabel: dto.ctaLabel
        )
    }
}

extension Experience {
    init(dto: ExperienceDTO) {
        self.init(
            id: dto.id,
            title: dto.title,
            imageNames: dto.images,
            categoryTag: dto.categoryTag,
            categoryLabel: dto.categoryLabel,
            city: EACity(rawValue: dto.cityId) ?? .nairobi,
            pricePerGuest: dto.pricePerGuest,
            currency: dto.currency,
            rating: dto.rating,
            reviewsCount: dto.reviewsCount,
            isTrending: dto.isTrending,
            hostName: dto.hostName,
            hostTagline: dto.hostTagline,
            hostImageName: dto.hostImageUrl ?? "",
            locationName: dto.locationName,
            locationArea: dto.locationArea,
            durationLabel: dto.durationLabel,
            language: dto.language,
            description: dto.description,
            bookingURL: dto.bookingUrl
        )
    }
}

extension ExperienceCategory {
    nonisolated init(dto: ExperienceCategoryDTO) {
        self.init(label: dto.label, imageName: dto.imageUrl ?? "", tag: dto.tag)
    }
}

extension DestinationDTO {
    /// Card subtitle, e.g. "Reserve · ★ 4.9".
    nonisolated var subtitleLabel: String {
        if let rating {
            return "\(category) · ★ \(String(format: "%.1f", rating))"
        }
        return category
    }
}
