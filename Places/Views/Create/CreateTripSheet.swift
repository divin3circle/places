//
//  CreateTripSheet.swift
//  Places
//
//  The "Plan a New Trip" flow. Two phases in one sheet:
//  1. Pitch — the orbiting-icons animation + the paid "Start planning" CTA.
//  2. Form — a step wizard (CreateTripForm) collecting the trip-generation config.
//  Reused by the tab-bar + button and by "Plan this trip" on a detail screen.
//

import SwiftUI

struct CreateTripSheet: View {
    /// Called with the collected config when the wizard finishes; the presenter
    /// dismisses this sheet and routes on to `GenerateItineraryView`.
    var onGenerate: (TripConfig) -> Void = { _ in }

    @Environment(\.dismiss) private var dismiss
    @State private var config = TripConfigViewModel()
    @State private var isPlanning = false
    @State private var detent: PresentationDetent = .height(360)

    private let symbols = [
        "figure.walk.suitcase.rolling",
        "airplane.departure",
        "map",
        "sparkle.text.clipboard.fill",
    ]

    var body: some View {
        Group {
            if isPlanning {
                CreateTripForm(
                    vm: config,
                    onBackToPitch: {
                        withAnimation(.snappy) {
                            isPlanning = false
                            detent = .height(360)
                        }
                    },
                    onFinish: {
                        onGenerate(config.snapshot())
                    }
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                pitch
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(.systemBackground))
        // Pitch is a compact sheet; once planning starts we lock to full height
        // (no minimize) so the wizard isn't cramped.
        .presentationDetents(isPlanning ? [.large] : [.height(360)], selection: $detent)
        .presentationDragIndicator(isPlanning ? .hidden : .visible)
        .presentationBackground(Color(.systemBackground))
    }

    private var pitch: some View {
        VStack(spacing: 14) {
            CreateTripView(symbols: symbols, symbolFont: .title, tint: .primary)
                .frame(height: 220)

            VStack(spacing: 8) {
                Text("Plan a New Trip")
                    .font(.title2.bold())
                    .fontDesign(.rounded)

                Text("Let the AI concierge build your next adventure 🌎")
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 8)
            .padding(.bottom)

            VStack(spacing: 10) {
                Text("14 days free, then $0.99 / month")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.secondary)

                // Starting a paid AI itinerary is a pay + generate action → accent.
                Button {
                    withAnimation(.snappy) {
                        isPlanning = true
                        detent = .large
                    }
                } label: {
                    Text("Start planning")
                }
                .buttonStyle(.appAccent)
            }
        }
        .padding(20)
    }
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            CreateTripSheet()
        }
}
