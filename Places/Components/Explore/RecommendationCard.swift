//
//  RecommendationCard.swift
//  Places
//
//  Created by Sylus Abel on 03/08/2026.
//

import SwiftUI

/// A destination shown as a fanned stack of photos with a name label — the
/// "Recommendations" carousel item.
struct RecommendationCard: View {
    let destination: RecommendedDestination

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                ForEach(Array(destination.imageNames.prefix(3).enumerated()), id: \.offset) { index, name in
                    let position = index - 1 // -1, 0, 1 → left, center, right
                    DownsampledAssetImage(name: name, width: 72, height: 94)
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

            Text(destination.name)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
        }
        .frame(width: 110)
    }
}

#Preview {
    RecommendationCard(destination: .samples[0])
}
