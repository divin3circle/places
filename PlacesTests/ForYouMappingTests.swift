import Testing
@testable import Places

struct ForYouMappingTests {
    @Test func mapsAndDedupes() {
        let tags = ForYouMapping.destinationTags(for: ["wildlife_safaris", "arts_crafts", "cultural_heritage"])
        #expect(tags.contains("wildlife_core"))
        #expect(tags.contains("arts_culture"))
        #expect(tags.filter { $0 == "arts_culture" }.count == 1)
    }
    @Test func foodAndNightlifeContributeNothing() {
        #expect(ForYouMapping.destinationTags(for: ["food_coffee_tours", "nightlife_music"]).isEmpty)
    }
    @Test func unknownTagIgnored() {
        #expect(ForYouMapping.destinationTags(for: ["atlantis"]).isEmpty)
    }
}
