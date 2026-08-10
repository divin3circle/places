//
//  PlaceRegistry.swift
//  Places
//
//  Bridges the AI's `placeName` strings to real geo + imagery. Tools populate it
//  during generation (from Destination / Experience data); the itinerary card
//  reads it to draw the map and place images. This keeps coordinates app-owned
//  and reliable rather than trusting the model to emit exact lat/long.
//

import Foundation
import CoreLocation
import Observation

struct ResolvedPlace: Identifiable {
    var id: String { name.lowercased() }
    let name: String
    let coordinate: CLLocationCoordinate2D
    var imageName: String? = nil
    var imageURL: URL? = nil
    var subtitle: String? = nil
}

@MainActor
@Observable
final class PlaceRegistry {
    private(set) var places: [String: ResolvedPlace] = [:]

    func register(_ place: ResolvedPlace) {
        places[Self.normalize(place.name)] = place
    }

    /// Resolve tolerantly: exact (normalized) match first, then the best
    /// word-token overlap. Lets minor model deviations ("Nairobi Park" vs
    /// "Nairobi National Park") still land on a real pin/image instead of nil.
    func resolve(_ name: String) -> ResolvedPlace? {
        let key = Self.normalize(name)
        if let exact = places[key] { return exact }

        let queryTokens = Self.tokens(name)
        guard !queryTokens.isEmpty else { return nil }
        var best: (place: ResolvedPlace, score: Int)?
        for place in places.values {
            let overlap = queryTokens.intersection(Self.tokens(place.name)).count
            if overlap > 0, overlap > (best?.score ?? 0) {
                best = (place, overlap)
            }
        }
        return best?.place
    }

    var all: [ResolvedPlace] { Array(places.values) }

    private static func normalize(_ s: String) -> String {
        s.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Meaningful lowercase word tokens (drops generic filler words).
    private static let fillers: Set<String> = ["national", "reserve", "the", "of", "and"]
    private static func tokens(_ s: String) -> Set<String> {
        Set(
            s.lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { !$0.isEmpty && !fillers.contains($0) }
        )
    }
}
