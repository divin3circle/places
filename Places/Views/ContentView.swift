//
//  ContentView.swift
//  Places
//
//  Root gate: shows the right surface for the current auth phase.
//

import SwiftUI

struct ContentView: View {
    @Environment(SessionStore.self) private var session: SessionStore?

    var body: some View {
        switch session?.phase ?? .booting {
        case .booting:
            SplashView()
        case .signedOut:
            Auth()
        case .onboarding:
            OnboardingFlow()
        case .ready:
            AppTab()
        }
    }
}
