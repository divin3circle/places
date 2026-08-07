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
                title: "Stay connected with\nPush Notifications",
                content: "We will send you push notifications to keep you updated once a friend joins your travel group or send a message.",
                notificationTitle: "Hello jLynne",
                notificationContent: "You trip to the savanna just received 2 more travel buddies, time to plan.",
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
