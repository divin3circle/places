//
//  CreateTripSheet.swift
//  Places
//
//  The "Plan a New Trip" upsell sheet: the orbiting-icons animation over the
//  pitch + the primary "Start planning" CTA. Reused by the tab-bar + button and
//  by "Plan this trip" on an experience/destination detail, so the UI is
//  identical everywhere (previously the copy/buttons lived inline in AppTab, so
//  other call sites showed only the bare animation).
//

import SwiftUI

struct CreateTripSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let symbols = [
        "figure.walk.suitcase.rolling",
        "airplane.departure",
        "map",
        "sparkle.text.clipboard.fill",
    ]

    var body: some View {
        VStack(spacing: 14) {
            CreateTripView(symbols: symbols, symbolFont: .title, tint: .primary)
                .frame(height: 220)

            VStack(spacing: 8) {
                Text("Plan a New Trip")
                    .font(.title2.bold())
                    .fontDesign(.rounded)

                Text("Let the AI concierge build a personalized itinerary for your next adventure 🌎")
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 8)

            Spacer(minLength: 8)

            VStack(spacing: 10) {
                Text("14 days free, then $0.99 / month")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.secondary)

                // Starting a paid AI itinerary is a pay + generate action → accent.
                Button {
                    // TODO: begin the itinerary flow.
                } label: {
                    Text("Start planning")
                }
                .buttonStyle(.appAccent)

                Button { dismiss() } label: {
                    Text("Maybe later")
                }
                .buttonStyle(.appOutline)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(.systemBackground))
        .presentationDetents([.height(560)])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color(.systemBackground))
    }
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            CreateTripSheet()
        }
}
