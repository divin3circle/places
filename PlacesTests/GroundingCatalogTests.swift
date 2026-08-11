import Testing
import Foundation
@testable import Places

struct GroundingCatalogTests {
    private func place(_ name: String, _ bucket: PlaceCategory) -> GroundingPlace {
        GroundingPlace(name: name, latitude: 0, longitude: 0, imageURL: "https://x.jpg", subtitle: "s", bucket: bucket)
    }
    @Test func namesAndBucketFilter() {
        let c = GroundingCatalog(places: [place("A", .wildlife), place("B", .city), place("C", .wildlife)])
        #expect(c.names == ["A", "B", "C"])
        #expect(c.entries(in: .wildlife).map(\.name) == ["A", "C"])
        #expect(c.resolvedPlaces.count == 3)
        #expect(c.entries(in: .lake).isEmpty)
    }
    @Test func emptyCatalog() {
        #expect(GroundingCatalog.empty.names.isEmpty)
    }
}
