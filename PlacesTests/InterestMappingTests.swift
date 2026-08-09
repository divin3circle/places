import Testing
@testable import Places

struct InterestMappingTests {
    let all = ["wildlife_safaris", "nature_hiking", "cultural_heritage", "food_coffee_tours",
               "arts_crafts", "adventure_sports", "wellness_relaxation", "nightlife_music"]

    @Test func everyChipTagIsAValidCategory() {
        for interest in EastAfricaInterestsDataset {
            #expect(all.contains(interest.categoryTag))
        }
    }

    @Test func datasetCoversAllEightCategories() {
        let covered = Set(EastAfricaInterestsDataset.map(\.categoryTag))
        #expect(covered == Set(all))
    }

    @Test func selectionDedupesToTags() {
        let wildlife = EastAfricaInterestsDataset.filter { $0.categoryTag == "wildlife_safaris" }
        #expect(wildlife.count >= 2)
        let tags = categoryTags(for: Set(wildlife))
        #expect(tags == ["wildlife_safaris"])
    }
}
