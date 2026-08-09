//
//  RecommendationCard.swift
//  Places
//
//  Created by Sylus Abel on 03/08/2026.
//

import SwiftUI

/// A destination shown as a fanned stack of photos with a name label — the
/// "Recommendations" carousel item. `images` may be remote URLs or asset names;
/// `RemoteImage` handles both.
struct RecommendationCard: View {
    let name: String
    let images: [String]

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                ForEach(Array(images.prefix(3).enumerated()), id: \.offset) { index, source in
                    let position = index - 1 // -1, 0, 1 → left, center, right
                    RemoteImage(source, width: 72, height: 94)
                        .frame(width: 72, height: 94)
                        .clipShape(.rect(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.background, lineWidth: 2))
                        .shadow(color: .black.opacity(0.15), radius: 3, y: 2)
                        .rotationEffect(.degrees(Double(position) * 9))
                        .offset(x: CGFloat(position) * 14)
                        .zIndex(position == 0 ? 1 : 0)
                }
            }
            .frame(width: 110, height: 104)

            Text(name)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
        }
        .frame(width: 110)
    }
}

#Preview {
    RecommendationCard(name: "Maasai Mara", images: ["onboarding1", "sample", "onboarding3"])
}
