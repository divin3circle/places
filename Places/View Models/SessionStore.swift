//
//  SessionStore.swift
//  Places
//
//  Single source of truth for auth phase + current profile. Depends on the
//  AuthProviding / ProfileProviding seams, so it is fully unit-testable.
//

import Foundation
import Observation

@Observable @MainActor
final class SessionStore {
    enum Phase: Equatable { case booting, signedOut, onboarding, ready }

    private(set) var phase: Phase = .booting
    private(set) var currentProfile: Profile?

    private let auth: AuthProviding
    private let profiles: ProfileProviding
    private let avatars: AvatarStoring
    private let defaults: UserDefaults
    private let mirrorKey = "onboarding_complete_mirror"
    private let profileCacheKey = "cached_profile_json"
    private var userID: UUID?

    /// Max time to wait for the persisted session to restore before falling back
    /// to local state. Prevents a hung token refresh (offline) from freezing the
    /// launch on the splash screen.
    private let restoreTimeout: Duration = .seconds(4)

    init(auth: AuthProviding, profiles: ProfileProviding, avatars: AvatarStoring, defaults: UserDefaults = .standard) {
        self.auth = auth
        self.profiles = profiles
        self.avatars = avatars
        self.defaults = defaults
    }

    /// Uploads a new profile photo and persists its URL. Throws on failure so the
    /// caller can surface it; `avatar_url` is written only after a successful upload.
    func updateAvatar(jpegData: Data) async throws {
        guard let id = userID else { return }
        let url = try await avatars.uploadAvatar(jpegData, userID: id)
        try await profiles.updateAvatarURL(url, id: id)
        currentProfile?.avatarURL = url
    }

    func bootstrap() async {
        // Restore the persisted session, but never let a hung network refresh
        // (offline) freeze the launch on the splash screen. Race the restore
        // against a timeout; on timeout fall back to cached local state.
        switch await restoreSessionWithTimeout() {
        case .restored(let id):
            userID = id
            await loadProfileAndSetPhase(id: id)
        case .noSession:
            phase = .signedOut
        case .timedOut:
            enterOfflineFallback()
        }
    }

    private enum RestoreOutcome { case restored(UUID), noSession, timedOut }

    private func restoreSessionWithTimeout() async -> RestoreOutcome {
        await withTaskGroup(of: RestoreOutcome?.self) { group in
            group.addTask { [auth] in
                do {
                    if let id = try await auth.restoreSession() { return .restored(id) }
                    return .noSession
                } catch { return .noSession }
            }
            group.addTask { [restoreTimeout] in
                try? await Task.sleep(for: restoreTimeout)
                return .timedOut
            }
            let outcome = await group.next() ?? .timedOut
            group.cancelAll()
            return outcome ?? .timedOut
        }
    }

    /// Offline (or auth backend unreachable): enter the app with cached state if
    /// we know the user was signed in and onboarded, otherwise show sign-in.
    private func enterOfflineFallback() {
        if let cached = cachedProfile() {
            currentProfile = cached
            userID = cached.id
            phase = cached.onboardingComplete ? .ready : .onboarding
        } else if defaults.bool(forKey: mirrorKey) {
            phase = .ready
        } else {
            phase = .signedOut
        }
    }

    func signIn(idToken: String, rawNonce: String, appleFullName: PersonNameComponents?) async throws {
        let id = try await auth.signInWithApple(idToken: idToken, rawNonce: rawNonce)
        userID = id
        if let name = appleFullName?.formatted(), !name.isEmpty {
            try? await profiles.updateName(name, id: id)
        }
        await loadProfileAndSetPhase(id: id)
    }

    func saveInterests(_ tags: [String]) async {
        guard let id = userID else { return }
        try? await profiles.updateInterests(tags, id: id)
        currentProfile?.interests = tags
    }

    /// Marks the profile onboarded. Throws if the write fails so the caller can
    /// keep the user on the tour and retry — never advance the gate on a failed write.
    func completeOnboarding() async throws {
        guard let id = userID else { return }
        try await profiles.updateOnboardingComplete(true, id: id)
        defaults.set(true, forKey: mirrorKey)
        currentProfile?.onboardingComplete = true
        phase = .ready
    }

    /// Debug helper: sends the user back through onboarding.
    func resetOnboarding() async {
        guard let id = userID else { return }
        try? await profiles.updateOnboardingComplete(false, id: id)
        defaults.set(false, forKey: mirrorKey)
        currentProfile?.onboardingComplete = false
        phase = .onboarding
    }

    func signOut() async {
        try? await auth.signOut()
        userID = nil
        defaults.set(false, forKey: mirrorKey)
        currentProfile = nil
        phase = .signedOut
    }

    private func loadProfileAndSetPhase(id: UUID) async {
        do {
            let profile = try await profiles.fetch(id: id)
            currentProfile = profile
            cacheProfile(profile)
            defaults.set(profile.onboardingComplete, forKey: mirrorKey)
            phase = profile.onboardingComplete ? .ready : .onboarding
        } catch {
            // Offline / fetch failure with a valid session: keep the user moving
            // with the last-cached profile + onboarding mirror.
            if let cached = cachedProfile(), cached.id == id { currentProfile = cached }
            phase = defaults.bool(forKey: mirrorKey) ? .ready : .onboarding
        }
    }

    // MARK: Offline profile cache

    private func cacheProfile(_ profile: Profile) {
        if let data = try? JSONEncoder().encode(profile) {
            defaults.set(data, forKey: profileCacheKey)
        }
    }

    private func cachedProfile() -> Profile? {
        guard let data = defaults.data(forKey: profileCacheKey) else { return nil }
        return try? JSONDecoder().decode(Profile.self, from: data)
    }
}
