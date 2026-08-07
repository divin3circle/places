//
//  Onboarding.swift
//  Places
//
//  Created by Sylus Abel on 27/07/2026.
//

import SwiftUI
import SwiftfulRouting

struct Auth: View {
    @Environment(\.router) var router
    
    @State private var selectedPage = 0
    @State private var showPanel = false
    @State private var showButton = false
    
    private let pages = [
        OnboardingPage(
            title: "Find Wild Places",
            subtitle: "Discover memorable stays, trails, and local experiences wherever you go.",
            imageName: "onboarding1"
        ),
        OnboardingPage(
            title: "Plan The Escape",
            subtitle: "Save ideas, compare places, and shape trips around the moments you want.",
            imageName: "onboarding2"
        ),
        OnboardingPage(
            title: "Travel With Context",
            subtitle: "Keep the best details close, from arrival notes to hidden spots nearby.",
            imageName: "onboarding3"
        ),
        OnboardingPage(
            title: "Travel With Context",
            subtitle: "Keep the best details close, from arrival notes to hidden spots nearby.",
            imageName: "onboarding6"
        ),

    ]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 2) {
                TabView(selection: $selectedPage) {

                    ForEach(pages.indices, id: \.self) { index in
                        OnboardingInfoCard(
                            title: pages[index].title,
                            subtitle: pages[index].subtitle,
                            imageName: pages[index].imageName,
                            imageHeight: 450,
                            imageCornerRadius: 30,
                            horizontalPadding: 0,
                            selectedPage: $selectedPage,
                            index: index
                        )
                        .tag(index)
                        .padding()
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))


                Spacer(minLength: 260)
            }
            
            authPanel
                .offset(y: showPanel ? 0 : 500)
                .opacity(showPanel ? 1 : 0)
                .padding(.horizontal)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                    showPanel = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    showButton = true
                }
            }
        }
    }
    
    private var authPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            Capsule()
                .fill(Color.secondary.opacity(0.35))
                .frame(width: 42, height: 5)
                .frame(maxWidth: .infinity)
                .accessibilityHidden(true)

            if pages.count > 1 {
                HStack(spacing: 6) {
                    ForEach(pages.indices, id: \.self) { index in
                        Capsule()
                            .fill(selectedPage == index ? Color.accent : Color.secondary.opacity(0.25))
                            .frame(width: selectedPage == index ? 22 : 6, height: 6)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: selectedPage)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 4)
            }

            VStack(alignment: .leading, spacing: 6) {
                
                Text("Welcome to Places")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .fontWidth(.expanded)
                Text("An AI supercharged travel companion for planning, sharing, and exploring unforgettable.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            VStack(spacing: 10) {
                authButton(title: "Continue with Apple", symbol: "apple.logo", style: .primary)
                    .scaleEffect(showButton ? 1 : 0.85)
                    .opacity(showButton ? 1 : 0)
            }
            
            Text("By continuing, you agree to the Terms and Privacy Policy.")
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 22)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .shadow(color: .black.opacity(0.18), radius: 26, x: 0, y: -8)
    }
    
    private func authButton(title: String, symbol: String, style: AuthButtonStyle) -> some View {
        Button {
            router.showScreen(.push) { router in
                FirstOnboarding {
                    router.showScreen(.push) { _ in
                        SecondOnboarding()
                    }
                }
            }
        } label: {
            HStack(spacing: 10) {
                Spacer(minLength: 0)
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 24)
                Text(title)
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                Spacer(minLength: 0)
            }
            .foregroundStyle(style.foregroundColor)
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(style.backgroundColor)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

private struct OnboardingPage {
    let title: String
    let subtitle: String
    let imageName: String
}

private enum AuthButtonStyle {
    case primary
    case secondary
    
    var backgroundColor: Color {
        switch self {
        case .primary:
            return .accent
        case .secondary:
            return Color(.secondarySystemBackground)
        }
    }
    
    var foregroundColor: Color {
        switch self {
        case .primary:
            return Color(.white)
        case .secondary:
            return .primary
        }
    }
}

#Preview {
    RouterView{ _ in
        Auth()
    }
}
