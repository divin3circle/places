//
//  ContentStore.swift
//  Places
//
//  Single source of truth for fetched Home/Explore content. In-memory cache;
//  each section is a Loadable that guards against refetch once loaded and
//  against duplicate in-flight loads.
//

import Foundation
import Observation

@Observable @MainActor
final class ContentStore {
    private(set) var popularDestinations: Loadable<[DestinationDTO]> = .idle
    private(set) var sponsored: Loadable<[SponsoredDTO]> = .idle
    private(set) var categories: Loadable<[ExperienceCategoryDTO]> = .idle
    private(set) var experiencesByCity: [String: Loadable<[ExperienceDTO]>] = [:]
    private(set) var experiencesByCategory: [String: Loadable<[ExperienceDTO]>] = [:]
    private(set) var forYou: Loadable<[ForYouItem]> = .idle

    private let content: ContentProviding

    init(content: ContentProviding) {
        self.content = content
    }

    func loadPopularDestinations(force: Bool = false) async {
        await load(get: { self.popularDestinations }, set: { self.popularDestinations = $0 },
                   force: force, fetch: { try await self.content.fetchPopularDestinations() },
                   failure: "Couldn't load destinations.")
    }

    func loadSponsored(force: Bool = false) async {
        await load(get: { self.sponsored }, set: { self.sponsored = $0 },
                   force: force, fetch: { try await self.content.fetchSponsored() },
                   failure: "Couldn't load sponsors.")
    }

    func loadCategories(force: Bool = false) async {
        await load(get: { self.categories }, set: { self.categories = $0 },
                   force: force, fetch: { try await self.content.fetchCategories() },
                   failure: "Couldn't load categories.")
    }

    func loadExperiences(cityId: String, force: Bool = false) async {
        await load(get: { self.experiencesByCity[cityId] ?? .idle },
                   set: { self.experiencesByCity[cityId] = $0 },
                   force: force,
                   fetch: { try await self.content.fetchExperiences(cityId: cityId, categoryTag: nil) },
                   failure: "Couldn't load experiences.")
    }

    func loadExperiences(cityId: String, categoryTag: String, force: Bool = false) async {
        let key = "\(cityId)|\(categoryTag)"
        await load(get: { self.experiencesByCategory[key] ?? .idle },
                   set: { self.experiencesByCategory[key] = $0 },
                   force: force,
                   fetch: { try await self.content.fetchExperiences(cityId: cityId, categoryTag: categoryTag) },
                   failure: "Couldn't load experiences.")
    }

    func loadForYou(interests: [String], force: Bool = false) async {
        if case .loaded = forYou, !force { return }
        if case .loading = forYou { return }
        forYou = .loading
        do {
            var items: [ForYouItem] = []
            if !interests.isEmpty {
                let destTags = ForYouMapping.destinationTags(for: interests)
                async let experiences = content.fetchExperiences(categoryTags: interests)
                async let destinations = destTags.isEmpty
                    ? [DestinationDTO]() : content.fetchDestinations(matchingTags: destTags)
                let (e, d) = try await (experiences, destinations)
                items = interleaveForYou(destinations: d, experiences: e, cap: 10)
            }
            if items.isEmpty {
                items = try await content.fetchTrendingExperiences().map(ForYouItem.experience)
            }
            forYou = .loaded(items)
        } catch {
            forYou = .failed("Couldn't load recommendations.")
        }
    }

    /// Shared load routine: guards against refetch-when-loaded and duplicate
    /// in-flight loads, then transitions the section through loading → loaded/failed.
    private func load<V>(
        get: () -> Loadable<[V]>,
        set: (Loadable<[V]>) -> Void,
        force: Bool,
        fetch: () async throws -> [V],
        failure: String
    ) async {
        switch get() {
        case .loaded where !force: return
        case .loading: return          // already in flight
        default: break
        }
        set(.loading)
        do { set(.loaded(try await fetch())) }
        catch { set(.failed(failure)) }
    }
}
