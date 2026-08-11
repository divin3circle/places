import Foundation
@testable import Places

final class FakeContentProviding: ContentProviding {
    var destinations: [DestinationDTO] = []
    var experiences: [ExperienceDTO] = []
    var trending: [ExperienceDTO] = []
    var shouldThrow = false
    private(set) var fetchCount = 0

    func fetchPopularDestinations() async throws -> [DestinationDTO] { try emit(destinations) }
    func fetchSponsored() async throws -> [SponsoredDTO] { try emit([]) }
    func fetchCategories() async throws -> [ExperienceCategoryDTO] { try emit([]) }
    func fetchExperiences(cityId: String?, categoryTag: String?) async throws -> [ExperienceDTO] { try emit(experiences) }
    func fetchExperiences(categoryTags: [String]) async throws -> [ExperienceDTO] { try emit(experiences) }
    func fetchDestinations(matchingTags: [String]) async throws -> [DestinationDTO] { try emit(destinations) }
    func fetchTrendingExperiences() async throws -> [ExperienceDTO] { try emit(trending) }

    private func emit<T>(_ value: [T]) throws -> [T] {
        fetchCount += 1
        if shouldThrow { throw URLError(.badServerResponse) }
        return value
    }
}
