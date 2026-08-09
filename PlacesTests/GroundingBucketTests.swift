import Testing
@testable import Places

struct GroundingBucketTests {
    @Test func destinationCategories() {
        #expect(GroundingBucket.forDestination(category: "national_park") == .wildlife)
        #expect(GroundingBucket.forDestination(category: "conservancy") == .wildlife)
        #expect(GroundingBucket.forDestination(category: "mountain") == .wildlife)
        #expect(GroundingBucket.forDestination(category: "beach") == .beach)
        #expect(GroundingBucket.forDestination(category: "cultural") == .culture)
        #expect(GroundingBucket.forDestination(category: "unknown") == .city)
    }
    @Test func experienceTags() {
        #expect(GroundingBucket.forExperience(tag: "wildlife_safaris") == .wildlife)
        #expect(GroundingBucket.forExperience(tag: "nature_hiking") == .wildlife)
        #expect(GroundingBucket.forExperience(tag: "cultural_heritage") == .culture)
        #expect(GroundingBucket.forExperience(tag: "arts_crafts") == .culture)
        #expect(GroundingBucket.forExperience(tag: "wellness_relaxation") == .beach)
        #expect(GroundingBucket.forExperience(tag: "food_coffee_tours") == .city)
        #expect(GroundingBucket.forExperience(tag: "nightlife_music") == .city)
    }
}
