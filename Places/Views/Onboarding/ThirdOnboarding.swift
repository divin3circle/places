//
//  ThirdOnboarding.swift
//  Places
//
//  Created by Sylus Abel on 28/07/2026.
//

import SwiftUI
import SwiftfulRouting

struct ThirdOnboarding: View {
    @Environment(\.router) var router
    
    var body: some View {
            let config: NotificationOnboardingConfig = NotificationOnboardingConfig(
                title: "Stay in the loop with\nPush Notifications",
                content: "Get trip reminders and a heads-up when your AI itinerary is ready.",
                notificationTitle: "Your trip to the Savanna",
                notificationContent: "Your itinerary is ready — time to start planning!",
                primaryButtonTitle: "Continue",
                secondaryButtonTitle: "Ask me Later"
            )
        VStack(spacing: 0){

            NotifiationsOnboarding(config: config) {
                Image("places-icon")
                    .resizable()
                    .font(.title2)
                    .frame(width: 40, height: 40)
                    .clipShape(.rect(cornerRadius: 12))
            } onPersmissionChange: { isApproved in
            } onPrimaryButtonTap: {
                navigateToFinalOnboardingScreen()
            } onSecondaryButtonTap: {
               navigateToFinalOnboardingScreen()
            } onFinish: {
            }

        }
        .toolbar(.hidden, for: .navigationBar)
    }
    
    private func navigateToFinalOnboardingScreen() {
        router.showScreen(.push) { _ in
            FourthOnboarding()
        }
    }
}

#Preview {
    ThirdOnboarding()
}
