//
//  PlacesApp.swift
//  Places
//
//  Created by Sylus Abel on 27/07/2026.
//

import SwiftUI
import SwiftfulRouting
import SwiftData

@main
struct PlacesApp: App {
    @AppStorage("appearanceMode") private var appearanceRaw = AppearanceMode.system.rawValue

    // Single source of truth for auth phase + current profile.
    @State private var session = SessionStore(
        auth: SupabaseAuthProvider(),
        profiles: ProfileRepository()
    )

    // Fetched Home/Explore content (in-memory).
    @State private var content = ContentStore()

    var body: some Scene {
        WindowGroup {
            RouterView { _ in
                ContentView()
            }
            .edgesIgnoringSafeArea(.all)
            .preferredColorScheme(AppearanceMode(rawValue: appearanceRaw)?.colorScheme)
            .environment(session)
            .environment(content)
            .task { await session.bootstrap() }
        }
        // On-device store for saved trips (no CloudKit).
        .modelContainer(for: [SavedTrip.self, SavedItineraryVersion.self])
    }
}
