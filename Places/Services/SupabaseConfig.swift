//
//  SupabaseConfig.swift
//  Places
//
//  Client-public Supabase values (safe to embed — the anon key is designed to ship
//  in clients; the OpenAI key lives ONLY in the Edge Function's secret). Fill these
//  after creating your Supabase project. Can later move to an .xcconfig / Info.plist.
//

import Foundation

enum SupabaseConfig {
    /// e.g. https://abcdefgh.supabase.co/functions/v1
    static let functionsBaseURL = URL(string: "https://bwafaffjhaxclcmrjhdg.supabase.co/functions/v1")!

    /// The project's base URL (for the supabase-swift client).
    static let projectURL = URL(string: "https://bwafaffjhaxclcmrjhdg.supabase.co")!

    /// The project's anon (publishable) key.
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ3YWZhZmZqaGF4Y2xjbXJqaGRnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODYyMTYyMDYsImV4cCI6MjEwMTc5MjIwNn0.CBEUxuMuSWnd_TzpOerkcc_8XdbPwmHzl6SvQnsuzq0"

    /// Name of the deployed Edge Function.
    static let itineraryFunction = "generate-itinerary"

    static var itineraryFunctionURL: URL {
        functionsBaseURL.appendingPathComponent(itineraryFunction)
    }
}
