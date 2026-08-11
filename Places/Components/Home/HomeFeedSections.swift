//
//  HomeFeedSections.swift
//  Places
//
//  Reusable Home-feed rows so surfaces beyond the Home tab (e.g. My Trips) can
//  drop in the same personalized "For You" and "Sponsored" carousels instead of
//  duplicating the loadable-state + carousel plumbing. Each section reads its
//  own dependencies from the environment and self-loads on appear.
//

import SwiftUI
import SwiftfulRouting

// MARK: - For You

struct ForYouSection: View {
    @Environment(\.router) private var router
    @Environment(ContentStore.self) private var content: ContentStore?
    @Environment(SessionStore.self) private var session: SessionStore?

    var body: some View {
        VStack(spacing: 8) {
            SectionHeader(title: "For You", hasButton: false, action: {})
            LoadableCarousel(content?.forYou,
                             empty: "Tell us what you love to see picks here.",
                             retry: { await content?.loadForYou(interests: interests, force: true) }) { item in
                Button {
                    route(item)
                } label: {
                    PlaceCard(image: item.imageURL, title: item.title, subtitle: item.subtitle,
                              width: 300, imageHeight: 210)
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
        .task { await content?.loadForYou(interests: interests) }
    }

    private var interests: [String] { session?.currentProfile?.interests ?? [] }

    private func route(_ item: ForYouItem) {
        switch item {
        case .destination(let dto):
            router.showScreen(.push) { _ in DestinationDetailView(destination: dto) }
        case .experience(let dto):
            router.showScreen(.push) { _ in ExperienceDetailView(experience: Experience(dto: dto)) }
        }
    }
}

// MARK: - Sponsored

struct SponsoredSection: View {
    @Environment(ContentStore.self) private var content: ContentStore?
    @Environment(SponsoredViewModel.self) private var sponsoredModel

    var body: some View {
        VStack(spacing: 8) {
            SectionHeader(title: "Sponsored", hasButton: false, action: {})
            LoadableCarousel(content?.sponsored,
                             empty: "No sponsors yet.",
                             retry: { await content?.loadSponsored(force: true) }) { dto in
                let card = Sponsored(dto: dto)
                Button {
                    withAnimation(.spring()) {
                        sponsoredModel.selectedCard = card
                        sponsoredModel.showCard = true
                    }
                } label: {
                    PlaceCard(image: card.image, title: card.title, subtitle: card.subtitle,
                              badge: "Sponsored", width: 185, imageHeight: 140)
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
        .task { await content?.loadSponsored() }
    }
}

// MARK: - Shared loadable carousel

/// A horizontal carousel that renders the four `Loadable` states (skeleton while
/// loading, cards when loaded, empty message, or a retry row on failure).
struct LoadableCarousel<Item: Identifiable, Card: View>: View {
    private let state: Loadable<[Item]>?
    private let empty: String
    private let retry: () async -> Void
    private let card: (Item) -> Card

    init(_ state: Loadable<[Item]>?,
         empty: String,
         retry: @escaping () async -> Void,
         @ViewBuilder card: @escaping (Item) -> Card) {
        self.state = state
        self.empty = empty
        self.retry = retry
        self.card = card
    }

    var body: some View {
        switch state ?? .idle {
        case .idle, .loading:
            skeletonRow
        case .loaded(let items):
            if items.isEmpty {
                ContentEmptyState(message: empty)
            } else {
                carousel(items)
            }
        case .failed(let message):
            retryRow(message: message)
        }
    }

    private func carousel(_ items: [Item]) -> some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 14) {
                ForEach(items) { card($0) }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 4)
        }
        .scrollIndicators(.hidden)
        .padding(.horizontal, -15)
    }

    private var skeletonRow: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 14) {
                ForEach(0..<4, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: 8) {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.gray.opacity(0.22))
                            .frame(width: 175, height: 130)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.22))
                            .frame(width: 120, height: 12)
                    }
                }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 4)
        }
        .scrollIndicators(.hidden)
        .padding(.horizontal, -15)
        .redacted(reason: .placeholder)
        .allowsHitTesting(false)
    }

    private func retryRow(message: String) -> some View {
        VStack(spacing: 8) {
            Text(message)
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(.secondary)
            Button {
                Task { await retry() }
            } label: {
                Label("Retry", systemImage: "arrow.clockwise")
                    .font(.system(.footnote, design: .rounded).weight(.semibold))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}
