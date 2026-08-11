//
//  GeneratedItinerary.swift
//  Places
//
//  The structured itinerary the AI produces. Deep fields (startTime, duration,
//  note, price, day travelNote, trip tips) are OPTIONAL so they stay backward-
//  compatible with both engines: absent in cloud JSON → nil (Codable), and
//  omittable while the on-device model streams.
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

    @Guide(description: "Three to five short, practical trip tips: weather, getting around, money, what to pack")
    var tips: [String]?

    @Guide(description: "The day-by-day plan, one entry per trip day")
    var days: [ItineraryDay]
}

@Generable
struct ItineraryDay: Equatable, Codable {
    @Guide(description: "A short, exciting title for the day")
    var title: String
    var subtitle: String

    @Guide(description: "One-line logistics note for the day (drive time, transfers). Optional.")
    var travelNote: String?

    @Guide(description: "Two to four activities for the day, in time order")
    var activities: [ItineraryActivity]
}

@Generable
struct ItineraryActivity: Equatable, Codable {
    var kind: ActivityKind
    var title: String
    var description: String

    @Guide(description: "Local start time in 24h 'HH:mm' (e.g. '09:30'). Omit if flexible.")
    var startTime: String?

    @Guide(description: "Rough duration in minutes (e.g. 120). Omit if open-ended.")
    var durationMinutes: Int?

    @Guide(description: "One short, practical tip for this stop (booking, what to bring, timing).")
    var note: String?

    @Guide(description: "Estimated cost for this activity for the whole party.")
    var price: MoneyEstimate?

    @Guide(description: "The real place name for this activity. Prefer a name returned by the findPlaces tool so it can be pinned on the map.")
    var placeName: String
}

@Generable
struct MoneyEstimate: Equatable, Codable {
    @Guide(description: "Estimated amount for the whole party; 0 if free.")
    var amount: Double
    @Guide(description: "Currency code: 'USD' or 'KES'.")
    var currency: String
}

extension GeneratedItinerary {
    static let example = GeneratedItinerary(
        title: "Rift Valley Escape",
        summary: "A short, active getaway blending wildlife and lakeside relaxation.",
        rationale: "Balances big-game viewing with easy travel days for a relaxed pace.",
        tips: [
            "Mornings are cool — pack a light jacket.",
            "Carry some cash; card acceptance varies outside cities.",
            "Park-to-park drives are long; start early."
        ],
        days: [
            ItineraryDay(
                title: "Arrival & City Warm-up",
                subtitle: "Ease in with sights and a great meal.",
                travelNote: "Short transfers within the city.",
                activities: [
                    ItineraryActivity(kind: .sightseeing, title: "Explore the old town",
                                      description: "A gentle afternoon walk to get oriented.",
                                      startTime: "15:00", durationMinutes: 120, note: "Wear comfortable shoes.",
                                      price: MoneyEstimate(amount: 0, currency: "USD"), placeName: "Nairobi"),
                    ItineraryActivity(kind: .foodAndDining, title: "Dinner with local flavors",
                                      description: "Sample regional cuisine.",
                                      startTime: "19:30", durationMinutes: 90, note: "Book ahead on weekends.",
                                      price: MoneyEstimate(amount: 25, currency: "USD"), placeName: "Nairobi")
                ]
            ),
            ItineraryDay(
                title: "Into the Wild",
                subtitle: "A full day on safari.",
                travelNote: "Early start; long drive to the reserve.",
                activities: [
                    ItineraryActivity(kind: .wildlife, title: "Morning game drive",
                                      description: "Track big cats at first light.",
                                      startTime: "06:30", durationMinutes: 240, note: "Bring binoculars.",
                                      price: MoneyEstimate(amount: 80, currency: "USD"), placeName: "Maasai Mara"),
                    ItineraryActivity(kind: .lodging, title: "Stay at a tented camp",
                                      description: "Rest under the stars.",
                                      startTime: "18:00", durationMinutes: 0, note: "Charging is limited — bring a power bank.",
                                      price: MoneyEstimate(amount: 150, currency: "USD"), placeName: "Maasai Mara")
                ]
            )
        ]
    )
}

extension GeneratedItinerary {
    init(partial p: PartiallyGenerated) {
        self.init(
            title: p.title ?? "",
            summary: p.summary ?? "",
            rationale: p.rationale ?? "",
            tips: p.tips,
            days: (p.days ?? []).map { d in
                ItineraryDay(
                    title: d.title ?? "",
                    subtitle: d.subtitle ?? "",
                    travelNote: d.travelNote ?? nil,
                    activities: (d.activities ?? []).map { a in
                        ItineraryActivity(
                            kind: a.kind ?? .sightseeing,
                            title: a.title ?? "",
                            description: a.description ?? "",
                            startTime: a.startTime ?? nil,
                            durationMinutes: a.durationMinutes ?? nil,
                            note: a.note ?? nil,
                            price: a.price.map { MoneyEstimate(amount: $0.amount ?? 0, currency: $0.currency ?? "USD") },
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
    var tips: [String]?
    var days: [Day]?

    struct Day: Equatable {
        var title: String?
        var subtitle: String?
        var travelNote: String?
        var activities: [Activity]?
    }
    struct Activity: Equatable {
        var kind: ActivityKind?
        var title: String?
        var description: String?
        var startTime: String?
        var durationMinutes: Int?
        var note: String?
        var price: MoneyEstimate?
        var placeName: String?
    }

    init(partial p: GeneratedItinerary.PartiallyGenerated) {
        title = p.title
        summary = p.summary
        rationale = p.rationale
        tips = p.tips
        days = p.days?.map { d in
            Day(title: d.title, subtitle: d.subtitle, travelNote: d.travelNote,
                activities: d.activities?.map { a in
                    Activity(kind: a.kind, title: a.title, description: a.description,
                             startTime: a.startTime, durationMinutes: a.durationMinutes, note: a.note,
                             price: a.price.map { MoneyEstimate(amount: $0.amount ?? 0, currency: $0.currency ?? "USD") },
                             placeName: a.placeName)
                })
        }
    }

    init(full i: GeneratedItinerary) {
        title = i.title
        summary = i.summary
        rationale = i.rationale
        tips = i.tips
        days = i.days.map { d in
            Day(title: d.title, subtitle: d.subtitle, travelNote: d.travelNote,
                activities: d.activities.map { a in
                    Activity(kind: a.kind, title: a.title, description: a.description,
                             startTime: a.startTime, durationMinutes: a.durationMinutes, note: a.note,
                             price: a.price, placeName: a.placeName)
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
