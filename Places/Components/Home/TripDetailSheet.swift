//
//  TripDetailSheet.swift
//  Places
//
//

import SwiftUI

struct TripDetailSheet: View {
    let trip: Trip
    var onView: () -> Void
    var onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            DownsampledAssetImage(name: trip.coverImageName, width: 360, height: 180)
                .frame(height: 180)
                .frame(maxWidth: .infinity)
                .clipShape(.rect(cornerRadius: 20, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(trip.title)
                    .font(.title2.bold())
                    .fontDesign(.rounded)
                if !trip.subtitle.isEmpty {
                    Text(trip.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Label(trip.dateLabel, systemImage: "calendar")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }

            Spacer(minLength: 0)

            HStack(spacing: 10) {
                Button(action: onEdit) {
                    Label("Edit", systemImage: "sparkles")
                }
                .buttonStyle(.appOutline)

                Button(action: onView) {
                    Label("View Trip", systemImage: "arrow.up.right")
                }
                .buttonStyle(.appPrimary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(.systemBackground))
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color(.systemBackground))
    }
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            TripDetailSheet(trip: Trip.previews[0], onView: {}, onEdit: {})
        }
}
