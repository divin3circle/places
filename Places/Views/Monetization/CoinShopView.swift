//
//  CoinShopView.swift
//  Places
//
//  ⚠️ STYLING IS A PLACEHOLDER — this is a functional stub for you to restyle.
//  The value here is the WIRING: it binds to `PurchasesManager.coinPacks` (plain
//  data, no RevenueCat types), buys via `PurchasesManager.purchase(id:)`, and
//  waits for the webhook to credit the balance via `TokenStore.awaitCredit`.
//  Presented from the Home-header coin button (see HomeHeader.swift).
//

import SwiftUI

struct CoinShopView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PurchasesManager.self) private var purchases: PurchasesManager?
    @Environment(TokenStore.self) private var tokens: TokenStore?

    @State private var buyingId: String?
    @State private var errorText: String?

    var body: some View {
        NavigationStack {
            List {
                Section("Your balance") {
                    Text("\(tokens?.balance ?? 0) tokens")
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                }
                Section("Buy tokens") {
                    let packs = purchases?.coinPacks ?? []
                    if packs.isEmpty {
                        Text("Loading…").foregroundStyle(.secondary)
                    }
                    ForEach(packs) { pack in
                        Button { Task { await buy(pack) } } label: {
                            HStack {
                                Text("\(pack.tokens) tokens")
                                Spacer()
                                if buyingId == pack.id {
                                    ProgressView()
                                } else {
                                    Text(pack.priceString).foregroundStyle(.secondary)
                                }
                            }
                        }
                        .disabled(buyingId != nil)
                    }
                }
                if let errorText {
                    Text(errorText).foregroundStyle(.red).font(.footnote)
                }
            }
            .navigationTitle("Get Tokens")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
            .task { await tokens?.refresh() }
        }
    }

    private func buy(_ pack: CoinPack) async {
        guard let purchases, let tokens else { return }
        errorText = nil
        buyingId = pack.id
        defer { buyingId = nil }
        let previous = tokens.balance ?? 0
        switch await purchases.purchase(id: pack.id) {
        case .success:
            await tokens.awaitCredit(above: previous)   // webhook credits Supabase async
            dismiss()
        case .cancelled:
            break
        case .failed(let msg):
            errorText = msg
        }
    }
}
