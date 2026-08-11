//
//  MyTrips.swift
//  Places
//
//  Created by Sylus Abel on 11/08/2026.
//

import SwiftUI
import SwiftData
import SwiftfulRouting

struct MyTrips: View {
    @Environment(\.router) private var router
    @Environment(\.colorScheme) var colorScheme
    @Environment(ContentStore.self) private var content: ContentStore?
    @Query(sort: \SavedTrip.createdAt, order: .reverse) private var savedTrips: [SavedTrip]
    @Query(filter: #Predicate<SavedPlace> { $0.kind == "destination" },
           sort: \SavedPlace.createdAt, order: .reverse)
    private var bookmarkedDestinations: [SavedPlace]

    @State private var scrollProgressX: CGFloat = 0

    /// The trip currently centered in the cover-flow — drives the page dots.
    private var activeIndex: Int {
        guard !savedTrips.isEmpty else { return 0 }
        return min(max(Int(scrollProgressX.rounded()), 0), savedTrips.count - 1)
    }

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 26) {
                if savedTrips.isEmpty {
                    ContentEmptyState(icon: "suitcase",
                                      message: "Your saved trips will appear here.\nPlan one to get started.")
                        .padding(.top, 80)
                } else {
                    VStack(spacing: 12) {
                        CarouselView()
                        if savedTrips.count > 1 { pageDots }
                    }
                }

                if !bookmarkedDestinations.isEmpty {
                    bookmarkedSection
                }

                ForYouSection()
                SponsoredSection()
            }
        }
        .safeAreaPadding(15)
        .scrollIndicators(.hidden)
        .background {
            Rectangle()
                .fill(gradientColor)
                .scaleEffect(y: -1)
                .ignoresSafeArea()
        }
        .task { await content?.loadPopularDestinations() }
    }

    // MARK: Cover-flow

    @ViewBuilder
    func CarouselView() -> some View {
        let spacing: CGFloat = 6

        ScrollView(.horizontal) {
            LazyHStack(spacing: spacing) {
                ForEach(savedTrips) { trip in
                    Button {
                        router.showScreen(.push) { _ in TripView(trip: trip) }
                    } label: {
                        tripCard(trip)
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
            .scrollTargetLayout()
        }
        .frame(height: 380)
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
        .onScrollGeometryChange(for: CGFloat.self) {
            let offsetX = $0.contentOffset.x + $0.contentInsets.leading
            let width = $0.containerSize.width + spacing
            return offsetX / width
        } action: { oldValue, newValue in
            let maxValue = CGFloat(savedTrips.count - 1)
            scrollProgressX = min(max(newValue, 0), maxValue)
        }
    }

    /// A single cover-flow card: full-bleed cover with a legibility scrim,
    /// the destination + date range bottom-left, and a countdown pill top-left.
    @ViewBuilder
    private func tripCard(_ trip: SavedTrip) -> some View {
        ZStack(alignment: .bottomLeading) {
            // RemoteImage handles both remote URLs and local asset names.
            RemoteImage(trip.coverImageName ?? "onboarding1", width: 400, height: 380)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()

            LinearGradient(colors: [.clear, .clear, .black.opacity(0.7)],
                           startPoint: .top, endPoint: .bottom)

            VStack(alignment: .leading, spacing: 4) {
                Text(trip.title)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                Text(trip.dateRangeLabel)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))
            }
//            .shadow(color: .black.opacity(0.35), radius: 6, y: 2)
            .padding(18)
        }
        .frame(height: 380)
        .containerRelativeFrame(.horizontal)
        .clipShape(.rect(cornerRadius: 20))
        .overlay(alignment: .topLeading) {
            if let label = trip.countdownLabel {
                countdownPill(label)
            }
        }
//        .shadow(color: .black.opacity(0.35), radius: 8, x: 0, y: 6)
    }

    private func countdownPill(_ text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: "clock.fill")
                .font(.system(size: 11, weight: .semibold))
            Text(text)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(.regularMaterial, in: .capsule)
        .padding(14)
    }

    private var pageDots: some View {
        HStack(spacing: 7) {
            ForEach(savedTrips.indices, id: \.self) { i in
                Circle()
                    .fill(i == activeIndex ? Color.accentColor : Color.primary.opacity(0.2))
                    .frame(width: i == activeIndex ? 8 : 6,
                           height: i == activeIndex ? 8 : 6)
            }
        }
        .animation(.snappy(duration: 0.25), value: activeIndex)
    }

    // MARK: Bookmarked destinations (card stack)

    private var bookmarkedSection: some View {
        VStack(spacing: 8) {
            SectionHeader(title: "Bookmarked", hasButton: false, action: {})
            CardStack(items: bookmarkedDestinations, onTap: { openBookmark($0) }) { place in
                BookmarkedDestinationCard(place: place)
            }
        }
    }

    /// Opens the full destination detail. Prefers the live DTO from ContentStore
    /// (rich fields) and falls back to a minimal DTO rebuilt from the bookmark.
    private func openBookmark(_ place: SavedPlace) {
        let dto = resolvedDestination(for: place)
        router.showScreen(.push) { _ in DestinationDetailView(destination: dto) }
    }

    private func resolvedDestination(for place: SavedPlace) -> DestinationDTO {
        if case .loaded(let dtos)? = content?.popularDestinations,
           let match = dtos.first(where: { $0.id == place.refId }) {
            return match
        }
        return DestinationDTO(bookmark: place)
    }

    private var gradientColor: AnyGradient {
        colorScheme == .dark ? Color.black.gradient : Color.white.gradient
    }
}

fileprivate extension SavedTrip {
    /// "Aug 20 – Aug 24, 2026" when a start date is known, else the duration label.
    var dateRangeLabel: String {
        if let cfg = config, let start = cfg.startDate {
            let end = Calendar.current.date(byAdding: .day,
                                            value: max(0, cfg.durationDays - 1),
                                            to: start) ?? start
            let startStr = start.formatted(.dateTime.month(.abbreviated).day())
            let endStr = end.formatted(.dateTime.month(.abbreviated).day().year())
            return "\(startStr) – \(endStr)"
        }
        return config?.durationLabel ?? subtitle
    }

    /// A short status pill: "In 5 days", "Today", "On trip", "Completed", or the
    /// duration label when the trip has no fixed start date.
    var countdownLabel: String? {
        guard let start = config?.startDate else { return config?.durationLabel }
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let startDay = cal.startOfDay(for: start)
        let days = cal.dateComponents([.day], from: today, to: startDay).day ?? 0
        let duration = config?.durationDays ?? 1
        if days > 1 { return "In \(days) days" }
        if days == 1 { return "Tomorrow" }
        if days == 0 { return "Today" }
        if -days < duration { return "On trip" }
        return "Completed"
    }
}

fileprivate extension DestinationDTO {
    /// A minimal DTO reconstructed from a bookmark, for when the full destination
    /// isn't in the loaded content cache. Rich fields are left empty/nil.
    init(bookmark p: SavedPlace) {
        self.init(id: p.refId, name: p.name, category: p.subtitle, countryCode: "",
                  latitude: p.latitude, longitude: p.longitude, description: "",
                  bannerUrl: p.imageURL, images: p.imageURL.isEmpty ? [] : [p.imageURL],
                  nonResidentFeeUsd: nil, feeLabel: nil, vehicleFeeGuidelines: nil,
                  paymentInfrastructure: nil, interestTags: [], bestSeason: nil,
                  closestHub: nil, rating: nil, bestTimeToVisit: nil, priceRange: nil,
                  isPopular: true)
    }
}

#Preview {
    MyTrips()
}
