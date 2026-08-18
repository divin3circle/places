//
//  SponsoredDetails.swift
//  Places
//
//  Created by Sylus Abel on 05/08/2026.
//

import SwiftUI

struct SponsoredDetails: View {
    @Environment(SponsoredViewModel.self) var model
    var animation: Namespace.ID

    private var card: Sponsored { model.selectedCard }

    var body: some View {
        // `Color.clear` respects the safe area, so the top bar and bottom panel
        // pin deterministically to the safe-area edges. The photo lives in the
        // BACKGROUND (safe-area-ignoring, full screen) and taps on it dismiss.
        Color.clear
            .contentShape(.rect)
            .onTapGesture { dismiss() }
            .background {
                ZStack {
                    card.accentColor

                    RemoteImage(card.image, width: 440, height: 950)

                    // Legibility scrims: light at the top for the badge/close, heavy
                    // at the bottom for the glass card.
                    LinearGradient(
                        colors: [.black.opacity(0.45), .clear, .clear, .black.opacity(0.55)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .matchedGeometryEffect(id: "bg-\(card.id)", in: animation)
                .ignoresSafeArea()
            }
            .overlay(alignment: .top) {
                topBar
                    .padding(20)
            }
            .overlay(alignment: .bottom) {
                bottomPanel
                    .padding(20)
            }
    }

    private var topBar: some View {
        HStack(alignment: .top) {
            Text(card.category.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.5)
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.ultraThinMaterial, in: .capsule)

            Spacer(minLength: 0)

            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(.ultraThinMaterial, in: .circle)
            }
        }
    }

    private var bottomPanel: some View {
        VStack(spacing: 0) {
            infoCard

            chips
                .padding(.top, 12)
        }
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(card.title)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text("\(card.category) · \(card.location)")
                .font(.footnote.weight(.medium))

            Text(card.subtitle)
                .font(.subheadline)
                .fontDesign(.rounded)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.thinMaterial, in: .rect(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.18), lineWidth: 1)
        )
    }

    private var chips: some View {
        HStack(spacing: 10) {
            Label(card.location, systemImage: "mappin.and.ellipse")
            Label(card.category, systemImage: "tag")
        }
        .font(.caption.weight(.semibold))
        .fontDesign(.rounded)
        .foregroundStyle(.white)
        .lineLimit(1)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: .capsule)
    }

    private func dismiss() {
        withAnimation(.spring()) {
            model.showCard.toggle()
        }
    }
}

#Preview {
    @Previewable @Namespace var ns
    SponsoredCarousel(animation: ns)
        .environment(SponsoredViewModel())
}
