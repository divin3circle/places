//
//  PurchasesManager.swift
//  Places
//
//  The app's single seam onto RevenueCat. Owns SDK configuration, identity
//  linking (RevenueCat customer == Supabase user id, so the server webhook
//  credits the right account), the current offering mapped to plain display
//  types, purchase/restore, and the live `pro` entitlement.
//
//  Requires the `RevenueCat` SPM package (add in Xcode: File → Add Packages →
//  https://github.com/RevenueCat/purchases-ios ; product "RevenueCat").
//

import Foundation
import Observation
import RevenueCat

@MainActor
@Observable
final class PurchasesManager {
    /// Public (client-embeddable) RevenueCat SDK key for the App Store app.
    private static let apiKey = "appl_zSXhKsCLkDOxPGQsXbWJoMFmzyG"
    private static let proEntitlement = "pro"

    /// Live Pro access (from the RevenueCat `pro` entitlement) — gate features on this.
    private(set) var isPro = false
    /// Subscriptions to render on the paywall (weekly → lifetime).
    private(set) var subscriptions: [SubOption] = []
    /// Consumable token packs to render on the coin shop (smallest → largest).
    private(set) var coinPacks: [CoinPack] = []
    private(set) var isLoadingOfferings = false

    /// packageId → RevenueCat package, so `purchase(id:)` can resolve without
    /// leaking RevenueCat types to the UI.
    private var packages: [String: Package] = [:]
    private var customerInfoTask: Task<Void, Never>?

    // MARK: - Lifecycle

    /// Configure the SDK once, at app launch (before `logIn`).
    func configure() {
        guard !Purchases.isConfigured else { return }
        Purchases.logLevel = .warn
        Purchases.configure(withAPIKey: Self.apiKey)
    }

    /// Link the RevenueCat customer to our Supabase user id, then load entitlement
    /// + offering. Call after the profile is known. `userId` MUST be the Supabase
    /// user id (the webhook keys grants on it).
    func logIn(userId: String) async {
        if let result = try? await Purchases.shared.logIn(userId) {
            updateEntitlement(result.customerInfo)
        }
        await refreshOfferings()
        startCustomerInfoStream()
    }

    /// Reset RevenueCat identity on sign-out.
    func logOut() async {
        _ = try? await Purchases.shared.logOut()
        isPro = false
    }

    // MARK: - Purchases

    /// Buy a subscription or token pack by its display id (the package identifier).
    func purchase(id: String) async -> PurchaseOutcome {
        guard let package = packages[id] else { return .failed("This product isn't available right now.") }
        do {
            let result = try await Purchases.shared.purchase(package: package)
            if result.userCancelled { return .cancelled }
            updateEntitlement(result.customerInfo)
            return .success
        } catch {
            return .failed(error.localizedDescription)
        }
    }

    /// Restore prior purchases (required by App Review for subs/non-consumables).
    @discardableResult
    func restore() async -> Bool {
        guard let info = try? await Purchases.shared.restorePurchases() else { return false }
        updateEntitlement(info)
        return isPro
    }

    // MARK: - Internals

    private func refreshOfferings() async {
        isLoadingOfferings = true
        defer { isLoadingOfferings = false }
        guard let current = try? await Purchases.shared.offerings().current else { return }

        var subs: [SubOption] = []
        var coins: [CoinPack] = []
        var map: [String: Package] = [:]
        for pkg in current.availablePackages {
            map[pkg.identifier] = pkg
            let price = pkg.storeProduct.localizedPriceString
            if let meta = Self.subMeta[pkg.identifier] {
                subs.append(SubOption(id: pkg.identifier, title: meta.title,
                                      priceString: price, periodLabel: meta.period,
                                      monthlyTokens: meta.tokens, isBestValue: meta.best,
                                      trialLabel: Self.trialLabel(pkg.storeProduct)))
            } else if let tokens = Self.coinTokens[pkg.identifier] {
                coins.append(CoinPack(id: pkg.identifier, tokens: tokens, priceString: price))
            }
        }
        packages = map
        subscriptions = subs.sorted { Self.subOrder($0.id) < Self.subOrder($1.id) }
        coinPacks = coins.sorted { $0.tokens < $1.tokens }
    }

    private func startCustomerInfoStream() {
        customerInfoTask?.cancel()
        customerInfoTask = Task { [weak self] in
            for await info in Purchases.shared.customerInfoStream {
                self?.updateEntitlement(info)
            }
        }
    }

    private func updateEntitlement(_ info: CustomerInfo) {
        isPro = info.entitlements[Self.proEntitlement]?.isActive == true
    }

    // Display metadata keyed by RevenueCat package identifier (tokens mirror the
    // TOK grant rules; annual grants 6000/yr ≈ 500/mo).
    private static let subMeta: [String: (title: String, period: String, tokens: Int, best: Bool)] = [
        "$rc_weekly":   ("Weekly",   "/week",    50,   false),
        "$rc_monthly":  ("Monthly",  "/month",   500,  false),
        "$rc_annual":   ("Annual",   "/year",    500,  true),
        "$rc_lifetime": ("Lifetime", "one-time", 1000, false),
    ]
    private static let coinTokens: [String: Int] = [
        "$rc_custom_tokens_25": 25, "$rc_custom_tokens_75": 75,
        "$rc_custom_tokens_200": 200, "$rc_custom_tokens_500": 500,
    ]
    private static func subOrder(_ id: String) -> Int {
        ["$rc_weekly": 0, "$rc_monthly": 1, "$rc_annual": 2, "$rc_lifetime": 3][id] ?? 99
    }

    /// A short "N-day free trial" label from the product's intro offer, or nil.
    /// Reads Apple's StoreKit offer via RevenueCat — no hardcoded copy.
    private static func trialLabel(_ product: StoreProduct) -> String? {
        guard let intro = product.introductoryDiscount, intro.paymentMode == .freeTrial else { return nil }
        let period = intro.subscriptionPeriod
        let unit: String
        switch period.unit {
        case .day: unit = "day"
        case .week: unit = "week"
        case .month: unit = "month"
        case .year: unit = "year"
        @unknown default: unit = "day"
        }
        return "\(period.value)-\(unit) free trial"
    }
}
