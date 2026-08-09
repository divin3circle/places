//
//  ContentStore.swift
//  Places
//
//  Single source of truth for fetched Home/Explore content. In-memory cache;
//  each section is a Loadable that guards against refetch once loaded.
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

    private let content: ContentProviding

    init(content: ContentProviding = SupabaseContentRepository()) {
        self.content = content
    }

    func loadPopularDestinations(force: Bool = false) async {
        if case .loaded = popularDestinations, !force { return }
        popularDestinations = .loading
        do { popularDestinations = .loaded(try await content.fetchPopularDestinations()) }
        catch { popularDestinations = .failed("Couldn't load destinations.") }
    }

    func loadSponsored(force: Bool = false) async {
        if case .loaded = sponsored, !force { return }
        sponsored = .loading
        do { sponsored = .loaded(try await content.fetchSponsored()) }
        catch { sponsored = .failed("Couldn't load sponsors.") }
    }

    func loadCategories(force: Bool = false) async {
        if case .loaded = categories, !force { return }
        categories = .loading
        do { categories = .loaded(try await content.fetchCategories()) }
        catch { categories = .failed("Couldn't load categories.") }
    }

    func loadExperiences(cityId: String, force: Bool = false) async {
        if case .loaded = (experiencesByCity[cityId] ?? .idle), !force { return }
        experiencesByCity[cityId] = .loading
        do { experiencesByCity[cityId] = .loaded(try await content.fetchExperiences(cityId: cityId, categoryTag: nil)) }
        catch { experiencesByCity[cityId] = .failed("Couldn't load experiences.") }
    }

    func loadExperiences(cityId: String, categoryTag: String, force: Bool = false) async {
        let key = "\(cityId)|\(categoryTag)"
        if case .loaded = (experiencesByCategory[key] ?? .idle), !force { return }
        experiencesByCategory[key] = .loading
        do { experiencesByCategory[key] = .loaded(try await content.fetchExperiences(cityId: cityId, categoryTag: categoryTag)) }
        catch { experiencesByCategory[key] = .failed("Couldn't load experiences.") }
    }
}
