//
// PopularCarousel.swift
// Places
//
// Created by Sylus Abel on 04/08/2026
//

import SwiftUI

struct PopularCarousel: View {
  /// Card size in the row. The focused card is wide enough that only ONE waiting
  /// card peeks beside it as a `collapsedWidth` capsule; the rest are reachable by
  /// scrolling. `shrinkAmount` and `cardStride` are derived so the capsule stays
  /// the same width regardless of `cardWidth`.
  private let cardWidth: CGFloat = 265
  private let cardHeight: CGFloat = 200

  /// Width a waiting card collapses to (the single peeking capsule).
  private let collapsedWidth: CGFloat = 50
  /// How much a card grows/shrinks between focused and collapsed states.
  private var shrinkAmount: CGFloat { cardWidth - collapsedWidth }
  /// Per-card scroll stride: card width + `HStack` spacing.
  private var cardStride: CGFloat { cardWidth + 10 }

  @State private var popularDestinations: [PopularDestination] = [
    .init(image: "onboarding1", name: "Maasai Mara", rating: 4.9, bestTimeToVisit: "Jul – Oct", category: "Safari"),
    .init(image: "onboarding2", name: "Serengeti", rating: 4.8, bestTimeToVisit: "Jun – Sep", category: "Wildlife"),
    .init(image: "onboarding3", name: "Zanzibar", rating: 4.7, bestTimeToVisit: "Jun – Oct", category: "Beach"),
    .init(image: "onboarding4", name: "Kilimanjaro", rating: 4.9, bestTimeToVisit: "Jan – Mar", category: "Trek"),
    .init(image: "onboarding5", name: "Diani Beach", rating: 4.6, bestTimeToVisit: "Dec – Mar", category: "Beach"),
  ]
  var body: some View {
    VStack {
      GeometryReader {
        let size = $0.size

        ScrollView(.horizontal) {
          HStack(spacing: 10) {
            ForEach(popularDestinations) { destination in
              cardView(destination)
            }
          }
          .padding(.trailing, size.width - cardWidth)
          .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollIndicators(.hidden)
        .clipShape(.rect(cornerRadius: 25))
      }
      .padding(.horizontal, 15)
      .frame(height: 210)

      Spacer(minLength: 0)
    }
  }

  @ViewBuilder
  func cardView(_ card: PopularDestination) -> some View {
    GeometryReader { proxy in
      let size = proxy.size
      let minX = proxy.frame(in: .scrollView).minX
      let reducingWidth = (minX / cardStride) * shrinkAmount
      let cappedWidth = min(reducingWidth, shrinkAmount)

      let frameWidth = size.width - (minX > 0 ? cappedWidth : -cappedWidth)

      // 1 while the card is the focused / full-width one, fading to 0 as it
      // collapses into the capsule — so text only shows on the expanded card.
      let collapseAmount = min(abs(cappedWidth), shrinkAmount)
      let expandProgress = max(0, min(1, 1 - collapseAmount / 45))

      ZStack(alignment: .bottomLeading) {
        DownsampledAssetImage(name: card.image, width: cardWidth + 130, height: cardHeight)
          .frame(width: size.width, height: size.height)

        destinationOverlay(card, size: size)
          .opacity(expandProgress)
      }
      .frame(width: size.width, height: size.height)
      .frame(width: frameWidth)
      .clipShape(.rect(cornerRadius: 25))
      .offset(x: minX > 0 ? 0 : -cappedWidth)
      .offset(x: -card.previousOffset)
    }
    .frame(width: cardWidth, height: cardHeight)
    .offset { offset in
      let reducingWidth = (offset / cardStride) * shrinkAmount
      let index = popularDestinations.indexOf(card)

      if popularDestinations.indices.contains(index + 1) {
        popularDestinations[index + 1].previousOffset = (offset < 0 ? 0 : reducingWidth)
      }

    }
  }

  /// Content shown only while a card is expanded. Sized to the full `cardWidth`
  /// so the text never reflows as the card windows down to the capsule.
  @ViewBuilder
  func destinationOverlay(_ card: PopularDestination, size: CGSize) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .top) {
        Text(card.category.uppercased())
          .font(.system(size: 9, weight: .semibold))
          .tracking(0.5)
          .foregroundStyle(.white)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(.ultraThinMaterial, in: .capsule)

        Spacer(minLength: 0)

        HStack(spacing: 3) {
          Image(systemName: "star.fill")
            .font(.system(size: 9))
            .foregroundStyle(.yellow)
          Text(card.rating.formatted())
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial, in: .capsule)
      }

      Spacer(minLength: 0)

      Text(card.name)
        .font(.system(size: 22, weight: .bold, design: .rounded))
        .foregroundStyle(.white)
        .lineLimit(1)
        .minimumScaleFactor(0.7)

      HStack(spacing: 5) {
        Image(systemName: "calendar")
          .font(.system(size: 10, weight: .semibold))
        Text("Best \(card.bestTimeToVisit)")
          .font(.system(size: 12, weight: .medium))
      }
      .foregroundStyle(.white.opacity(0.9))
      .padding(.top, 2)
    }
    .padding(14)
    .frame(width: size.width, height: size.height, alignment: .leading)
    .background(
      LinearGradient(
        colors: [.clear, .black.opacity(0.15), .black.opacity(0.75)],
        startPoint: .center,
        endPoint: .bottom
      )
    )
  }
}
