//
//  AppTourOnboarding.swift
//  Places
//
//  Created by Sylus Abel on 14/08/2026.
//

import SwiftUI
import SwiftfulRouting

struct AppTourOnboarding: View {
    @Environment(\.router) var router
    @Environment(SessionStore.self) private var session: SessionStore?

    @State private var isFinishing = false
    @State private var toast: ToastData?

    var body: some View {
        AppTour(items:  [
            .init(
                id: 0,
                title: "Welcome to Places",
                subtitle: "Plan unforgettable trips in seconds",
                screenshot: UIImage(
                    named:"onboarding-features"
                )
            ),
            .init(
                id: 1,
                title: "Tailor Experiences",
                subtitle: "Dictate how Places generated itineraries",
                screenshot: UIImage(
                    named: "onboarding-interests"
                )
            ),
            .init(
                id: 2,
                title: "Focused Trip",
                subtitle: "Genrate from real places with real prices",
                screenshot: UIImage(
                    named: "masaai-mara"
                ),
                zoomScale: 1.3,
                zoomAnchor: .bottom
            ),
            .init(
                id: 3,
                title: "Explore the Region",
                subtitle: "Experiences, Destinations, Amenities all in on place",
                screenshot: UIImage(
                    named: "explore-screen"
                ),
                zoomScale: 1.2,
                zoomAnchor: .init(
                    x: 0.5,
                    y: -0.1
                )
            ),
            .init(
                id: 4,
                title: "Plan More",
                subtitle: "Get Places pro to unlock boundaries and limits",
                screenshot: UIImage(
                    named: "paywall"
                )
            ),
        ], back: goBack, onComplete: finishTour)
        .toolbar(.hidden, for: .navigationBar)
        .disabled(isFinishing)
        .toast($toast)
    }


    private func goBack() {
        guard !isFinishing else { return }
        router.dismissScreen()
    }

    /// Mirrors FourthOnboarding.navigateToHome(): mark the profile onboarded
    /// (phase → .ready, AppTab becomes root) and only then pop the stack to reveal it.
    private func finishTour() {
        guard !isFinishing else { return }
        isFinishing = true
        Task {
            do {
                try await session?.completeOnboarding()
                router.dismissAllScreens()
            } catch {
                isFinishing = false
                toast = ToastData(message: "Couldn't finish setup. Please try again.", isError: true)
            }
        }
    }
}

#Preview {
    AppTourOnboarding()
}
