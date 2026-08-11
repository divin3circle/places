import Testing
import Foundation
@testable import Places

struct ProfileDecodingTests {
    @Test func decodesSnakeCaseRow() throws {
        let id = UUID().uuidString
        let json = """
        {"id":"\(id)","name":"Ada","email":"a@b.com","avatar_url":null,
         "interests":["wildlife_safaris"],"plan":"free","onboarding_complete":true}
        """
        let p = try JSONDecoder().decode(Profile.self, from: Data(json.utf8))
        #expect(p.plan == "free")
        #expect(p.onboardingComplete == true)
        #expect(p.interests == ["wildlife_safaris"])
        #expect(p.avatarURL == nil)
        #expect(p.name == "Ada")
    }
}
