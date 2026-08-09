//
//  SponsoredCardView.swift
//  Places
//
//  Created by Sylus Abel on 05/08/2026.
//

import SwiftUI

struct SponsoredCardView: View {
    @Environment(SponsoredViewModel.self) var model
    var card: Sponsored
    var animation: Namespace.ID

    var body: some View {
        content
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            // The photo lives in the BACKGROUND so it sizes to the card's frame and
            // never drives layout — matching it (not the layout container) is what
            // keeps the hero morph from stretching the card to full width.
            .background {
                ZStack {
                    card.accentColor
                    RemoteImage(card.image, width: 300, height: 400)
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.15), .black.opacity(0.75)],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                }
                .matchedGeometryEffect(id: "bg-\(card.id)", in: animation)
            }
            .clipShape(RoundedRectangle(cornerRadius: 25))
            .contentShape(RoundedRectangle(cornerRadius: 25))
            .onTapGesture {
                withAnimation(.spring()) {
                    model.selectedCard = card
                    model.showCard.toggle()
                }
            }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Text(card.category.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.5)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial, in: .capsule)

                Spacer(minLength: 0)

                Text("Sponsored")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial, in: .capsule)
            }

            Spacer(minLength: 0)

            Text(card.title)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(card.subtitle)
                .font(.subheadline)
                .fontDesign(.rounded)
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(2)
                .padding(.top, 2)

            HStack(spacing: 4) {
                Text("See More")
                Image(systemName: "chevron.right")
            }
            .font(.footnote.weight(.semibold))
            .fontDesign(.rounded)
            .foregroundStyle(.white.opacity(0.9))
            .padding(.top, 12)
        }
    }
}

#Preview {
    @Previewable @Namespace var ns
    SponsoredCarousel(animation: ns)
        .environment(SponsoredViewModel())
}
