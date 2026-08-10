//
//  AIModelKind.swift
//  Places
//
//  Which backend generates itineraries. Persisted in @AppStorage (empty until
//  the user picks the first time), and editable in Profile settings. Mirrors the
//  AppearanceMode preference pattern.
//

import Foundation

/// Shared @AppStorage key(s) for AI preferences, so a rename can't silently miss a site.
enum AIPreferenceKey {
    static let model = "aiModelKind"
}

enum AIModelKind: String, CaseIterable, Identifiable {
    case onDevice
    case cloud

    var id: String { rawValue }

    var title: String {
        switch self {
        case .onDevice: "On-device"
        case .cloud: "Cloud"
        }
    }

    var subtitle: String {
        switch self {
        case .onDevice: "Private and offline, powered by Apple Intelligence."
        case .cloud: "More capable, needs a connection."
        }
    }

    var icon: String {
        switch self {
        case .onDevice: "iphone"
        case .cloud: "cloud"
        }
    }
}
