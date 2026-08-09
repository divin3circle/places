//
//  ForYouItem.swift
//  Places
//
//  Unifies the two content kinds behind one card for the personalized For You row.
//

import Foundation

nonisolated enum ForYouItem: Identifiable {
    case destination(DestinationDTO)
    case experience(ExperienceDTO)

    var id: String {
        switch self {
        case .destination(let d): "d-\(d.id)"
        case .experience(let e): "e-\(e.id.uuidString)"
        }
    }
    var imageURL: String {
        switch self {
        case .destination(let d): d.bannerUrl
        case .experience(let e): e.images.first ?? ""
        }
    }
    var title: String {
        switch self {
        case .destination(let d): d.name
        case .experience(let e): e.title
        }
    }
    var subtitle: String {
        switch self {
        case .destination(let d): d.subtitleLabel
        case .experience(let e):
            "\(e.categoryLabel) · KSh \(e.pricePerGuest.formatted(.number.grouping(.automatic)))"
        }
    }
}

/// Alternates destination, experience, destination, … then appends leftovers, capped.
nonisolated func interleaveForYou(destinations: [DestinationDTO], experiences: [ExperienceDTO], cap: Int) -> [ForYouItem] {
    var out: [ForYouItem] = []
    var di = destinations.makeIterator()
    var ei = experiences.makeIterator()
    var d = di.next()
    var e = ei.next()
    while d != nil || e != nil {
        if let dd = d { out.append(.destination(dd)); d = di.next() }
        if let ee = e { out.append(.experience(ee)); e = ei.next() }
    }
    return Array(out.prefix(cap))
}
