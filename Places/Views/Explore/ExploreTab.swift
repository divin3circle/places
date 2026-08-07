//
//  ExploreTab.swift
//  Places
//
//  Created by Sylus Abel on 03/08/2026.
//

import SwiftUI
import SwiftfulRouting

/// The Explore discovery screen: hero + search, an upcoming trip with a live
/// countdown, recommendations, and a filterable "slow down" carousel.
struct ExploreTab: View {
    @Environment(\.router) private var router

    @State private var searchText = ""
    @State private var selectedCategory: String? = nil

    private let upcoming = UpcomingTrip.sample
    private let recommendations = RecommendedDestination.samples
    private let curated = CuratedTrip.samples

    var body: some View {
        GeometryReader { proxy in
            let topInset = proxy.safeAreaInsets.top
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 24) {
                    ExploreHero(searchText: $searchText, topInset: topInset)

                    VStack(alignment: .leading, spacing: 24) {
                        upcomingSection

                        recommendationsSection

                        curatedSection
                    }
                    .padding(.horizontal, 15)
                }
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
            .ignoresSafeArea(edges: .top)
        }
    }

    // MARK: Sections

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionTitle("Upcoming")
                Spacer()
                CountdownBadge(target: upcoming.countdownTarget)
            }
            UpcomingTripCard(trip: upcoming) {
                pushDetail(title: upcoming.title, image: upcoming.coverImageName)
            }
        }
    }

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Recommendations")
            ScrollView(.horizontal) {
                LazyHStack(spacing: 18) {
                    ForEach(filteredRecommendations) { destination in
                        Button {
                            pushDetail(title: destination.name, image: destination.imageNames.first ?? "sample")
                        } label: {
                            RecommendationCard(destination: destination)
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                }
                .padding(.vertical, 4)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var curatedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Places worth slowing down for")

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    FilterPill(label: "All", isSelected: selectedCategory == nil) {
                        selectedCategory = nil
                    }
                    ForEach(CuratedTrip.filters) { filter in
                        FilterPill(
                            icon: filter.icon,
                            label: filter.label,
                            isSelected: selectedCategory == filter.category
                        ) {
                            selectedCategory = filter.category
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)

            ScrollView(.horizontal) {
                LazyHStack(spacing: 14) {
                    ForEach(filteredCurated) { trip in
                        Button {
                            pushDetail(title: trip.title, image: trip.imageName)
                        } label: {
                            CuratedTripCard(trip: trip)
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                }
                .padding(.vertical, 4)
            }
            .scrollIndicators(.hidden)
            .animation(.snappy, value: selectedCategory)
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

    private func pushDetail(title: String, image: String) {
        router.showScreen(.push) { _ in
            ExploreDetailView(title: title, imageName: image)
        }
    }

    private var filteredRecommendations: [RecommendedDestination] {
        guard !searchText.isEmpty else { return recommendations }
        return recommendations.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var filteredCurated: [CuratedTrip] {
        curated.filter { trip in
            let matchesCategory = selectedCategory == nil || trip.category == selectedCategory
            let matchesSearch = searchText.isEmpty || trip.title.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch
        }
    }
}

#Preview {
    RouterView { _ in
        ExploreTab()
    }
}
