//
//  ProfileRepository.swift
//  Places
//
//  PostgREST access to the `profiles` table (owner-gated by RLS). Protocol seam
//  keeps SessionStore testable with a fake.
//

import Foundation
import Supabase

protocol ProfileProviding {
    func fetch(id: UUID) async throws -> Profile
    func updateName(_ name: String, id: UUID) async throws
    func updateInterests(_ tags: [String], id: UUID) async throws
    func updateOnboardingComplete(_ complete: Bool, id: UUID) async throws
}

struct ProfileRepository: ProfileProviding {
    func fetch(id: UUID) async throws -> Profile {
        try await SupabaseService.client
            .from("profiles")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
    }

    func updateName(_ name: String, id: UUID) async throws {
        try await SupabaseService.client
            .from("profiles")
            .update(["name": name])
            .eq("id", value: id.uuidString)
            .execute()
    }

    func updateInterests(_ tags: [String], id: UUID) async throws {
        try await SupabaseService.client
            .from("profiles")
            .update(["interests": tags])
            .eq("id", value: id.uuidString)
            .execute()
    }

    func updateOnboardingComplete(_ complete: Bool, id: UUID) async throws {
        try await SupabaseService.client
            .from("profiles")
            .update(["onboarding_complete": complete])
            .eq("id", value: id.uuidString)
            .execute()
    }
}
