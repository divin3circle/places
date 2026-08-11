//
//  FourthOnboarding.swift
//  Places
//
//  Created by Sylus Abel on 29/07/2026.
//

import SwiftUI
import SwiftfulRouting

struct FourthOnboarding: View {
    @Environment(\.router) private var router
    @Environment(SessionStore.self) private var session: SessionStore?
    @State private var currentStep: Int = 3
    @State private var isFinishing = false
    @State private var toast: ToastData?
    var body: some View {
        VStack(spacing: 0) {
            ProgressViewer(steps: 4, currentStep: $currentStep)
                .microAnimations(delay: 0.09, slideDirection: .Top, offsetAmount: 0)
            Spacer(minLength: 0)
            LottieAnimationLoader(fileName: "travel", loop: true, loopCount: 2, autoPlay: true)
                .frame(maxWidth: .infinity)
                .frame(height: 350)
                .microAnimations(delay: 0.1, slideDirection: .Left, offsetAmount: 0)
            Spacer(minLength: 0)
            Text("Places Quick Tour")
                .font(.largeTitle.bold())
                .fontDesign(.rounded)
                .fontWidth(.expanded)
                .lineLimit(2)
                .microAnimations(delay: 0.3, slideDirection: .Bottom, offsetAmount: 0)
            Text("Discover how easily Places helps you design your dream safari across the East African savanna.")
                .font(.callout)
                .fontWeight(.medium)
                .fontDesign(.rounded)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
                .microAnimations(delay: 0.4, slideDirection: .Bottom, offsetAmount: 0)
                .padding(.vertical)
            
            PrimaryButton(title: "Start Tour", kind: .appPrimary, action: navigateToHome)
                .microAnimations(delay: 0.5, slideDirection: .Bottom, offsetAmount: 0)
                .padding(.top)
            Button {
                navigateToHome()
            } label: {
                Text("Ask me Later")
                    .fontDesign(.rounded)
                    .fontWeight(.medium)
                    .foregroundStyle(.gray)
            }
            .frame(height: 55)
            .microAnimations(delay: 0.7, slideDirection: .Bottom, offsetAmount: 0)
            
        }
        .padding(.horizontal)
        .toolbar(.hidden, for: .navigationBar)
        .disabled(isFinishing)
        .toast($toast)
    }

    private func navigateToHome() {
        guard !isFinishing else { return }
        isFinishing = true
        Task {
            do {
                // Marks the profile onboarded (phase → .ready, AppTab becomes root),
                // then pops the onboarding stack to reveal it. Only advances on success.
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
    FourthOnboarding()
}
