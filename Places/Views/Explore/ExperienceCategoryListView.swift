//
//  ExperienceCategoryListView.swift
//  Places
//
//  The filtered list opened when a category tile is tapped in the "Explore
//  experiences nearby" row: a header, a filter-pill row (from live categories),
//  a search field, and a vertical list of experiences fetched for the city + tag.
//

import SwiftUI
import SwiftfulRouting
import SwiftData

struct ExperienceCategoryListView: View {
    let category: ExperienceCategory
    var city: EACity = .nairobi

    @Environment(\.router) private var router
    @Environment(ContentStore.self) private var content: ContentStore?
    @Environment(\.modelContext) private var context
    @Query private var savedPlaces: [SavedPlace]

    @State private var selectedTag: String
    @State private var searchText = ""

    init(category: ExperienceCategory, city: EACity = .nairobi) {
        self.category = category
        self.city = city
        _selectedTag = State(initialValue: category.tag)
    }

    private var key: String { "\(city.rawValue)|\(selectedTag)" }

    /// Live categories for the filter row; falls back to the tapped one until loaded.
    private var categoryPills: [ExperienceCategory] {
        if case .loaded(let dtos) = content?.categories, !dtos.isEmpty {
            return dtos.map(ExperienceCategory.init(dto:))
        }
        return [category]
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

                experiencesList
                    .padding(.horizontal, 15)
                    .animation(.snappy, value: selectedTag)
            }
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .task(id: selectedTag) {
            await content?.loadCategories()
            await content?.loadExperiences(cityId: city.rawValue, categoryTag: selectedTag)
        }
    }

    private var filterPills: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(categoryPills) { cat in
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

    @ViewBuilder
    private var experiencesList: some View {
        switch content?.experiencesByCategory[key] ?? .idle {
        case .idle, .loading:
            LazyVStack(spacing: 22) {
                ForEach(0..<4, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.gray.opacity(0.22))
                        .frame(height: 120)
                }
            }
            .redacted(reason: .placeholder)
            .allowsHitTesting(false)

        case .loaded(let dtos):
            let matches = dtos.filter {
                searchText.isEmpty || $0.title.localizedCaseInsensitiveContains(searchText)
            }
            if matches.isEmpty {
                Text("No experiences here yet.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
            } else {
                LazyVStack(spacing: 22) {
                    ForEach(matches) { dto in
                        let experience = Experience(dto: dto)
                        Button {
                            router.showScreen(.push) { _ in
                                ExperienceDetailView(experience: experience)
                            }
                        } label: {
                            ExperienceRow(
                                experience: experience,
                                isSaved: isSaved(dto),
                                onToggleSave: { toggleSave(dto) }
                            )
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                }
            }

        case .failed(let message):
            VStack(spacing: 8) {
                Text(message)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(.secondary)
                Button {
                    Task { await content?.loadExperiences(cityId: city.rawValue, categoryTag: selectedTag, force: true) }
                } label: {
                    Label("Retry", systemImage: "arrow.clockwise")
                        .font(.system(.footnote, design: .rounded).weight(.semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 40)
        }
    }

    private func isSaved(_ dto: ExperienceDTO) -> Bool {
        savedPlaces.contains { $0.kind == "experience" && $0.refId == dto.id.uuidString }
    }

    private func toggleSave(_ dto: ExperienceDTO) {
        if let existing = savedPlaces.first(where: { $0.kind == "experience" && $0.refId == dto.id.uuidString }) {
            context.delete(existing)
        } else {
            context.insert(SavedPlace(experience: dto))
        }
        try? context.save()
    }
}

#Preview {
    RouterView { _ in
        ExperienceCategoryListView(category: ExperienceCategory.preview)
    }
}
