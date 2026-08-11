//
//  SavedTrip.swift
//  Places
//
//  A durable trip the user created from the itinerary chat via "Convert to trip".
//  A trip owns its config, the full model memory (transcript), and one or more
//  itinerary versions (each AI edit adds a version). These populate the app's
//  "My Trips" UI. On-device only — no cloud.
//

import Foundation
import SwiftData

@Model
final class SavedTrip {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var title: String
    var coverImageName: String?
    var subtitle: String
    var configData: Data                 // encoded TripConfig
    var transcriptData: Data?            // session memory (for reopen-to-edit later)

    @Relationship(deleteRule: .cascade, inverse: \SavedItineraryVersion.trip)
    var versions: [SavedItineraryVersion]

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        title: String,
        coverImageName: String? = nil,
        subtitle: String = "",
        configData: Data,
        transcriptData: Data? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.title = title
        self.coverImageName = coverImageName
        self.subtitle = subtitle
        self.configData = configData
        self.transcriptData = transcriptData
        self.versions = []
    }

    var config: TripConfig? {
        try? JSONDecoder().decode(TripConfig.self, from: configData)
    }

    /// The most recent itinerary version (highest order), decoded.
    var latestItinerary: GeneratedItinerary? {
        versions.max(by: { $0.order < $1.order })?.itinerary
    }

    /// Bridges to the app's existing `Trip` display model (My Trips card + sheet).
    var displayTrip: Trip {
        Trip(
            id: id.uuidString,
            title: title,
            coverImageName: coverImageName ?? "onboarding1",
            dateLabel: createdAt.formatted(.dateTime.month(.abbreviated).year()),
            subtitle: subtitle
        )
    }
}

@Model
final class SavedItineraryVersion {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var order: Int
    var itineraryJSON: Data              // encoded GeneratedItinerary
    var note: String?                    // "Original" or the edit instruction
    var trip: SavedTrip?

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        order: Int,
        itineraryJSON: Data,
        note: String? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.order = order
        self.itineraryJSON = itineraryJSON
        self.note = note
    }

    var itinerary: GeneratedItinerary? {
        try? JSONDecoder().decode(GeneratedItinerary.self, from: itineraryJSON)
    }
}
