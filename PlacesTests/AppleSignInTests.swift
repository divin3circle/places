import Testing
@testable import Places

struct AppleSignInTests {
    @Test func nonceHasRequestedLength() {
        #expect(AppleSignIn.randomNonceString(length: 32).count == 32)
    }

    @Test func noncesAreUnique() {
        #expect(AppleSignIn.randomNonceString() != AppleSignIn.randomNonceString())
    }

    @Test func sha256MatchesKnownVector() {
        // SHA-256("abc") canonical test vector.
        #expect(AppleSignIn.sha256("abc") ==
                "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    }
}
