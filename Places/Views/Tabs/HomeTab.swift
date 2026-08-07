//
//  HomeTab.swift
//  Places
//
//  Created by Sylus Abel on 30/07/2026.
//

import SwiftUI
import SwiftfulRouting

struct HomeTab: View {
    let sponsoredAnimation: Namespace.ID

    @Environment(\.router) private var router
    @EnvironmentObject private var sponsoredModel: SponsoredViewModel

    @State private var selectedTrip: Trip?
    @State private var savedIds: Set<UUID> = []
    @State private var savedExperienceIds: Set<UUID> = []
    @State private var city: EACity = .nairobi

    private let trips = Trip.dummyTrips
    private static let forYouItems: [FeedItem] = [
        .init(image: "onboarding1", title: "Maasai Mara", subtitle: "Wild savanna & the Big Five"),
        .init(image: "onboarding5", title: "Diani Beach", subtitle: "White sand & turquoise water"),
        .init(image: "onboarding4", title: "Mount Kenya", subtitle: "Alpine treks above the clouds"),
        .init(image: "onboarding3", title: "Zanzibar", subtitle: "Spice markets & old-town lanes"),
    ]
    private static let popularItems: [FeedItem] = [
        .init(image: "onboarding1", title: "Maasai Mara", subtitle: "Safari · ★ 4.9"),
        .init(image: "onboarding2", title: "Serengeti", subtitle: "Wildlife · ★ 4.8"),
        .init(image: "onboarding3", title: "Zanzibar", subtitle: "Beach · ★ 4.7"),
        .init(image: "onboarding4", title: "Kilimanjaro", subtitle: "Trek · ★ 4.9"),
        .init(image: "onboarding5", title: "Diani Beach", subtitle: "Beach · ★ 4.6"),
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
        .sheet(item: $selectedTrip) { trip in
            TripDetailSheet(
                trip: trip,
                onView: { selectedTrip = nil },  // TODO: navigate to the Trip view
                onEdit: { selectedTrip = nil }   // TODO: open the Trip in AI chat mode
            )
        }
    }

    // MARK: Sections

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

    private var popularSection: some View {
        VStack(spacing: 8) {
            SectionHeader(title: "Popular Destinations", hasButton: true, action: {})
            carousel(Self.popularItems) { item in
                Button {
                    pushDetail(title: item.title, image: item.image)
                } label: {
                    PlaceCard(image: item.image, title: item.title, subtitle: item.subtitle,
                              width: 175, imageHeight: 130)
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
    }

    private var sponsoredSection: some View {
        VStack(spacing: 8) {
            SectionHeader(title: "Sponsored", hasButton: false, action: {})
            carousel(sponsoredModel.cards) { card in
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

    // MARK: Experiences

    private var exploreExperiencesSection: some View {
        VStack(spacing: 8) {
            SectionHeader(title: "Explore experiences nearby", hasButton: true, action: {})
            carousel(ExperienceCategory.all) { cat in
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

    private var popularExperiencesSection: some View {
        VStack(spacing: 8) {
            SectionHeader(title: "Popular experiences in \(city.displayName)", hasButton: true, action: {})
            carousel(Experience.samples(in: city)) { exp in
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
