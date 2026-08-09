import Foundation
@testable import Places

final class FakeAuthProviding: AuthProviding {
    var restoreID: UUID?
    var signInID = UUID()

    func restoreSession() async throws -> UUID? { restoreID }
    func signInWithApple(idToken: String, rawNonce: String) async throws -> UUID { signInID }
    func signOut() async throws {}
}

final class FakeProfileProviding: ProfileProviding {
    var stored: Profile
    var shouldThrowOnFetch = false

    init(stored: Profile) { self.stored = stored }

    func fetch(id: UUID) async throws -> Profile {
        if shouldThrowOnFetch { throw URLError(.notConnectedToInternet) }
        return stored
    }
    func updateName(_ name: String, id: UUID) async throws { stored.name = name }
    func updateInterests(_ tags: [String], id: UUID) async throws { stored.interests = tags }
    func updateOnboardingComplete(_ complete: Bool, id: UUID) async throws { stored.onboardingComplete = complete }
}

extension Profile {
    static func fixture(onboardingComplete: Bool) -> Profile {
        Profile(id: UUID(), name: nil, email: "a@b.com", avatarURL: nil,
                interests: [], plan: "free", onboardingComplete: onboardingComplete)
    }
}
