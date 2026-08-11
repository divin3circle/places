import Testing
import Foundation
import CoreLocation
@testable import Places

struct GroundingPlaceTests {
    private func dest() -> DestinationDTO {
        DestinationDTO(id: "ke_mara", name: "Maasai Mara", category: "national_park", countryCode: "KE",
            latitude: -1.5, longitude: 35.1, description: "", bannerUrl: "https://b.jpg", images: [],
            nonResidentFeeUsd: nil, feeLabel: nil, vehicleFeeGuidelines: nil, paymentInfrastructure: nil,
            interestTags: [], bestSeason: nil, closestHub: nil, rating: 4.9, bestTimeToVisit: nil,
            priceRange: nil, isPopular: true)
    }
    private func exp(lat: Double?, lng: Double?) -> ExperienceDTO {
        ExperienceDTO(id: UUID(), title: "Game Drive", images: ["https://e.jpg"], categoryTag: "wildlife_safaris",
            categoryLabel: "Wildlife safaris", cityId: "nairobi", pricePerGuest: 1, currency: "KSh",
            rating: 4, reviewsCount: 0, isTrending: false, hostName: "", hostTagline: "", hostImageUrl: nil,
            locationName: "", locationArea: "", durationLabel: "", language: "", description: "",
            latitude: lat, longitude: lng)
    }

    @Test func mapsDestination() {
        let p = GroundingPlace(destination: dest())
        #expect(p.name == "Maasai Mara")
        #expect(p.bucket == .wildlife)
        #expect(p.imageURL == "https://b.jpg")
        #expect(p.resolvedPlace.coordinate.latitude == -1.5)
        #expect(p.resolvedPlace.imageURL?.absoluteString == "https://b.jpg")
    }
    @Test func mapsExperienceWithCoords() {
        let p = GroundingPlace(experience: exp(lat: -1.3, lng: 36.8))
        #expect(p != nil)
        #expect(p?.bucket == .wildlife)
        #expect(p?.imageURL == "https://e.jpg")
    }
    @Test func dropsExperienceWithoutCoords() {
        #expect(GroundingPlace(experience: exp(lat: nil, lng: nil)) == nil)
    }
}
