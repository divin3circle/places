//
//  ExploreMapViewModel.swift
//  Places
//
//  Backs the full-screen Explore map browse: fetches every destination + coord-
//  bearing experience as map pins that also carry their DTO, so tapping opens the
//  rich detail screen.
//

import Foundation
import CoreLocation

struct MapPlace: Identifiable {
    let id: String
    let name: String
    let subtitle: String
    let imageURL: String
    let coordinate: CLLocationCoordinate2D
    let destination: DestinationDTO?
    let experience: ExperienceDTO?

    var isExperience: Bool { experience != nil }
}

@Observable @MainActor
final class ExploreMapViewModel {
    private(set) var places: [MapPlace] = []
    private(set) var isLoading = false

    private let content: ContentProviding
    private var loaded = false

    init(content: ContentProviding = SupabaseContentRepository()) {
        self.content = content
    }

    func load() async {
        guard !loaded else { return }
        loaded = true
        isLoading = true

        async let dRaw = content.fetchPopularDestinations()
        async let eRaw = content.fetchExperiences(cityId: nil, categoryTag: nil)
        let dests = (try? await dRaw) ?? []
        let exps = (try? await eRaw) ?? []

        var out: [MapPlace] = dests.map { dto in
            MapPlace(id: dto.id, name: dto.name,
                     subtitle: dto.category.replacingOccurrences(of: "_", with: " ").capitalized,
                     imageURL: dto.bannerUrl,
                     coordinate: .init(latitude: dto.latitude, longitude: dto.longitude),
                     destination: dto, experience: nil)
        }
        out += exps.compactMap { dto in
            guard let lat = dto.latitude, let lng = dto.longitude else { return nil }
            return MapPlace(id: dto.id.uuidString, name: dto.title, subtitle: dto.categoryLabel,
                            imageURL: dto.images.first ?? "",
                            coordinate: .init(latitude: lat, longitude: lng),
                            destination: nil, experience: dto)
        }

        places = out
        isLoading = false
    }
}
