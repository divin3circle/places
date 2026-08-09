//
//  UpcomingTripCard.swift
//  Places
//
//  Created by Sylus Abel on 03/08/2026.
//

import SwiftUI

/// The prominent "Upcoming" trip card: cover + title/subtitle, quick facts, and
/// a "Trip detail" action.
struct UpcomingTripCard: View {
    let trip: UpcomingTrip
    var onDetail: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                DownsampledAssetImage(name: trip.coverImageName, width: 76, height: 76)
                    .frame(width: 76, height: 76)
                    .clipShape(.rect(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 4) {
                    Text(trip.title)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                    Text(trip.subtitle)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)
            }

            HStack {
                HStack(spacing: 14) {
                    Label("\(trip.days) Days", systemImage: "clock")
                    Label("\(trip.placesCount) Places", systemImage: "mappin.and.ellipse")
                }
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)

                Spacer(minLength: 0)

                Button(action: onDetail) {
                    HStack(spacing: 4) {
                        Text("Trip detail")
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color(.systemGray5), in: .capsule)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 22))
    }
}

#Preview {
    UpcomingTripCard(
        trip: UpcomingTrip(id: UUID(), title: "Maasai Mara Safari",
                           subtitle: "Golden plains and Big Five mornings.",
                           coverImageName: "onboarding2", days: 8, placesCount: 12),
        onDetail: {}
    )
    .padding()
}
