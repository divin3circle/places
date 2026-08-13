//
//  ProBadge.swift
//  Places
//
//  Animated Pro/Lifetime flair (Discord-style), rendered from the staged Lottie
//  files via the existing LottieAnimationLoader. Gate with `PurchasesManager.isPro`
//  and `profile.planProduct == "piea_pro_lifetime"`.
//

import SwiftUI

/// Small animated badge shown next to a Pro member's name.
struct ProBadgeView: View {
    var size: CGFloat = 26
    var body: some View {
        LottieAnimationLoader(fileName: "pro-badge", loop: true, autoPlay: true)
            .frame(width: size, height: size)
            .allowsHitTesting(false)
    }
}

/// Ornate gold frame that wraps a Lifetime member's avatar. Size it slightly
/// larger than the avatar so it surrounds the circle.
struct LifetimeFrameView: View {
    var size: CGFloat = 132
    var body: some View {
        LottieAnimationLoader(fileName: "lifetime-frame", loop: true, autoPlay: true)
            .frame(width: size, height: size)
            .allowsHitTesting(false)
    }
}
