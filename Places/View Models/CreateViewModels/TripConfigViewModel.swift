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
    var startDate: Date? = nil
    var currency: Currency = .usd
    var useSavedPlaces: Bool = false

    var trimmedExpectation: String {
        expectation.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // `id` is a fresh local identifier, not persisted config data.
    private enum CodingKeys: String, CodingKey {
        case travelers, hasKids, expectation, multipleCountries, durationDays, durationLabel
        case startDate, currency, useSavedPlaces
    }
}

nonisolated extension TripConfig {
    // Tolerant decode so trips saved before startDate/currency/useSavedPlaces still load.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        travelers = try c.decode(Int.self, forKey: .travelers)
        hasKids = try c.decode(Bool.self, forKey: .hasKids)
        expectation = try c.decode(String.self, forKey: .expectation)
        multipleCountries = try c.decode(Bool.self, forKey: .multipleCountries)
        durationDays = try c.decode(Int.self, forKey: .durationDays)
        durationLabel = try c.decode(String.self, forKey: .durationLabel)
        startDate = try c.decodeIfPresent(Date.self, forKey: .startDate)
        currency = try c.decodeIfPresent(Currency.self, forKey: .currency) ?? .usd
        useSavedPlaces = try c.decodeIfPresent(Bool.self, forKey: .useSavedPlaces) ?? false
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
    let totalSteps = 6

    var step = 0

    // Collected config
    var travelers = 2
    var hasKids = false
    var expectation = ""
    var multipleCountries = false
    var durationPreset: DurationPreset = .week
    var customDays = 5
    var startDate: Date = Calendar.current.date(byAdding: .day, value: 14, to: .now) ?? .now
    var currency: Currency = .usd
    var useSavedPlaces = false

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
            durationLabel: durationPreset == .custom ? "\(customDays) day\(customDays == 1 ? "" : "s")" : durationPreset.rawValue,
            startDate: startDate,
            currency: currency,
            useSavedPlaces: useSavedPlaces
        )
    }
}
