//
//  PlacesApp.swift
//  Places
//
//  Created by Sylus Abel on 27/07/2026.
//

import SwiftUI
import SwiftfulRouting

@main
struct PlacesApp: App {
    @AppStorage("appearanceMode") private var appearanceRaw = AppearanceMode.system.rawValue

    var body: some Scene {
        WindowGroup {
            RouterView { _ in
                ContentView()
            }
            .edgesIgnoringSafeArea(.all)
            .preferredColorScheme(AppearanceMode(rawValue: appearanceRaw)?.colorScheme)
        }
    }
}
