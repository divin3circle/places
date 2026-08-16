//
//  AuthProviding.swift
//  Places
//
//  Thin seam over supabase-swift auth so SessionStore is unit-testable with a fake.
//

import Foundation
import Supabase

protocol AuthProviding: Sendable {
    /// Restores a persisted session (Keychain, offline-capable). Returns the user id, or nil.
    func restoreSession() async throws -> UUID?
    /// Exchanges an Apple identity token for a Supabase session. Returns the user id.
    func signInWithApple(idToken: String, rawNonce: String) async throws -> UUID
    func signOut() async throws
    /// Permanently deletes the signed-in user's account and server data. Throws on failure.
    func deleteAccount() async throws
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

    func deleteAccount() async throws {
        // Authenticated POST to the delete-account Edge Function, which deletes the
        // user's data + auth user with the service role. The user's JWT identifies
        // whose account to delete (the server never trusts a client-supplied id).
        guard let token = try? await SupabaseService.client.auth.session.accessToken else {
            throw NSError(domain: "DeleteAccount", code: 401,
                          userInfo: [NSLocalizedDescriptionKey: "You're signed out. Please sign in again."])
        }
        var req = URLRequest(url: SupabaseConfig.deleteAccountFunctionURL)
        req.httpMethod = "POST"
        req.timeoutInterval = 30
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "DeleteAccount", code: (response as? HTTPURLResponse)?.statusCode ?? -1,
                          userInfo: [NSLocalizedDescriptionKey: "Couldn't delete your account. \(body)"])
        }
    }
}
