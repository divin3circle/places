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
        profiles: ProfileRepository(),
        avatars: SupabaseAvatarStore()
    )

    // Fetched Home/Explore content (in-memory).
    @State private var content = ContentStore(content: SupabaseContentRepository())

    // RevenueCat purchases + entitlement (paywall data source).
    @State private var purchases = PurchasesManager()

    var body: some Scene {
        WindowGroup {
            RouterView { _ in
                ContentView()
            }
            .edgesIgnoringSafeArea(.all)
            .preferredColorScheme(AppearanceMode(rawValue: appearanceRaw)?.colorScheme)
            .environment(session)
            .environment(content)
            .environment(purchases)
            .task {
                purchases.configure()
                await session.bootstrap()
            }
            // Link RevenueCat to the Supabase user whenever we have one (bootstrap
            // or fresh sign-in) — the webhook keys token grants on this id.
            .task(id: session.currentProfile?.id) {
                guard let id = session.currentProfile?.id else { return }
                purchases.configure()
                await purchases.logIn(userId: id.uuidString)
            }
        }
        // On-device store for saved trips + bookmarks (no CloudKit).
        .modelContainer(for: [SavedTrip.self, SavedItineraryVersion.self, SavedPlace.self])
    }
}
