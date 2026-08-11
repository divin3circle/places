//
//  FirstOnboarding.swift
//  Places
//
//  Created by Sylus Abel on 27/07/2026.
//

import SwiftUI
import SwiftfulRouting

struct FirstOnboarding: View {
    @Environment(\.router) var router
    var action: () -> Void
    @State private var currentStep: Int = 0
    
    var body: some View {
        VStack{
            ProgressViewer(steps: 4, currentStep: $currentStep)
            LottieAnimationLoader(fileName: "feature-animation1", loop: true, loopCount: 2, autoPlay: true)
                .frame(maxWidth: .infinity)
                .frame(height: 350)
                .microAnimations(delay: 0.1, slideDirection: .Top, offsetAmount: 0)
            
            VStack(spacing: 16) {
                ForEach(Features.list, id: \.id) { feature in
                    FeatureItem(
                        feature: feature
                    )
                    .microAnimations(
                        delay: 0.4 + Double(
                            Int(feature.id) ?? 0
                        ) * 0.3,
                        slideDirection: .Bottom,
                        offsetAmount: 0
                    )
                }
            }
            Spacer()
            PrimaryButton(title: "Continue", kind: .appPrimary, action: action)
                .microAnimations(delay: 1.5, slideDirection: .Bottom, offsetAmount: 0)
                .padding(.top)
            Spacer()
        }
        .padding(.horizontal, 30)
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview {
    RouterView { _ in
        FirstOnboarding {
          //
        }
    }
}
