//
//  AuthProviding.swift
//  Places
//
//  Thin seam over supabase-swift auth so SessionStore is unit-testable with a fake.
//

import Foundation
import Supabase

protocol AuthProviding {
    /// Restores a persisted session (Keychain, offline-capable). Returns the user id, or nil.
    func restoreSession() async throws -> UUID?
    /// Exchanges an Apple identity token for a Supabase session. Returns the user id.
    func signInWithApple(idToken: String, rawNonce: String) async throws -> UUID
    func signOut() async throws
}

struct SupabaseAuthProvider: AuthProviding {
    func restoreSession() async throws -> UUID? {
        (try? await SupabaseService.client.auth.session)?.user.id
    }

    func signInWithApple(idToken: String, rawNonce: String) async throws -> UUID {
        let session = try await SupabaseService.client.auth.signInWithIdToken(
            credentials: OpenIDConnectCredentials(provider: .apple, idToken: idToken, nonce: rawNonce)
        )
        return session.user.id
    }

    func signOut() async throws {
        try await SupabaseService.client.auth.signOut()
    }
}
