//
//  SavedPlace.swift
//  Places
//
//  A bookmarked destination or experience, stored locally on-device (SwiftData).
//  Not synced upstream yet. Bookmarks can seed itinerary generation ("base this
//  on your saved places").
//

import Foundation
import SwiftData

@Model
final class SavedPlace {
    @Attribute(.unique) var id: UUID
    var kind: String          // "destination" | "experience"
    var refId: String         // the source DTO id
    var name: String
    var imageURL: String
    var subtitle: String
    var latitude: Double
    var longitude: Double
    var createdAt: Date

    init(kind: String, refId: String, name: String, imageURL: String,
         subtitle: String, latitude: Double, longitude: Double) {
        self.id = UUID()
        self.kind = kind
        self.refId = refId
        self.name = name
        self.imageURL = imageURL
        self.subtitle = subtitle
        self.latitude = latitude
        self.longitude = longitude
        self.createdAt = .now
    }
}

extension SavedPlace {
    enum Kind: String { case destination, experience }

    convenience init(destination d: DestinationDTO) {
        self.init(kind: Kind.destination.rawValue, refId: d.id, name: d.name,
                  imageURL: d.bannerUrl, subtitle: d.category,
                  latitude: d.latitude, longitude: d.longitude)
    }

    convenience init(experience e: ExperienceDTO) {
        self.init(kind: Kind.experience.rawValue, refId: e.id.uuidString, name: e.title,
                  imageURL: e.images.first ?? "", subtitle: e.categoryLabel,
                  latitude: e.latitude ?? 0, longitude: e.longitude ?? 0)
    }
}
