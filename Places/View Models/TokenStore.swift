//
//  TokenStore.swift
//  Places
//
//  The app-side view of the Supabase-authoritative token balance. Reads the
//  current user's `token_balances.balance`, spends via the `spend_my_tokens`
//  RPC (client-initiated actions: on-device generation, Border Pass), and can
//  wait for the balance to rise after a purchase (the RevenueCat webhook credits
//  Supabase asynchronously). Cloud generation is debited server-side, so it is
//  NOT spent here — only refreshed afterwards.
//

import Foundation
import Observation
import Supabase

@MainActor
@Observable
final class TokenStore {
    /// Current spendable balance; nil until first load / signed out.
    private(set) var balance: Int?
    private(set) var isRefreshing = false

    private struct BalanceRow: Decodable { let balance: Int }
    private struct SpendParams: Encodable {
        let p_cost: Int
        let p_reason: String
        let p_ref: String?
    }

    /// Reload the balance for the signed-in user. RLS restricts `token_balances`
    /// to the caller's own row, so no explicit filter is needed. Missing row
    /// (brand-new user before the signup grant lands) is treated as 0, not an error.
    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            let row: BalanceRow = try await SupabaseService.client
                .from("token_balances")
                .select("balance")
                .single()
                .execute()
                .value
            balance = row.balance
        } catch {
            balance = balance ?? 0
        }
    }

    /// Spend tokens for a client-initiated action. Returns true on success.
    /// (Reasons: `spend_gen`/`spend_iter` for on-device, `spend_border`,
    /// `spend_offline`.) Refreshes the balance either way.
    @discardableResult
    func spend(_ cost: Int, reason: String, ref: String? = nil) async -> Bool {
        do {
            try await SupabaseService.client
                .rpc("spend_my_tokens", params: SpendParams(p_cost: cost, p_reason: reason, p_ref: ref))
                .execute()
            await refresh()
            return true
        } catch {
            // insufficient_tokens (P0001) or any failure → not spent.
            await refresh()
            return false
        }
    }

    /// After a token-pack purchase, poll until the webhook-credited balance rises
    /// above `previous` (or the timeout elapses). Keeps the UI honest despite the
    /// server-to-server webhook lag.
    func awaitCredit(above previous: Int, timeoutSeconds: Int = 10) async {
        for _ in 0..<timeoutSeconds {
            await refresh()
            if let b = balance, b > previous { return }
            try? await Task.sleep(for: .seconds(1))
        }
    }

    func clear() { balance = nil }
}
