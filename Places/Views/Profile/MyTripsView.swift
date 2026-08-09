//
//  MyTripsView.swift
//  Places
//
//  Created by Sylus Abel on 03/08/2026.
//

import SwiftUI
import SwiftData

/// Instagram-style grid of the user's saved trips, with an empty state until
/// they convert their first itinerary.
/// Pushed from the profile settings via SwiftfulRouting.
struct MyTripsView: View {
    @Query(sort: \SavedTrip.createdAt, order: .reverse) private var savedTrips: [SavedTrip]
    private var trips: [Trip] { savedTrips.map(\.displayTrip) }

    private let columns = [
        GridItem(.flexible(), spacing: 3),
        GridItem(.flexible(), spacing: 3),
        GridItem(.flexible(), spacing: 3)
    ]

    var body: some View {
        ScrollView(.vertical) {
            if trips.isEmpty {
                ContentEmptyState(icon: "suitcase", message: "Your saved trips will appear here.\nPlan one to get started.")
                    .padding(.top, 80)
            } else {
                LazyVGrid(columns: columns, spacing: 3) {
                    ForEach(trips) { trip in
                        TripCell(trip: trip)
                    }
                }
                .padding(.horizontal, 3)
            }
        }
        .scrollIndicators(.hidden)
        .navigationTitle("My Trips")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func TripCell(trip: Trip) -> some View {
        // TODO: push a trip-detail screen when one exists.
        Image(trip.coverImageName)
            .resizable()
            .aspectRatio(1, contentMode: .fill)
            .frame(maxWidth: .infinity)
            .clipped()
            .clipShape(.rect(cornerRadius: 6))
            .overlay(alignment: .bottomLeading) {
                LinearGradient(
                    colors: [.black.opacity(0.55), .clear],
                    startPoint: .bottom,
                    endPoint: .center
                )
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(trip.title)
                            .font(.system(size: 13, weight: .semibold))
                            .fontDesign(.rounded)
                        Text(trip.dateLabel)
                            .font(.system(size: 11))
                            .fontDesign(.rounded)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    .foregroundStyle(.white)
                    .padding(8)
                }
                .clipShape(.rect(cornerRadius: 6))
            }
    }
}

#Preview {
    NavigationStack {
        MyTripsView()
    }
}
