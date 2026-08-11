//
// MyTripsStack.swift
// Places
//
// Created by Sylus Abel on 05/08/2026
//
// A swipeable "deck" of cards (front card on top, up to two peeking behind).
// `CardStack` owns the stacking math, drag-to-advance, and auto-advance; callers
// supply the card view and a tap handler. Two card faces live here: `MyTripCard`
// (a saved trip, with actions) and `BookmarkedDestinationCard` (a bookmarked
// destination — whole-card tap, no buttons).
//

import SwiftUI
import UIKit

// MARK: - Trip card (saved trips)

struct MyTripCard: View {
  let trip: Trip
  var onView: () -> Void = {}
  var onEdit: () -> Void = {}

  var body: some View {
    ZStack {
      RemoteImage(trip.coverImageName, width: 340, height: 340)
        .frame(maxWidth: .infinity)
        .frame(height: 340)
        .clipped()

      LinearGradient(
        colors: [.black.opacity(0.6), .black.opacity(0.25), .clear, .black.opacity(0.6)],
        startPoint: .top,
        endPoint: .bottom
      )

      VStack(spacing: 0) {
        header
        Spacer(minLength: 0)
        footerButtons
      }
      .padding(14)
    }
    .frame(maxWidth: .infinity)
    .frame(height: 340)
    .clipShape(.rect(cornerRadius: 24, style: .continuous))
    .contentShape(.rect(cornerRadius: 24, style: .continuous))
  }

  private var header: some View {
    HStack(alignment: .top) {
      VStack(alignment: .leading, spacing: 4) {
        Text(trip.title)
          .font(.title3.bold())
          .fontDesign(.rounded)
          .foregroundStyle(.white)
          .lineLimit(1)
          .minimumScaleFactor(0.8)

        if !trip.subtitle.isEmpty {
          Text(trip.subtitle)
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.9))
            .lineLimit(1)
        }
      }

      Spacer(minLength: 0)

      Label(trip.dateLabel, systemImage: "calendar")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: .capsule)
    }
  }

  private var footerButtons: some View {
    HStack(spacing: 10) {
      Button(action: onEdit) {
        Label("Edit", systemImage: "sparkles")
          .fontWeight(.semibold)
          .frame(maxWidth: .infinity, minHeight: 46)
      }
      .foregroundStyle(.white)
      .background(.ultraThinMaterial, in: .capsule)

      Button(action: onView) {
        Label("View Trip", systemImage: "arrow.up.right")
          .fontWeight(.semibold)
          .frame(maxWidth: .infinity, minHeight: 46)
      }
      .foregroundStyle(.white)
      .background(.accent, in: .capsule)
    }
  }
}

// MARK: - Bookmarked destination card

/// A bookmarked destination in the deck. No action buttons — the whole card is
/// the tap target (opens the destination detail), matching the request.
struct BookmarkedDestinationCard: View {
  let place: SavedPlace

  var body: some View {
    ZStack(alignment: .bottomLeading) {
      RemoteImage(place.imageURL, width: 340, height: 340)
        .frame(maxWidth: .infinity)
        .frame(height: 340)
        .clipped()

      LinearGradient(
        colors: [.black.opacity(0.35), .clear, .clear, .black.opacity(0.65)],
        startPoint: .top,
        endPoint: .bottom
      )

      VStack(alignment: .leading, spacing: 4) {
        Text(place.name)
          .font(.title3.bold())
          .fontDesign(.rounded)
          .foregroundStyle(.white)
          .lineLimit(2)

        if !place.subtitle.isEmpty {
          Text(place.subtitle)
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.9))
            .lineLimit(1)
        }
      }
      .padding(16)
    }
    .frame(maxWidth: .infinity)
    .frame(height: 340)
    .clipShape(.rect(cornerRadius: 24, style: .continuous))
    .contentShape(.rect(cornerRadius: 24, style: .continuous))
    .overlay(alignment: .topTrailing) {
      Image(systemName: "bookmark.fill")
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(.white)
        .frame(width: 32, height: 32)
        .background(.ultraThinMaterial, in: .circle)
        .padding(12)
    }
  }
}

// MARK: - Generic swipeable deck

