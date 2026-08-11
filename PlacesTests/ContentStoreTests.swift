import Testing
import Foundation
@testable import Places

@MainActor
struct ContentStoreTests {
    private func loadedCount<T>(_ l: Loadable<[T]>) -> Int? {
        if case .loaded(let v) = l { return v.count }
        return nil
    }
    private func isFailed<T>(_ l: Loadable<[T]>) -> Bool {
        if case .failed = l { return true }
        return false
    }

    @Test func loadsDestinations() async {
        let fake = FakeContentProviding()
        fake.destinations = [Self.destFixture()]
        let store = ContentStore(content: fake)
        await store.loadPopularDestinations()
        #expect(loadedCount(store.popularDestinations) == 1)
    }

    @Test func emptyStaysLoadedEmpty() async {
        let store = ContentStore(content: FakeContentProviding())
        await store.loadPopularDestinations()
        #expect(loadedCount(store.popularDestinations) == 0)
    }

    @Test func failureIsFailed() async {
        let fake = FakeContentProviding(); fake.shouldThrow = true
        let store = ContentStore(content: fake)
        await store.loadPopularDestinations()
        #expect(isFailed(store.popularDestinations))
    }

    @Test func guardSkipsRefetch() async {
        let fake = FakeContentProviding()
        let store = ContentStore(content: fake)
        await store.loadPopularDestinations()
        await store.loadPopularDestinations()
        #expect(fake.fetchCount == 1)
    }

    @Test func forceRefetches() async {
        let fake = FakeContentProviding()
        let store = ContentStore(content: fake)
        await store.loadPopularDestinations()
        await store.loadPopularDestinations(force: true)
        #expect(fake.fetchCount == 2)
    }

    static func destFixture() -> DestinationDTO {
        DestinationDTO(id: "x", name: "N", category: "C", countryCode: "KE", latitude: 0, longitude: 0,
            description: "", bannerUrl: "https://b.jpg", images: [], nonResidentFeeUsd: nil, feeLabel: nil,
            vehicleFeeGuidelines: nil, paymentInfrastructure: nil, interestTags: [], bestSeason: nil,
            closestHub: nil, rating: 4.5, bestTimeToVisit: nil, priceRange: nil, isPopular: true)
    }
}
