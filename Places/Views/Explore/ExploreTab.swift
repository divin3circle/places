//
//  ExploreTab.swift
//  Places
//
//  Created by Sylus Abel on 03/08/2026.
//

import SwiftUI
import SwiftfulRouting
import SwiftData
import MapKit

/// The Explore discovery screen: hero + search, the traveler's most recent
/// planned trip, and live destination recommendations from Supabase.
struct ExploreTab: View {
    @Environment(\.router) private var router
    @Environment(ContentStore.self) private var content: ContentStore?
    @Environment(\.openURL) private var openURL

    @State private var searchText = ""
    /// Selected "Things to do" category chip; nil = All.
    @State private var selectedExperienceTag: String? = nil

    /// City the "Things to do" feed is scoped to (no geolocation yet).
    private let city: EACity = .nairobi

    // Transport hand-offs — external providers until in-app search lands (v1).
    private struct TransportLink: Identifiable {
        let id = UUID()
        let title: String
        let icon: String
        let url: URL
    }
    private let transportLinks: [TransportLink] = [
        .init(title: "Flights", icon: "airplane", url: URL(string: "https://www.kenya-airways.com")!),
        .init(title: "Trains", icon: "train.side.front.car", url: URL(string: "https://metickets.krc.co.ke")!),
        .init(title: "Buses", icon: "bus.fill", url: URL(string: "https://www.buupass.com")!),
        .init(title: "Car hire", icon: "car.fill", url: URL(string: "https://www.google.com/search?q=car+hire+kenya")!),
        .init(title: "Transfers", icon: "airplane.arrival", url: URL(string: "https://www.google.com/search?q=nairobi+airport+transfer")!),
    ]

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
                        transportSection
                        mapSection
                        collectionsSection
                        upcomingSection
                        recommendationsSection
                        thingsToDoSection
                    }
                    .padding(.horizontal, 15)
                }
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
            .ignoresSafeArea(edges: .top)
            .task {
                await content?.loadPopularDestinations()
                await content?.loadCategories()
                await content?.loadExperiences(cityId: city.rawValue)
            }
        }
    }

    // MARK: Sections

    private var transportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Get around")
            ScrollView(.horizontal) {
                HStack(spacing: 14) {
                    ForEach(transportLinks) { link in
                        Button { openURL(link.url) } label: { transportPill(link) }
                            .buttonStyle(PressableButtonStyle())
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func transportPill(_ link: TransportLink) -> some View {
        VStack(spacing: 8) {
            Image(systemName: link.icon)
                .font(.system(size: 20))
                .foregroundStyle(.accent)
                .frame(width: 56, height: 56)
                .background(Color(.secondarySystemBackground), in: .circle)
            Text(link.title)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)
        }
        .frame(width: 72)
    }

    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Explore the map")
            Button {
                router.showScreen(.push) { _ in ExploreMapView() }
            } label: {
                ZStack(alignment: .bottomLeading) {
                    Map(initialPosition: .region(MKCoordinateRegion(
                        center: .init(latitude: -1.0, longitude: 36.5),
                        span: .init(latitudeDelta: 7, longitudeDelta: 7))),
                        interactionModes: [])
                        .mapStyle(.standard(pointsOfInterest: .excludingAll))
                        .allowsHitTesting(false)

                    LinearGradient(colors: [.clear, .black.opacity(0.5)],
                                   startPoint: .center, endPoint: .bottom)

                    Label("Browse destinations & experiences", systemImage: "map.fill")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(14)
                }
                .frame(height: 150)
                .clipShape(.rect(cornerRadius: 20, style: .continuous))
            }
            .buttonStyle(PressableButtonStyle())
        }
    }

    private var collectionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Collections")
            ScrollView(.horizontal) {
                HStack(spacing: 16) {
                    ForEach(DiscoveryCollection.all) { collection in
                        Button {
                            router.showScreen(.push) { _ in CollectionDetailView(collection: collection) }
                        } label: {
                            DiscoveryCollectionCard(collection: collection)
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var thingsToDoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Things to do")
            experienceChips
            thingsToDoContent
        }
    }

    /// "All" + live category chips, filtering the loaded experiences client-side.
    private var experienceChips: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                FilterPill(label: "All", isSelected: selectedExperienceTag == nil) {
                    selectedExperienceTag = nil
                }
                if case .loaded(let cats) = content?.categories {
                    ForEach(cats.map(ExperienceCategory.init(dto:))) { cat in
                        FilterPill(label: cat.label, isSelected: selectedExperienceTag == cat.tag) {
                            selectedExperienceTag = cat.tag
                        }
                    }
                }
            }
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
    }

    @ViewBuilder
    private var thingsToDoContent: some View {
        switch content?.experiencesByCity[city.rawValue] ?? .idle {
        case .idle, .loading:
            experienceSkeleton
        case .loaded(let dtos):
            let items = filteredExperiences(dtos)
            if items.isEmpty {
                ContentEmptyState(icon: "figure.walk",
                                  message: "No experiences in this category yet.")
            } else {
                ScrollView(.horizontal) {
                    LazyHStack(alignment: .top, spacing: 16) {
                        ForEach(items) { dto in
                            let experience = Experience(dto: dto)
                            Button {
                                router.showScreen(.push) { _ in
                                    ExperienceDetailView(experience: experience)
                                }
                            } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    ExperienceHero(experience: experience)
                                        .frame(width: 240, height: 180)
                                    ExperienceCaption(experience: experience, width: 240)
                                }
                            }
                            .buttonStyle(PressableButtonStyle())
                        }
                    }
                    .padding(.vertical, 4)
                }
                .scrollIndicators(.hidden)
                .animation(.snappy, value: selectedExperienceTag)
            }
        case .failed(let message):
            retryRow(message)
        }
    }

    private func filteredExperiences(_ dtos: [ExperienceDTO]) -> [ExperienceDTO] {
        guard let tag = selectedExperienceTag else { return dtos }
        return dtos.filter { $0.categoryTag == tag }
    }

    private var experienceSkeleton: some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .top, spacing: 16) {
                ForEach(0..<3, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: 8) {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.gray.opacity(0.22))
                            .frame(width: 240, height: 180)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.22))
                            .frame(width: 160, height: 12)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .scrollIndicators(.hidden)
        .redacted(reason: .placeholder)
        .allowsHitTesting(false)
    }

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
            DestinationDetailView(destination: dto)
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
