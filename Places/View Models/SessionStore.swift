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
    private var userID: UUID?

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
        do {
            guard let id = try await auth.restoreSession() else { phase = .signedOut; return }
            userID = id
            await loadProfileAndSetPhase(id: id)
        } catch {
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
            defaults.set(profile.onboardingComplete, forKey: mirrorKey)
            phase = profile.onboardingComplete ? .ready : .onboarding
        } catch {
            // Offline / fetch failure with a valid session: fall back to the local mirror.
            phase = defaults.bool(forKey: mirrorKey) ? .ready : .onboarding
        }
    }
}
