//
//  ExploreTab.swift
//  Places
//
//  Created by Sylus Abel on 03/08/2026.
//

import SwiftUI
import SwiftfulRouting
import SwiftData

/// The Explore discovery screen: hero + search, the traveler's most recent
/// planned trip, and live destination recommendations from Supabase.
struct ExploreTab: View {
    @Environment(\.router) private var router
    @Environment(ContentStore.self) private var content: ContentStore?

    @State private var searchText = ""

    @Query(sort: \SavedTrip.createdAt, order: .reverse) private var savedTrips: [SavedTrip]
    /// Most recently planned trip, surfaced as the Explore hero (nil until one exists).
    private var upcoming: UpcomingTrip? {
        guard let latest = savedTrips.first else { return nil }
        return UpcomingTrip(savedTrip: latest)
    }

    var body: some View {
        GeometryReader { proxy in
            let topInset = proxy.safeAreaInsets.top
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 24) {
                    ExploreHero(searchText: $searchText, topInset: topInset)

                    VStack(alignment: .leading, spacing: 24) {
                        upcomingSection
                        recommendationsSection
                    }
                    .padding(.horizontal, 15)
                }
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
            .ignoresSafeArea(edges: .top)
            .task { await content?.loadPopularDestinations() }
        }
    }

    // MARK: Sections

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Your latest plan")
            if let upcoming {
                UpcomingTripCard(trip: upcoming) {
                    pushDetail(title: upcoming.title, image: upcoming.coverImageName)
                }
            } else {
                ContentEmptyState(icon: "airplane.departure",
                                  message: "Plan a trip and it'll appear here.")
            }
        }
    }

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Recommendations")
            switch content?.popularDestinations ?? .idle {
            case .idle, .loading:
                recommendationSkeleton
            case .loaded(let dtos):
                let items = filtered(dtos)
                if items.isEmpty {
                    ContentEmptyState(message: searchText.isEmpty
                                      ? "No destinations yet."
                                      : "No matches for \u{201C}\(searchText)\u{201D}.")
                } else {
                    ScrollView(.horizontal) {
                        LazyHStack(spacing: 18) {
                            ForEach(items) { dto in
                                Button {
                                    pushDestination(dto)
                                } label: {
                                    RecommendationCard(name: dto.name, images: cardImages(dto))
                                }
                                .buttonStyle(PressableButtonStyle())
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .scrollIndicators(.hidden)
                }
            case .failed(let message):
                retryRow(message)
            }
        }
    }

    // MARK: Helpers

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.title2)
            .fontWeight(.semibold)
            .fontDesign(.rounded)
            .fontWidth(.expanded)
    }

    private func filtered(_ dtos: [DestinationDTO]) -> [DestinationDTO] {
        guard !searchText.isEmpty else { return dtos }
        return dtos.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    /// Up to three image sources for the fanned stack; pad short galleries so the
    /// fan still reads as a stack. Remote URLs and asset names both work here.
    private func cardImages(_ dto: DestinationDTO) -> [String] {
        let base = dto.images.isEmpty ? [dto.bannerUrl] : dto.images
        guard base.count < 3, let first = base.first else { return base }
        return base + Array(repeating: first, count: 3 - base.count)
    }

    private func pushDetail(title: String, image: String) {
        router.showScreen(.push) { _ in
            ExploreDetailView(title: title, imageName: image)
        }
    }

    private func pushDestination(_ dto: DestinationDTO) {
        router.showScreen(.push) { _ in
            ExploreDetailView(destination: dto)
        }
    }

    private var recommendationSkeleton: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 18) {
                ForEach(0..<4, id: \.self) { _ in
                    VStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.gray.opacity(0.22))
                            .frame(width: 110, height: 104)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.22))
                            .frame(width: 80, height: 12)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .scrollIndicators(.hidden)
        .redacted(reason: .placeholder)
        .allowsHitTesting(false)
    }

    private func retryRow(_ message: String) -> some View {
        VStack(spacing: 8) {
            Text(message)
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(.secondary)
            Button {
                Task { await content?.loadPopularDestinations(force: true) }
            } label: {
                Label("Retry", systemImage: "arrow.clockwise")
                    .font(.system(.footnote, design: .rounded).weight(.semibold))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

#Preview {
    RouterView { _ in
        ExploreTab()
    }
}
