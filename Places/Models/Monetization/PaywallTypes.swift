//
//  PaywallTypes.swift
//  Places
//
//  Plain, RevenueCat-free data the paywall / coin-shop UI binds to. The UI reads
//  `PurchasesManager.subscriptions` / `.coinPacks` and buys via
//  `PurchasesManager.purchase(id:)` — it never touches RevenueCat types directly.
//

import Foundation

/// A subscription choice on the paywall.
nonisolated struct SubOption: Identifiable, Hashable {
    let id: String            // RevenueCat package identifier ($rc_weekly, $rc_annual…)
    let title: String         // "Weekly", "Annual"
    let priceString: String   // localized, from the store (e.g. "$14.99")
    let periodLabel: String   // "/week", "/year", "one-time"
    let monthlyTokens: Int    // tokens granted per month (50 / 500 / 500 / 1000)
    let isBestValue: Bool
}

/// A consumable token pack on the coin shop.
nonisolated struct CoinPack: Identifiable, Hashable {
    let id: String            // RevenueCat package identifier ($rc_custom_tokens_25…)
    let tokens: Int           // 25 / 75 / 200 / 500
    let priceString: String   // localized
}

/// Result of a purchase attempt, surfaced to the UI.
nonisolated enum PurchaseOutcome: Equatable {
    case success
    case cancelled
    case failed(String)
}
