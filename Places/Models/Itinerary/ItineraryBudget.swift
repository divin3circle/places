//
//  ItineraryBudget.swift
//  Places
//
//  Currency + budget totals for an itinerary. Totals are computed in Swift from
//  the per-activity price estimates — the model never does the arithmetic. FX is a
//  single static rate for now (swap for a rate API later).
//

import Foundation

nonisolated enum Currency: String, Codable, CaseIterable {
    case usd = "USD"
    case kes = "KES"

    var symbol: String { self == .usd ? "$" : "KSh" }
    var label: String { self == .usd ? "USD" : "KSh" }

    /// Static FX. 1 USD ≈ 130 KES.
    static let usdToKes: Double = 130

    /// Convert a money estimate into this currency.
    func amount(_ money: MoneyEstimate) -> Double {
        let from = Currency(rawValue: money.currency.uppercased()) ?? .usd
        if from == self { return money.amount }
        return self == .kes ? money.amount * Currency.usdToKes
                            : money.amount / Currency.usdToKes
    }

    /// Format a value in this currency (no decimals for these ranges).
    func format(_ value: Double) -> String {
        let rounded = Int(value.rounded())
        switch self {
        case .usd: return "$\(rounded.formatted(.number.grouping(.automatic)))"
        case .kes: return "KSh \(rounded.formatted(.number.grouping(.automatic)))"
        }
    }
}

extension ItineraryActivity {
    func displayPrice(in currency: Currency) -> String? {
        guard let price else { return nil }
        let value = currency.amount(price)
        return value <= 0 ? "Free" : currency.format(value)
    }
}

extension ItineraryDay {
    /// Sum of this day's priced activities in the given currency (nil if none priced).
    func estimatedTotal(in currency: Currency) -> Double? {
        let priced = activities.compactMap(\.price)
        guard !priced.isEmpty else { return nil }
        return priced.reduce(0) { $0 + currency.amount($1) }
    }
}

extension GeneratedItinerary {
    /// Trip total in the given currency (nil if nothing is priced).
    func estimatedTotal(in currency: Currency) -> Double? {
        let totals = days.compactMap { $0.estimatedTotal(in: currency) }
        guard !totals.isEmpty else { return nil }
        return totals.reduce(0, +)
    }

    /// Replace each activity's price with the grounded DB price (USD) when the
    /// place is known; leaves the model's estimate otherwise. Pure.
    func withGroundedPrices(_ priceUSD: (String) -> Double?) -> GeneratedItinerary {
        var copy = self
        copy.days = days.map { day in
            var d = day
            d.activities = day.activities.map { activity in
                guard let usd = priceUSD(activity.placeName) else { return activity }
                var a = activity
                a.price = MoneyEstimate(amount: usd, currency: "USD")
                return a
            }
            return d
        }
        return copy
    }
}
