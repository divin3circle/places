import Testing
import Foundation
@testable import Places

@MainActor
struct SessionStoreTests {
    private func makeStore(restoreID: UUID?, profile: Profile, throwFetch: Bool = false)
        -> (SessionStore, FakeProfileProviding) {
        let auth = FakeAuthProviding()
        auth.restoreID = restoreID
        if let restoreID { auth.signInID = restoreID }
        let repo = FakeProfileProviding(stored: profile)
        repo.shouldThrowOnFetch = throwFetch
        let defaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        return (SessionStore(auth: auth, profiles: repo, avatars: FakeAvatarStoring(), defaults: defaults), repo)
    }

    @Test func bootstrapNoSessionIsSignedOut() async {
        let (store, _) = makeStore(restoreID: nil, profile: .fixture(onboardingComplete: true))
        await store.bootstrap()
        #expect(store.phase == .signedOut)
    }

    @Test func bootstrapRestoredCompleteIsReady() async {
        let (store, _) = makeStore(restoreID: UUID(), profile: .fixture(onboardingComplete: true))
        await store.bootstrap()
        #expect(store.phase == .ready)
    }

    @Test func bootstrapRestoredIncompleteIsOnboarding() async {
        let (store, _) = makeStore(restoreID: UUID(), profile: .fixture(onboardingComplete: false))
        await store.bootstrap()
        #expect(store.phase == .onboarding)
    }

    @Test func completeOnboardingBecomesReadyAndPersists() async throws {
        let (store, repo) = makeStore(restoreID: UUID(), profile: .fixture(onboardingComplete: false))
        await store.bootstrap()
        try await store.completeOnboarding()
        #expect(store.phase == .ready)
        #expect(repo.stored.onboardingComplete == true)
    }

    @Test func signOutReturnsToSignedOut() async {
        let (store, _) = makeStore(restoreID: UUID(), profile: .fixture(onboardingComplete: true))
        await store.bootstrap()
        await store.signOut()
        #expect(store.phase == .signedOut)
    }

    @Test func offlineFetchFailFallsBackToOnboarding() async {
        let (store, _) = makeStore(restoreID: UUID(), profile: .fixture(onboardingComplete: true), throwFetch: true)
        await store.bootstrap()
        #expect(store.phase == .onboarding)
    }
}
