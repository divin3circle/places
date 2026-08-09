import Testing
import Foundation
@testable import Places

struct ForYouItemTests {
    private func dest(_ id: String) -> DestinationDTO {
        DestinationDTO(id: id, name: "Mara", category: "Reserve", countryCode: "KE", latitude: 0, longitude: 0,
            description: "", bannerUrl: "https://b.jpg", images: [], nonResidentFeeUsd: nil, feeLabel: nil,
            vehicleFeeGuidelines: nil, paymentInfrastructure: nil, interestTags: [], bestSeason: nil,
            closestHub: nil, rating: 4.9, bestTimeToVisit: nil, priceRange: nil, isPopular: true)
    }
    private func exp(_ title: String) -> ExperienceDTO {
        ExperienceDTO(id: UUID(), title: title, images: ["https://e.jpg"], categoryTag: "wildlife_safaris",
            categoryLabel: "Wildlife safaris", cityId: "nairobi", pricePerGuest: 6500, currency: "KSh",
            rating: 4.9, reviewsCount: 10, isTrending: true, hostName: "S", hostTagline: "g",
            hostImageUrl: nil, locationName: "L", locationArea: "A", durationLabel: "4 hr",
            language: "English", description: "d", latitude: nil, longitude: nil)
    }

    @Test func projectsDestination() {
        let item = ForYouItem.destination(dest("ke_mara"))
        #expect(item.id == "d-ke_mara")
        #expect(item.imageURL == "https://b.jpg")
        #expect(item.title == "Mara")
        #expect(item.subtitle.contains("Reserve"))
    }
    @Test func projectsExperience() {
        let item = ForYouItem.experience(exp("Game Drive"))
        #expect(item.id.hasPrefix("e-"))
        #expect(item.imageURL == "https://e.jpg")
        #expect(item.title == "Game Drive")
        #expect(item.subtitle.contains("Wildlife safaris"))
    }
    @Test func interleaveAlternatesAndCaps() {
        let result = interleaveForYou(destinations: [dest("a"), dest("b")],
                                      experiences: [exp("x"), exp("y")], cap: 3)
        #expect(result.count == 3)
        #expect(result[0].id.hasPrefix("d-"))
        #expect(result[1].id.hasPrefix("e-"))
    }
    @Test func interleaveHandlesEmptySide() {
        let result = interleaveForYou(destinations: [], experiences: [exp("x")], cap: 10)
        #expect(result.count == 1)
        #expect(result[0].id.hasPrefix("e-"))
    }
}
