//
//  PlaceCategory.swift
//  Places
//
//  The closed set of place kinds the itinerary grounding buckets into. Shared by
//  the on-device tool's @Generable argument, the grounding catalog, and the map
//  registry. `nonisolated` so it's reachable from tool calls (non-isolated) and
//  the main actor alike.
//

nonisolated enum PlaceCategory: String, CaseIterable, Sendable {
    case wildlife
    case city
    case beach
    case lake
    case culture
}
