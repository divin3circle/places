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
            signedOutState()
        case .timedOut:
            // Slow/hung restore. Only enter the app if we have cached evidence of a
            // signed-in user (never a userless .ready); reconcile once the net resolves.
            if let cached = cachedProfile() {
                userID = cached.id
                currentProfile = cached
                phase = cached.onboardingComplete ? .ready : .onboarding
                Task { await reconcileSessionInBackground() }
            } else {
                signedOutState()
            }
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

    private func signedOutState() {
        userID = nil
        currentProfile = nil
        phase = .signedOut
    }

    /// After a timed-out launch, confirm the session (no timeout now) and refresh
    /// the profile so a stale/cached avatar self-heals without a re-login. Never
    /// signs the user out on a nil result — that could be a transient offline read.
    private func reconcileSessionInBackground() async {
        guard let id = try? await auth.restoreSession() else { return }
        userID = id
        await loadProfileAndSetPhase(id: id)
    }

    /// Re-fetch the current profile (call when connectivity returns or the app
    /// foregrounds) so a stale or synthesized profile picks up the real name/avatar.
    func refreshProfile() async {
        guard let id = userID else { return }
        await loadProfileAndSetPhase(id: id)
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
        defaults.removeObject(forKey: profileCacheKey)   // don't offline-restore a signed-out user
        currentProfile = nil
        phase = .signedOut
    }

    /// Permanently deletes the user's account and server data (Apple 5.1.1(v)),
    /// then tears down local state exactly like `signOut`. Throws if the server
    /// delete fails so the caller can surface it and keep the user signed in.
    func deleteAccount() async throws {
        try await auth.deleteAccount()
        userID = nil
        defaults.set(false, forKey: mirrorKey)
        defaults.removeObject(forKey: profileCacheKey)
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
            // Offline / fetch failure with a valid session: keep the user moving.
            // Prefer the cached profile; otherwise synthesize a minimal one so the
            // app always has a valid user id (plans won't load without it) — the
            // real name/avatar fill in on the next successful refresh.
            if let cached = cachedProfile(), cached.id == id {
                currentProfile = cached
            } else if currentProfile?.id != id {
                currentProfile = Profile(id: id, name: nil, email: nil, avatarURL: nil,
                                         interests: [], plan: "free",
                                         onboardingComplete: defaults.bool(forKey: mirrorKey),
                                         planProduct: nil, proExpiresAt: nil)
            }
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
