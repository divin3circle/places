//
//  ExploreHero.swift
//  Places
//
//  Created by Sylus Abel on 03/08/2026.
//

import SwiftUI

/// The Explore hero: a full-bleed destination image that runs edge-to-edge and
/// up under the status bar, with a scrim, a blurred status-bar strip to keep the
/// clock/battery legible, the headline, and the embedded search bar.
struct ExploreHero: View {
    @Binding var searchText: String
    /// Top safe-area inset, passed down so the image can extend under the status
    /// bar while the headline and blur stay aligned to it.
    var topInset: CGFloat = 0

    var body: some View {
        heroImage
            .frame(height: 400 + topInset)
            .frame(maxWidth: .infinity)
            .clipped()
            .overlay { scrim }
            .overlay(alignment: .top) { statusBarBlur }
            .overlay(alignment: .topLeading) { headline }
            .overlay(alignment: .bottom) {
                ExploreSearchBar(text: $searchText)
                    .padding(16)
            }
    }

    private var heroImage: some View {
        DownsampledAssetImage(
            name: "onboarding2",
            width: UIScreen.main.bounds.width,
            height: 400 + topInset,
            contentMode: .fill
        )
    }

    private var scrim: some View {
        LinearGradient(
            colors: [.black.opacity(0.15), .black.opacity(0.1), .black.opacity(0.65)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Blurred strip over the status bar so the clock/battery stay legible.
    private var statusBarBlur: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .frame(height: topInset + 8)
            .mask(
                LinearGradient(
                    colors: [.black, .black, .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .allowsHitTesting(false)
    }

    private var headline: some View {
        Text("Find your next\natmosphere.")
            .font(.system(size: 36, weight: .bold, design: .rounded))
            .fontWidth(.expanded)
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.25), radius: 8, y: 2)
            .padding(20)
            .padding(.top, topInset)
    }
}

#Preview {
    ExploreHero(searchText: .constant(""))
}
