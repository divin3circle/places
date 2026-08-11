import Testing
import Foundation
@testable import Places

@MainActor
struct AvatarUpdateTests {
    private func makeStore(avatarThrows: Bool = false)
        -> (SessionStore, FakeProfileProviding, FakeAvatarStoring) {
        let id = UUID()
        let auth = FakeAuthProviding(); auth.restoreID = id
        let repo = FakeProfileProviding(stored: .fixture(onboardingComplete: true))
        let avatars = FakeAvatarStoring(); avatars.shouldThrow = avatarThrows
        let store = SessionStore(auth: auth, profiles: repo, avatars: avatars,
                                 defaults: UserDefaults(suiteName: "t-\(UUID().uuidString)")!)
        return (store, repo, avatars)
    }

    @Test func successStoresURL() async throws {
        let (store, repo, avatars) = makeStore()
        await store.bootstrap()
        try await store.updateAvatar(jpegData: Data([1, 2, 3]))
        #expect(store.currentProfile?.avatarURL == avatars.returnURL)
        #expect(repo.stored.avatarURL == avatars.returnURL)
    }

    @Test func uploadFailureThrowsAndLeavesAvatarUnchanged() async {
        let (store, _, _) = makeStore(avatarThrows: true)
        await store.bootstrap()
        await #expect(throws: (any Error).self) {
            try await store.updateAvatar(jpegData: Data([1]))
        }
        #expect(store.currentProfile?.avatarURL == nil)
    }
}
