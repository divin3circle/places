import Testing
import Foundation
@testable import Places

@MainActor
struct ForYouStoreTests {
    private func exp(trending: Bool = false) -> ExperienceDTO {
        ExperienceDTO(id: UUID(), title: "E", images: [], categoryTag: "wildlife_safaris",
            categoryLabel: "Wildlife safaris", cityId: "nairobi", pricePerGuest: 1, currency: "KSh",
            rating: 4, reviewsCount: 0, isTrending: trending, hostName: "", hostTagline: "",
            hostImageUrl: nil, locationName: "", locationArea: "", durationLabel: "", language: "",
            description: "", latitude: nil, longitude: nil)
    }
    private func loaded(_ l: Loadable<[ForYouItem]>) -> [ForYouItem]? {
        if case .loaded(let v) = l { return v }
        return nil
    }

    @Test func interestsProduceMix() async {
        let fake = FakeContentProviding()
        fake.destinations = [ContentStoreTests.destFixture()]
        fake.experiences = [exp()]
        let store = ContentStore(content: fake)
        await store.loadForYou(interests: ["wildlife_safaris"])
        let items = loaded(store.forYou)
        #expect(items?.contains { $0.id.hasPrefix("d-") } == true)
        #expect(items?.contains { $0.id.hasPrefix("e-") } == true)
    }
    @Test func noInterestsFallsBackToTrending() async {
        let fake = FakeContentProviding(); fake.trending = [exp(trending: true)]
        let store = ContentStore(content: fake)
        await store.loadForYou(interests: [])
        #expect(loaded(store.forYou)?.count == 1)
        #expect(loaded(store.forYou)?.first?.id.hasPrefix("e-") == true)
    }
    @Test func emptyMatchesFallBackToTrending() async {
        let fake = FakeContentProviding(); fake.trending = [exp(trending: true)]
        let store = ContentStore(content: fake)
        await store.loadForYou(interests: ["wildlife_safaris"])
        #expect(loaded(store.forYou)?.count == 1)
    }
}
