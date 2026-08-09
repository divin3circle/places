//
//  GroundingRepository.swift
//  Places
//
//  Fetches the live grounding palette (all destinations + coord-bearing
//  experiences) for itinerary generation. Protocol seam for testability.
//

import Foundation
import Supabase

nonisolated protocol GroundingProviding {
    func fetchGroundingPlaces() async throws -> [GroundingPlace]
}

nonisolated struct SupabaseGroundingRepository: GroundingProviding {
    func fetchGroundingPlaces() async throws -> [GroundingPlace] {
        async let dests: [DestinationDTO] = SupabaseService.client.from("destinations").select().execute().value
        async let exps: [ExperienceDTO] = SupabaseService.client.from("experiences").select().execute().value
        let (d, e) = try await (dests, exps)
        return d.map { GroundingPlace(destination: $0) } + e.compactMap { GroundingPlace(experience: $0) }
    }
}
