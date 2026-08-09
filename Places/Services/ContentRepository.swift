//
//  ContentRepository.swift
//  Places
//
//  Public-read content fetches over PostgREST. Protocol seam keeps ContentStore
//  testable with a fake.
//

import Foundation
import Supabase

protocol ContentProviding {
    func fetchPopularDestinations() async throws -> [DestinationDTO]
    func fetchSponsored() async throws -> [SponsoredDTO]
    func fetchCategories() async throws -> [ExperienceCategoryDTO]
    func fetchExperiences(cityId: String?, categoryTag: String?) async throws -> [ExperienceDTO]
}

struct SupabaseContentRepository: ContentProviding {
    private var db: SupabaseClient { SupabaseService.client }

    func fetchPopularDestinations() async throws -> [DestinationDTO] {
        try await db.from("destinations")
            .select()
            .eq("is_popular", value: true)
            .order("rating", ascending: false)
            .execute()
            .value
    }

    func fetchSponsored() async throws -> [SponsoredDTO] {
        try await db.from("sponsored")
            .select()
            .order("sort_order")
            .execute()
            .value
    }

    func fetchCategories() async throws -> [ExperienceCategoryDTO] {
        try await db.from("experience_categories")
            .select()
            .order("sort_order")
            .execute()
            .value
    }

    func fetchExperiences(cityId: String?, categoryTag: String?) async throws -> [ExperienceDTO] {
        var query = db.from("experiences").select()
        if let cityId { query = query.eq("city_id", value: cityId) }
        if let categoryTag { query = query.eq("category_tag", value: categoryTag) }
        return try await query
            .order("is_trending", ascending: false)
            .order("rating", ascending: false)
            .execute()
            .value
    }
}
