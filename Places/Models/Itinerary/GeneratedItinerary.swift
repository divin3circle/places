//
//  GeneratedItinerary.swift
//  Places
//
//

import Foundation
import FoundationModels

@Generable
struct GeneratedItinerary: Equatable, Codable {
    @Guide(description: "An exciting, specific title for the whole trip")
    var title: String

    @Guide(description: "A one-paragraph overview of the trip")
    var summary: String

    @Guide(description: "A short explanation of how this plan fits the traveler's stated request")
    var rationale: String

    @Guide(description: "The day-by-day plan, one entry per trip day")
    var days: [ItineraryDay]
}

extension GeneratedItinerary {
    static let example = GeneratedItinerary(
        title: "Rift Valley Escape",
        summary: "A short, active getaway blending wildlife and lakeside relaxation.",
        rationale: "Balances big-game viewing with easy travel days for a relaxed pace.",
        days: [
            ItineraryDay(
                title: "Arrival & City Warm-up",
                subtitle: "Ease in with sights and a great meal.",
                activities: [
                    ItineraryActivity(kind: .sightseeing, title: "Explore the old town", description: "A gentle afternoon walk to get oriented.", placeName: "Nairobi"),
                    ItineraryActivity(kind: .foodAndDining, title: "Dinner with local flavors", description: "Sample regional cuisine.", placeName: "Nairobi")
                ]
            ),
            ItineraryDay(
                title: "Into the Wild",
                subtitle: "A full day on safari.",
                activities: [
                    ItineraryActivity(kind: .wildlife, title: "Morning game drive", description: "Track big cats at first light.", placeName: "Maasai Mara"),
                    ItineraryActivity(kind: .lodging, title: "Stay at a tented camp", description: "Rest under the stars.", placeName: "Maasai Mara")
                ]
            )
        ]
    )
}

@Generable
struct ItineraryDay: Equatable, Codable {
    @Guide(description: "A short, exciting title for the day")
    var title: String
    var subtitle: String

    @Guide(description: "Two to four activities for the day")
    var activities: [ItineraryActivity]
}

@Generable
struct ItineraryActivity: Equatable, Codable {
    var kind: ActivityKind
    var title: String
    var description: String

    @Guide(description: "The real place name for this activity. Prefer a name returned by the findPlaces tool so it can be pinned on the map.")
    var placeName: String
}

extension GeneratedItinerary {
    init(partial p: PartiallyGenerated) {
        self.init(
            title: p.title ?? "",
            summary: p.summary ?? "",
            rationale: p.rationale ?? "",
            days: (p.days ?? []).map { d in
                ItineraryDay(
                    title: d.title ?? "",
                    subtitle: d.subtitle ?? "",
                    activities: (d.activities ?? []).map { a in
                        ItineraryActivity(
                            kind: a.kind ?? .sightseeing,
                            title: a.title ?? "",
                            description: a.description ?? "",
                            placeName: a.placeName ?? ""
                        )
                    }
                )
            }
        )
    }
}

struct ItineraryDisplay: Equatable {
    var title: String?
    var summary: String?
    var rationale: String?
    var days: [Day]?

    struct Day: Equatable {
        var title: String?
        var subtitle: String?
        var activities: [Activity]?
    }
    struct Activity: Equatable {
        var kind: ActivityKind?
        var title: String?
        var description: String?
        var placeName: String?
    }

    init(partial p: GeneratedItinerary.PartiallyGenerated) {
        title = p.title
        summary = p.summary
        rationale = p.rationale
        days = p.days?.map { d in
            Day(title: d.title, subtitle: d.subtitle,
                activities: d.activities?.map { a in
                    Activity(kind: a.kind, title: a.title, description: a.description, placeName: a.placeName)
                })
        }
    }

    init(full i: GeneratedItinerary) {
        title = i.title
        summary = i.summary
        rationale = i.rationale
        days = i.days.map { d in
            Day(title: d.title, subtitle: d.subtitle,
                activities: d.activities.map { a in
                    Activity(kind: a.kind, title: a.title, description: a.description, placeName: a.placeName)
                })
        }
    }
}

@Generable
enum ActivityKind: String, Codable, CaseIterable {
    case wildlife
    case sightseeing
    case foodAndDining
    case lodging
    case transport
    case culture
    case shopping
    case relaxation

    var symbolName: String {
        switch self {
        case .wildlife: "binoculars.fill"
        case .sightseeing: "camera.fill"
        case .foodAndDining: "fork.knife"
        case .lodging: "bed.double.fill"
        case .transport: "car.fill"
        case .culture: "building.columns.fill"
        case .shopping: "bag.fill"
        case .relaxation: "leaf.fill"
        }
    }
}
