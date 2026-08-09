import Testing
import Foundation
@testable import Places

struct ContentMappingTests {
    @Test func experienceMapsCityAndImages() {
        let dto = ExperienceDTO(id: UUID(), title: "T", images: ["u1", "u2"], categoryTag: "wildlife_safaris",
            categoryLabel: "Wildlife safaris", cityId: "kampala", pricePerGuest: 100, currency: "KSh",
            rating: 4.5, reviewsCount: 10, isTrending: true, hostName: "H", hostTagline: "tag",
            hostImageUrl: "https://h.jpg", locationName: "L", locationArea: "A", durationLabel: "2 hr",
            language: "English", description: "d", latitude: nil, longitude: nil)
        let e = Experience(dto: dto)
        #expect(e.city == .kampala)
        #expect(e.imageNames == ["u1", "u2"])
        #expect(e.hostImageName == "https://h.jpg")
    }

    @Test func experienceUnknownCityDefaultsNairobi() {
        let dto = ExperienceDTO(id: UUID(), title: "T", images: [], categoryTag: "x", categoryLabel: "X",
            cityId: "atlantis", pricePerGuest: 1, currency: "KSh", rating: 1, reviewsCount: 0, isTrending: false,
            hostName: "", hostTagline: "", hostImageUrl: nil, locationName: "", locationArea: "",
            durationLabel: "", language: "", description: "", latitude: nil, longitude: nil)
        #expect(Experience(dto: dto).city == .nairobi)
        #expect(Experience(dto: dto).hostImageName == "")
    }

    @Test func categoryMapsImageUrl() {
        let c = ExperienceCategory(dto: ExperienceCategoryDTO(tag: "t", label: "L", imageUrl: "https://c.jpg", sortOrder: 1))
        #expect(c.imageName == "https://c.jpg")
        #expect(c.tag == "t")
    }
}
