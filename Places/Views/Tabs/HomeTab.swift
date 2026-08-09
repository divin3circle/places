//
//  HomeTab.swift
//  Places
//
//  Created by Sylus Abel on 30/07/2026.
//

import SwiftUI
import SwiftfulRouting
import SwiftData

struct HomeTab: View {
    let sponsoredAnimation: Namespace.ID

    @Environment(\.router) private var router
    @Environment(ContentStore.self) private var content: ContentStore?
    @Environment(SponsoredViewModel.self) private var sponsoredModel

    @State private var selectedTrip: Trip?
    @State private var savedIds: Set<UUID> = []
    @State private var savedExperienceIds: Set<UUID> = []
    @State private var city: EACity = .nairobi

    @Query(sort: \SavedTrip.createdAt, order: .reverse) private var savedTrips: [SavedTrip]
    /// Real saved trips, falling back to sample data when the user has none yet.
    private var trips: [Trip] { savedTrips.isEmpty ? Trip.dummyTrips : savedTrips.map(\.displayTrip) }

    private static let forYouItems: [FeedItem] = [
        .init(image: "onboarding1", title: "Maasai Mara", subtitle: "Wild savanna & the Big Five"),
        .init(image: "onboarding5", title: "Diani Beach", subtitle: "White sand & turquoise water"),
        .init(image: "onboarding4", title: "Mount Kenya", subtitle: "Alpine treks above the clouds"),
        .init(image: "onboarding3", title: "Zanzibar", subtitle: "Spice markets & old-town lanes"),
    ]

    var body: some View {
        VStack(spacing: 28) {
            forYouSection
            myTripsSection
            popularSection
            sponsoredSection
            exploreExperiencesSection
            popularExperiencesSection
        }
        .padding(.top, 4)
        .padding(.bottom, 10)
        .task { await loadContent() }
        .sheet(item: $selectedTrip) { trip in
            TripDetailSheet(
                trip: trip,
                onView: { selectedTrip = nil },  // TODO: navigate to the Trip view
                onEdit: { selectedTrip = nil }   // TODO: open the Trip in AI chat mode
            )
        }
    }

    private func loadContent() async {
        await content?.loadPopularDestinations()
        await content?.loadSponsored()
        await content?.loadCategories()
        await content?.loadExperiences(cityId: city.rawValue)
    }

    // MARK: Sections (sample data — For You / My Trips are later phases)

    private var forYouSection: some View {
        VStack(spacing: 8) {
            SectionHeader(title: "For You", hasButton: false, action: {})
            carousel(Self.forYouItems) { item in
                Button {
                    pushDetail(title: item.title, image: item.image)
                } label: {
                    PlaceCard(image: item.image, title: item.title, subtitle: item.subtitle,
                              width: 300, imageHeight: 210,
                              isSaved: savedIds.contains(item.id),
                              onToggleSave: { toggleSave(item.id) })
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
    }

    private var myTripsSection: some View {
        VStack(spacing: 8) {
            SectionHeader(title: "My Trips", hasButton: true, action: {})
            carousel(trips) { trip in
                Button {
                    selectedTrip = trip
                } label: {
                    PlaceCard(image: trip.coverImageName, title: trip.title, subtitle: trip.subtitle,
                              width: 200, imageHeight: 150)
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
    }

    // MARK: Sections (live Supabase content)

    private var popularSection: some View {
        VStack(spacing: 8) {
            SectionHeader(title: "Popular Destinations", hasButton: true, action: {})
            loadableSection(content?.popularDestinations,
                            empty: "No destinations yet.",
                            retry: { await content?.loadPopularDestinations(force: true) }) { dtos in
                carousel(dtos) { dto in
                    Button {
                        pushDestination(dto)
                    } label: {
                        PlaceCard(image: dto.bannerUrl, title: dto.name, subtitle: dto.subtitleLabel,
                                  width: 175, imageHeight: 130)
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
        }
    }

    private var sponsoredSection: some View {
        VStack(spacing: 8) {
            SectionHeader(title: "Sponsored", hasButton: false, action: {})
            loadableSection(content?.sponsored,
                            empty: "No sponsors yet.",
                            retry: { await content?.loadSponsored(force: true) }) { dtos in
                carousel(dtos) { dto in
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
        }
    }

    private var exploreExperiencesSection: some View {
        VStack(spacing: 8) {
            SectionHeader(title: "Explore experiences nearby", hasButton: true, action: {})
            loadableSection(content?.categories,
                            empty: "No categories yet.",
                            retry: { await content?.loadCategories(force: true) }) { dtos in
                carousel(dtos) { dto in
                    let cat = ExperienceCategory(dto: dto)
                    Button {
                        router.showScreen(.push) { _ in
                            ExperienceCategoryListView(category: cat, city: city)
                        }
                    } label: {
                        ExperienceCategoryCard(category: cat)
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
        }
    }

    private var popularExperiencesSection: some View {
        VStack(spacing: 8) {
            SectionHeader(title: "Popular experiences in \(city.displayName)", hasButton: true, action: {})
            loadableSection(content?.experiencesByCity[city.rawValue],
                            empty: "No experiences yet.",
                            retry: { await content?.loadExperiences(cityId: city.rawValue, force: true) }) { dtos in
                carousel(dtos) { dto in
                    let exp = Experience(dto: dto)
                    VStack(alignment: .leading, spacing: 8) {
                        DestinationTransition { isExpanded, _ in
                            ExperienceHero(
                                experience: exp,
                                cornerRadius: isExpanded ? 0 : 16,
                                expanded: isExpanded,
                                isSaved: savedExperienceIds.contains(exp.id),
                                onToggleSave: { toggleExperienceSave(exp.id) }
                            )
                        } content: { _, _ in
                            ExperienceDetailBody(experience: exp, showsTitle: false)
                        }
                        .frame(width: 300, height: 220)

                        ExperienceCaption(experience: exp, width: 300)
                    }
                }
            }
        }
    }

    // MARK: Loadable section states

    @ViewBuilder
    private func loadableSection<T, Content: View>(
        _ state: Loadable<[T]>?,
        empty: String,
        retry: @escaping () async -> Void,
        @ViewBuilder content: (_ items: [T]) -> Content
    ) -> some View {
        switch state ?? .idle {
        case .idle, .loading:
            skeletonRow()
        case .loaded(let items):
            if items.isEmpty {
                ContentEmptyState(message: empty)
            } else {
                content(items)
            }
        case .failed(let message):
            retryRow(message: message, retry: retry)
        }
    }

    private func skeletonRow() -> some View {
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

    private func retryRow(message: String, retry: @escaping () async -> Void) -> some View {
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

    // MARK: Helpers

    private func carousel<Item: Identifiable, Card: View>(
        _ items: [Item],
        @ViewBuilder card: @escaping (Item) -> Card
    ) -> some View {
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

    private func toggleSave(_ id: UUID) {
        withAnimation(.snappy) {
            if savedIds.contains(id) { savedIds.remove(id) } else { savedIds.insert(id) }
        }
    }

    private func toggleExperienceSave(_ id: UUID) {
        withAnimation(.snappy) {
            if savedExperienceIds.contains(id) { savedExperienceIds.remove(id) } else { savedExperienceIds.insert(id) }
        }
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
}

private struct FeedItem: Identifiable {
    let id = UUID()
    let image: String
    let title: String
    let subtitle: String
}

#Preview {
    AppTab()
}
