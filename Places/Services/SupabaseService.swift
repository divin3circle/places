//
//  SupabaseService.swift
//  Places
//
//  The single app-wide Supabase client. Auth persists the session in the Keychain
//  and auto-refreshes tokens. Reused by auth, profiles, and later phases.
//

import Foundation
import Supabase

enum SupabaseService {
    static let client = SupabaseClient(
        supabaseURL: SupabaseConfig.projectURL,
        supabaseKey: SupabaseConfig.anonKey
    )
}
