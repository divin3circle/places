//
//  GroundingCatalog.swift
//  Places
//
//  The live grounding palette for one itinerary session (replaces the static
//  PlaceCatalog): valid place names for the models + resolved places for the map.
//

import Foundation

nonisolated struct GroundingCatalog {
    let places: [GroundingPlace]

    var names: [String] { places.map(\.name) }

    func entries(in category: PlaceCategory) -> [GroundingPlace] {
        places.filter { $0.bucket == category }
    }

    var resolvedPlaces: [ResolvedPlace] { places.map(\.resolvedPlace) }

    static let empty = GroundingCatalog(places: [])
}
