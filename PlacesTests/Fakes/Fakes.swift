import Foundation
@testable import Places

final class FakeAuthProviding: AuthProviding, @unchecked Sendable {
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
    func updateAvatarURL(_ url: String, id: UUID) async throws { stored.avatarURL = url }
}

final class FakeAvatarStoring: AvatarStoring {
    var returnURL = "https://cdn.example/avatar.jpg"
    var shouldThrow = false
    private(set) var uploadCount = 0
    func uploadAvatar(_ data: Data, userID: UUID) async throws -> String {
        uploadCount += 1
        if shouldThrow { throw URLError(.badServerResponse) }
        return returnURL
    }
}

extension Profile {
    static func fixture(onboardingComplete: Bool) -> Profile {
        Profile(id: UUID(), name: nil, email: "a@b.com", avatarURL: nil,
                interests: [], plan: "free", onboardingComplete: onboardingComplete)
    }
}
