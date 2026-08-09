//
//  OnboardingFlow.swift
//  Places
//
//  Root of the onboarding phase. Shows the feature intro, then pushes the
//  interests → notifications → tour chain via the router (unchanged views).
//

import SwiftUI
import SwiftfulRouting

struct OnboardingFlow: View {
    @Environment(\.router) private var router

    var body: some View {
        FirstOnboarding {
            router.showScreen(.push) { _ in SecondOnboarding() }
        }
    }
}
