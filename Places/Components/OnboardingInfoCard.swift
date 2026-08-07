//
//  OnboardingInfoCard.swift
//  Places
//
//  Created by Sylus Abel on 27/07/2026.
//

import SwiftUI

struct OnboardingInfoCard: View {
    var title: String = "Safari Onboarding"
    var subtitle: String = "The place to be this summer"
    var imageName: String = "onboarding1"
    var imageHeight: CGFloat = 500
    var imageCornerRadius: CGFloat = 28
    var horizontalPadding: CGFloat = 20
    @Binding var selectedPage: Int
    var index: Int

    @State private var showText = false

    var body: some View {
        ImageLoader(
            isOnlineImage: false,
            localImageName: imageName,
            localImageExtension: "jpg",
            onlineImageUrl: nil,
            resizeMode: .fill
        )
        .frame(maxWidth: .infinity)
        .frame(height: imageHeight)
        .clipped()
        .overlay(alignment: .bottomLeading) {
            ZStack(alignment: .bottomLeading) {
                Rectangle()
                    .fill(.regularMaterial)
                    .mask(
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.35), .black],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                LinearGradient(
                    colors: [.clear, .black.opacity(0.82)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 10) {
                    Text(title)
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .fontWidth(.expanded)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)

                    Text(subtitle)
                        .font(.system(.callout, design: .rounded, weight: .medium))
                        .lineLimit(2)
                }
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 2)
                .padding(22)
                .opacity(showText ? 1 : 0)
                .offset(y: showText ? 0 : 20)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 210)
        }
        .clipShape(RoundedRectangle(cornerRadius: imageCornerRadius, style: .continuous))
        .padding(.horizontal, horizontalPadding)
        .onChange(of: selectedPage) { _, newValue in
            if newValue == index {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.85).delay(0.08)) {
                    showText = true
                }
            } else {
                showText = false
            }
        }
        .onAppear {
            if selectedPage == index {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.85).delay(0.15)) {
                    showText = true
                }
            }
        }
    }
}

#Preview {
    OnboardingInfoCard(
        selectedPage: .constant(0),
        index: 0
    )
}
