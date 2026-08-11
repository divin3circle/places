//
//  CollectionDetailView.swift
//  Places
//
//  The screen opened from an Explore "Collections" tile: a themed header over
//  the live destinations whose `interest_tags` overlap the collection's tags.
//  Reads the already-loaded `popularDestinations` — no extra fetch.
//

import SwiftUI
import SwiftfulRouting

struct CollectionDetailView: View {
    let collection: DiscoveryCollection

    @Environment(\.router) private var router
    @Environment(ContentStore.self) private var content: ContentStore?

    private var matches: [DestinationDTO] {
        guard case .loaded(let dtos) = content?.popularDestinations else { return [] }
        let wanted = Set(collection.tags)
        return dtos.filter { !wanted.isDisjoint(with: Set($0.interestTags)) }
    }

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 18) {
                header
                switch content?.popularDestinations ?? .idle {
                case .idle, .loading:
                    skeleton
                case .loaded:
                    if matches.isEmpty {
                        ContentEmptyState(icon: collection.systemImage,
                                          message: "Nothing in this collection yet.")
                            .padding(.horizontal, 15)
                    } else {
                        LazyVStack(spacing: 18) {
                            ForEach(matches) { dto in
                                Button { pushDestination(dto) } label: {
                                    CollectionDestinationRow(destination: dto)
                                }
                                .buttonStyle(PressableButtonStyle())
                            }
                        }
                        .padding(.horizontal, 15)
                    }
                case .failed(let message):
                    Text(message)
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                }
            }
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .toolbar(.hidden, for: .navigationBar)
        .task { await content?.loadPopularDestinations() }
    }

    private var header: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: collection.gradient,
                           startPoint: .topTrailing, endPoint: .bottomLeading)
            LinearGradient(colors: [.clear, .black.opacity(0.35)],
                           startPoint: .center, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: collection.systemImage)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.white)
                Text(collection.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(collection.subtitle)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(20)
        }
        .frame(height: 220)
        .clipShape(.rect(cornerRadius: 0))
        .overlay(alignment: .topLeading) { backButton }
        .ignoresSafeArea(edges: .top)
    }

    private var backButton: some View {
        Button { router.dismissScreen() } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: .circle)
        }
        .buttonStyle(PressableButtonStyle())
        .padding(.leading, 12)
        .padding(.top, 8)
    }

    private var skeleton: some View {
        LazyVStack(spacing: 18) {
            ForEach(0..<4, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.gray.opacity(0.22))
                    .frame(height: 96)
            }
        }
        .padding(.horizontal, 15)
        .redacted(reason: .placeholder)
        .allowsHitTesting(false)
    }

    private func pushDestination(_ dto: DestinationDTO) {
        router.showScreen(.push) { _ in DestinationDetailView(destination: dto) }
    }
}

/// Compact horizontal destination row used inside a collection.
private struct CollectionDestinationRow: View {
    let destination: DestinationDTO

    var body: some View {
        HStack(spacing: 14) {
            RemoteImage(destination.bannerUrl, width: 96, height: 96)
                .frame(width: 96, height: 96)
                .clipShape(.rect(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(destination.name)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                Text(destination.subtitleLabel)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.secondary)
                if let hub = destination.closestHub {
                    Text(hub)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
    }
}
