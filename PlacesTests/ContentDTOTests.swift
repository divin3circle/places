import Testing
import Foundation
@testable import Places

struct ContentDTOTests {
    private func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        try JSONDecoder().decode(T.self, from: Data(json.utf8))
    }

    @Test func experienceDecodes() throws {
        let e = try decode(ExperienceDTO.self, """
        {"id":"\(UUID().uuidString)","title":"Game Drive","images":["https://x/1.jpg"],
         "category_tag":"wildlife_safaris","category_label":"Wildlife safaris","city_id":"nairobi",
         "price_per_guest":6500,"currency":"KSh","rating":4.9,"reviews_count":820,"is_trending":true,
         "host_name":"Samuel","host_tagline":"Guide","host_image_url":null,"location_name":"NNP",
         "location_area":"Nairobi","duration_label":"4 hr","language":"English","description":"...",
         "latitude":-1.37,"longitude":36.85}
        """)
        #expect(e.cityId == "nairobi")
        #expect(e.hostImageUrl == nil)
        #expect(e.images.count == 1)
    }

    @Test func sponsoredDecodes() throws {
        let s = try decode(SponsoredDTO.self, """
        {"id":"\(UUID().uuidString)","image_url":"https://x/s.jpg","accent_hex":null,"category":"Food",
         "title":"Mama Oliech","subtitle":"Fish","location":"Nairobi","cta_label":"Directions",
         "city_id":"nairobi","sort_order":1}
        """)
        #expect(s.accentHex == nil)
        #expect(s.ctaLabel == "Directions")
    }

    @Test func categoryDecodesAndIdIsTag() throws {
        let c = try decode(ExperienceCategoryDTO.self,
            #"{"tag":"wildlife_safaris","label":"Wildlife safaris","image_url":null,"sort_order":1}"#)
        #expect(c.id == "wildlife_safaris")
    }

    @Test func destinationDecodes() throws {
        let d = try decode(DestinationDTO.self, """
        {"id":"ke_maasai_mara","name":"Maasai Mara","category":"Reserve","country_code":"KE",
         "latitude":-1.5,"longitude":35.1,"description":"...","banner_url":"https://x/b.jpg","images":[],
         "non_resident_fee_usd":100,"fee_label":"$100–$200","vehicle_fee_guidelines":null,
         "payment_infrastructure":null,"interest_tags":["wildlife"],"best_season":"Jul","closest_hub":"Narok",
         "rating":4.9,"best_time_to_visit":"Jul–Oct","price_range":"$$$","is_popular":true}
        """)
        #expect(d.isPopular)
        #expect(d.feeLabel == "$100–$200")
    }
}
