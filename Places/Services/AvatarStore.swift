//
//  AvatarStore.swift
//  Places
//
//  Uploads a profile photo to the Supabase `avatars` bucket. Protocol seam keeps
//  SessionStore testable with a fake.
//

import Foundation
import Supabase

protocol AvatarStoring {
    /// Uploads JPEG data to avatars/<uid>/<uuid>.jpg and returns the public URL string.
    func uploadAvatar(_ data: Data, userID: UUID) async throws -> String
}

struct SupabaseAvatarStore: AvatarStoring {
    func uploadAvatar(_ data: Data, userID: UUID) async throws -> String {
        // The folder MUST be the lowercased uid to satisfy the owner-write RLS
        // (Postgres `auth.uid()::text` is lowercase; Swift's UUID.uuidString is upper).
        let path = "\(userID.uuidString.lowercased())/\(UUID().uuidString.lowercased()).jpg"
        let bucket = SupabaseService.client.storage.from("avatars")
        try await bucket.upload(path, data: data, options: FileOptions(contentType: "image/jpeg"))
        return try bucket.getPublicURL(path: path).absoluteString
    }
}
