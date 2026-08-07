//
//  CuratedTripCard.swift
//  Places
//
//  Created by Sylus Abel on 03/08/2026.
//

import SwiftUI

/// An image card with a duration badge and title — the "Places worth slowing
/// down for" carousel item.
struct CuratedTripCard: View {
    let trip: CuratedTrip

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            DownsampledAssetImage(name: trip.imageName, width: 200, height: 150)
                .frame(width: 200, height: 150)
                .clipped()
                .clipShape(.rect(cornerRadius: 18))
                .overlay(alignment: .topTrailing) {
                    Label(trip.durationLabel, systemImage: "clock")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: .capsule)
                        .environment(\.colorScheme, .dark)
                        .padding(10)
                }

            Text(trip.title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
        }
        .frame(width: 200)
    }
}

#Preview {
    CuratedTripCard(trip: .samples[0])
}
