//
//  ExperienceCategoryListView.swift
//  Places
//
//  The filtered list opened when a category tile is tapped in the "Explore
//  experiences nearby" row: a header, a filter-pill row (seeded with the tapped
//  category), a search field, and a vertical list of experiences. Each row pushes
//  the experience detail.
//

import SwiftUI
import SwiftfulRouting

struct ExperienceCategoryListView: View {
    let category: ExperienceCategory
    var city: EACity = .nairobi

    @Environment(\.router) private var router

    @State private var selectedTag: String
    @State private var searchText = ""
    @State private var savedIds: Set<UUID> = []

    init(category: ExperienceCategory, city: EACity = .nairobi) {
        self.category = category
        self.city = city
        _selectedTag = State(initialValue: category.tag)
    }

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Experiences in \(city.displayName)")
                        .font(.system(.title2, design: .rounded).bold())
                        .fontWidth(.expanded)

                    ExploreSearchBar(text: $searchText)

                    filterPills
                }
                .padding(.horizontal, 15)

                LazyVStack(spacing: 22) {
                    ForEach(filtered) { experience in
                        Button {
                            router.showScreen(.push) { _ in
                                ExperienceDetailView(experience: experience)
                            }
                        } label: {
                            ExperienceRow(
                                experience: experience,
                                isSaved: savedIds.contains(experience.id),
                                onToggleSave: { toggleSave(experience.id) }
                            )
                        }
                        .buttonStyle(PressableButtonStyle())
                    }

                    if filtered.isEmpty {
                        Text("No experiences here yet.")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                    }
                }
                .padding(.horizontal, 15)
                .animation(.snappy, value: selectedTag)
            }
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
    }

    private var filterPills: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(ExperienceCategory.all) { cat in
                    FilterPill(
                        label: cat.label,
                        isSelected: selectedTag == cat.tag
                    ) {
                        selectedTag = cat.tag
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    private var filtered: [Experience] {
        Experience.samples.filter { exp in
            let matchesCity = exp.city == city
            let matchesTag = exp.categoryTag == selectedTag
            let matchesSearch = searchText.isEmpty
                || exp.title.localizedCaseInsensitiveContains(searchText)
            return matchesCity && matchesTag && matchesSearch
        }
    }

    private func toggleSave(_ id: UUID) {
        withAnimation(.snappy) {
            if savedIds.contains(id) { savedIds.remove(id) } else { savedIds.insert(id) }
        }
    }
}

#Preview {
    RouterView { _ in
        ExperienceCategoryListView(category: ExperienceCategory.all[6])
    }
}