struct CardStack<Item: Identifiable, CardContent: View>: View {
  let items: [Item]
  var autoAdvanceSeconds: UInt64 = 8
  var onTap: (Item) -> Void = { _ in }
  @ViewBuilder var content: (Item) -> CardContent

  @State private var activeIndex = 0
  @GestureState private var dragTranslation: CGFloat = 0

  private var hasStack: Bool { items.count > 1 }

  private var visibleItems: [StackedItem<Item>] {
    guard !items.isEmpty else { return [] }
    let visibleCount = min(3, items.count)
    return (0..<visibleCount).map { depth in
      StackedItem(item: items[index(forDepth: depth)], depth: depth)
    }
  }

  var body: some View {
    ZStack(alignment: .top) {
      ForEach(visibleItems.reversed()) { stacked in
        content(stacked.item)
          .scaleEffect(scale(forDepth: stacked.depth), anchor: .top)
          .offset(x: xOffset(forDepth: stacked.depth), y: yOffset(forDepth: stacked.depth))
          .rotationEffect(rotation(forDepth: stacked.depth))
          .opacity(opacity(forDepth: stacked.depth))
          .zIndex(Double(items.count - stacked.depth))
          .allowsHitTesting(stacked.depth == 0)
          .onTapGesture { if stacked.depth == 0 { onTap(stacked.item) } }
      }
    }
    .frame(height: hasStack ? 380 : 344)
    .contentShape(Rectangle())
    .gesture(dragGesture)
    .animation(.spring(response: 0.45, dampingFraction: 0.84), value: activeIndex)
    .animation(.interactiveSpring(response: 0.28, dampingFraction: 0.86), value: dragTranslation)
    .task(id: activeIndex) {
      await autoAdvanceIfNeeded()
    }
  }

  private var dragGesture: some Gesture {
    DragGesture(minimumDistance: 18)
      .updating($dragTranslation) { value, state, _ in
        state = value.translation.width
      }
      .onEnded { value in
        let threshold: CGFloat = 70
        let predictedOffset = value.translation.width + value.predictedEndTranslation.width * 0.18

        if predictedOffset <= -threshold {
          advance(forward: true, haptics: true)
        } else if predictedOffset >= threshold {
          advance(forward: false, haptics: true)
        }
      }
  }

  private func autoAdvanceIfNeeded() async {
    guard hasStack else { return }

    do {
      try await Task.sleep(for: .seconds(autoAdvanceSeconds))
    } catch {
      return
    }

    guard !Task.isCancelled else { return }
    advance(forward: true, haptics: false)
  }

  private func advance(forward: Bool, haptics: Bool) {
    guard hasStack else { return }

    if haptics {
      UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    withAnimation(.spring(response: 0.45, dampingFraction: 0.84)) {
      if forward {
        activeIndex = (activeIndex + 1) % items.count
      } else {
        activeIndex = (activeIndex - 1 + items.count) % items.count
      }
    }
  }

  private func index(forDepth depth: Int) -> Int {
    (activeIndex + depth) % items.count
  }

  private func xOffset(forDepth depth: Int) -> CGFloat {
    guard depth == 0 else { return 0 }
    return dragTranslation
  }

  private func yOffset(forDepth depth: Int) -> CGFloat {
    // A lone card sits flush; with a stack, the front card drops to let the
    // ones behind peek out the top.
    guard hasStack else { return 0 }
    switch depth {
    case 0: return abs(dragTranslation) * 0.02 + 28
    case 1: return 8
    default: return 0
    }
  }

  private func scale(forDepth depth: Int) -> CGFloat {
    switch depth {
    case 0: return 1.0 - min(abs(dragTranslation) / 1800, 0.04)
    case 1: return 0.94
    default: return 0.88
    }
  }

  private func opacity(forDepth depth: Int) -> Double {
    depth > 1 ? 0.72 : 1
  }

  private func rotation(forDepth depth: Int) -> Angle {
    guard depth == 0 else { return .zero }
    return .degrees(Double(dragTranslation / 24))
  }
}

private struct StackedItem<Item: Identifiable>: Identifiable {
  let item: Item
  let depth: Int

  var id: Item.ID { item.id }
}

#Preview {
  CardStack(items: Trip.previews, onTap: { _ in }) { trip in
    MyTripCard(trip: trip)
  }
  .padding()
}
