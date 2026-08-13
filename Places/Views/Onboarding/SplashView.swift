//
//  SplashView.swift
//  Places
//
//  Shown while the session is being restored at launch (phase == .booting).
//  A looping Lottie + a rotating travel fact so the wait feels intentional
//  rather than a frozen logo. (Placeholder animation until the elephant/lion
//  asset lands — swap `splashAnimation` below.)
//

import SwiftUI

struct SplashView: View {
    /// Temporary Lottie until the branded elephant/lion is supplied.
    private let splashAnimation = "birds"

    private let facts = [
        "The Great Migration sends over 1.5 million wildebeest across the Mara each year.",
        "On a clear day, Kilimanjaro rises over Kenya's Amboseli plains.",
        "Kenya has 60+ national parks and reserves — from Tsavo to Samburu.",
        "Lamu Old Town is one of the oldest living Swahili settlements — 700+ years.",
        "Lake Nakuru has turned pink with over a million flamingos.",
    ]

    @State private var factIndex = 0

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                LottieAnimationLoader(fileName: splashAnimation, loop: true, autoPlay: true)
                    .frame(width: 220, height: 220)

                Text("Places")
                    .font(.system(.title, design: .rounded).weight(.bold))

                Spacer()

                Text(facts[factIndex])
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .id(factIndex)
                    .transition(.opacity)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 18, style: .continuous))
                    .padding(.horizontal, 32)
                    .padding(.bottom, 24)
            }
        }
        .task {
            factIndex = Int.random(in: 0..<facts.count)
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(3.2))
                withAnimation(.easeInOut(duration: 0.45)) {
                    factIndex = (factIndex + 1) % facts.count
                }
            }
        }
    }
}

#Preview {
    SplashView()
}
