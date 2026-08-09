//
//  FindPlacesTool.swift
//  Places
//
//  A FoundationModels tool the on-device model calls to discover real East-Africa
//  places with map coordinates. It mirrors the WWDC code-along's tool design: a
//  CLOSED @Generable enum argument (finite call space, so the model converges
//  instead of looping) plus a curated catalog that carries real lat/long. Each hit
//  is registered in the PlaceRegistry so the itinerary card can pin it on the map
//  and label it; the model receives the exact names to use as activity placeNames.
//

import Foundation
import CoreLocation
import FoundationModels

final class FindPlacesTool: Tool {
    let name = "findPlaces"
    let description = "Find real, mappable places in East Africa by kind (wildlife parks, cities, beaches, lakes, cultural sites). Returns exact place names to use for an activity's placeName."

    private let catalog: GroundingCatalog
    private let registry: PlaceRegistry

    init(catalog: GroundingCatalog, registry: PlaceRegistry) {
        self.catalog = catalog
        self.registry = registry
    }

    /// Closed set of place kinds — a finite argument space is what stops the model
    /// from re-calling the tool forever (the code-along's `Category` pattern).
    @Generable
    enum PlaceKind: String, CaseIterable {
        case wildlife
        case city
        case beach
        case lake
        case culture
    }

    @Generable
    struct Arguments {
        @Guide(description: "The kind of place to look up.")
        var kind: PlaceKind

        var category: PlaceCategory { PlaceCategory(rawValue: kind.rawValue) ?? .city }
    }

    func call(arguments: Arguments) async throws -> String {
        ItineraryLog.debug("🔧 [findPlaces] called with kind=\(arguments.kind.rawValue)")
        let matches = catalog.entries(in: arguments.category)

        // PlaceRegistry is main-actor isolated; register there in one hop.
        await MainActor.run {
            for entry in matches { registry.register(entry.resolvedPlace) }
        }

        ItineraryLog.debug("🔧 [findPlaces] registered \(matches.count) \(arguments.kind.rawValue) place(s)")
        let lines = matches.map { "- \($0.name): \($0.subtitle)" }
        return """
        Real \(arguments.kind.rawValue) places you can use (use these EXACT names as an activity's placeName):
        \(lines.joined(separator: "\n"))
        """
    }
}
