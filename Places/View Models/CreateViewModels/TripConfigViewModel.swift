//
//  TripConfigViewModel.swift
//  Places
//
//  Drives the "Plan a New Trip" step form: the collected trip-generation config
//  and the current wizard step. Follows the app's ObservableObject convention.
//

import Foundation
import Observation

/// An immutable snapshot of the collected trip-generation config, handed to
/// `GenerateItineraryView` once the wizard finishes.
nonisolated struct TripConfig: Identifiable, Hashable, Codable {
    let id = UUID()
    var travelers: Int
    var hasKids: Bool
    var expectation: String
    var multipleCountries: Bool
    var durationDays: Int
    var durationLabel: String

    var trimmedExpectation: String {
        expectation.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // `id` is a fresh local identifier, not persisted config data.
    private enum CodingKeys: String, CodingKey {
        case travelers, hasKids, expectation, multipleCountries, durationDays, durationLabel
    }
}

enum DurationPreset: String, CaseIterable, Identifiable {
    case weekend = "Weekend"
    case short = "3–5 days"
    case week = "1 week"
    case long = "2+ weeks"
    case custom = "Custom"

    var id: String { rawValue }

    /// Fixed length in days, or nil for the custom stepper.
    var days: Int? {
        switch self {
        case .weekend: 2
        case .short: 4
        case .week: 7
        case .long: 14
        case .custom: nil
        }
    }
}

@Observable
final class TripConfigViewModel {
    let totalSteps = 5

    var step = 0

    // Collected config
    var travelers = 2
    var hasKids = false
    var expectation = ""
    var multipleCountries = false
    var durationPreset: DurationPreset = .week
    var customDays = 5

    var progress: Double { Double(step + 1) / Double(totalSteps) }
    var isFirstStep: Bool { step == 0 }
    var isLastStep: Bool { step == totalSteps - 1 }

    var durationDays: Int { durationPreset.days ?? customDays }

    func next() {
        guard step < totalSteps - 1 else { return }
        step += 1
    }

    func back() {
        guard step > 0 else { return }
        step -= 1
    }

    func incrementTravelers() { travelers = min(travelers + 1, 20) }
    func decrementTravelers() { travelers = max(travelers - 1, 1) }
    func incrementDays() { customDays = min(customDays + 1, 60) }
    func decrementDays() { customDays = max(customDays - 1, 1) }

    func snapshot() -> TripConfig {
        TripConfig(
            travelers: travelers,
            hasKids: hasKids,
            expectation: expectation,
            multipleCountries: multipleCountries,
            durationDays: durationDays,
            durationLabel: durationPreset == .custom ? "\(customDays) day\(customDays == 1 ? "" : "s")" : durationPreset.rawValue
        )
    }
}
