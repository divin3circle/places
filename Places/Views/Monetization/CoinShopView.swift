//
//  CoinShopView.swift
//  Places
//
//  The "Get Tokens" shop. Binds to `PurchasesManager.coinPacks` (plain data, no
//  RevenueCat types), buys via `PurchasesManager.purchase(id:)`, and waits for
//  the webhook to credit the Supabase balance via `TokenStore.awaitCredit`.
//  Presented from the Home-header coin chip and the paywall's "buy tokens" path.
//  Visual language matches PaywallView (hero → selectable cards → one pinned CTA).
//

import SwiftUI

struct CoinShopView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PurchasesManager.self) private var purchases: PurchasesManager?
    @Environment(TokenStore.self) private var tokens: TokenStore?

    @State private var selectedId: String?
    @State private var isPurchasing = false
    @State private var errorText: String?

    private var packs: [CoinPack] { purchases?.coinPacks ?? [] }
    /// Most-tokens pack gets the BEST VALUE flag (packs are priced to scale).
    private var bestValueId: String? { packs.max(by: { $0.tokens < $1.tokens })?.id }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    hero
                    packList
                    usageNote
                    if let errorText {
                        Text(errorText)
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(20)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .safeAreaInset(edge: .bottom) { ctaBar }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").font(.system(size: 15, weight: .semibold))
                    }
                    .tint(.secondary)
                }
            }
            .task {
                await tokens?.refresh()
                ensureSelection()
            }
            .onChange(of: packs.map(\.id)) { _, _ in ensureSelection() }
        }
    }

    // MARK: Hero

    private var hero: some View {
        VStack(spacing: 12) {
            Image("TokenCoin")
                .resizable()
                .scaledToFit()
                .frame(width: 68, height: 68)
                .shadow(color: .black.opacity(0.15), radius: 8, y: 3)
            Text("Get Tokens")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .fontWidth(.expanded)
            HStack(spacing: 6) {
                Image("TokenCoin").resizable().scaledToFit().frame(width: 18, height: 18)
                Text("\(tokens?.balance ?? 0) available")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .contentTransition(.numericText())
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(Color(.secondarySystemBackground), in: .capsule)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: Packs

    private var packList: some View {
        VStack(spacing: 10) {
            if packs.isEmpty {
                VStack(spacing: 10) {
                    ProgressView()
                    Text("Loading packs…")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                ForEach(packs) { packRow($0) }
            }
        }
    }

    private func packRow(_ pack: CoinPack) -> some View {
        let selected = pack.id == selectedId
        return Button {
            withAnimation(.snappy(duration: 0.15)) { selectedId = pack.id }
        } label: {
            HStack(spacing: 14) {
                Image("TokenCoin").resizable().scaledToFit().frame(width: 34, height: 34)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("\(pack.tokens) tokens")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                        if pack.id == bestValueId {
                            Text("BEST VALUE")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(.accent, in: .capsule)
                        }
                    }
                    Text("One-time top-up")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Text(pack.priceString)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(selected ? Color.accentColor : Color.primary.opacity(0.25))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(selected ? Color.accentColor : Color.primary.opacity(0.1),
                            lineWidth: selected ? 2 : 1)
            )
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    private var usageNote: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 24)
            Text("Tokens power AI itineraries (~5–8 each) and multi-country Border Passes (15). Go Pro for a monthly refill.")
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 18, style: .continuous))
    }

    // MARK: CTA

    private var ctaBar: some View {
        VStack(spacing: 8) {
            PrimaryButton(title: ctaTitle) { Task { await purchaseSelected() } }
                .disabled(isPurchasing || selectedId == nil)
                .opacity(selectedId == nil ? 0.6 : 1)
                .overlay { if isPurchasing { ProgressView().tint(.white) } }
            Text("Charged to your App Store account. Tokens are non-refundable.")
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(.bar)
    }

    private var ctaTitle: String {
        guard let id = selectedId, let pack = packs.first(where: { $0.id == id }) else { return "Select a pack" }
        return "Buy \(pack.tokens) tokens"
    }

    // MARK: Actions

    private func ensureSelection() {
        guard selectedId == nil, !packs.isEmpty else { return }
        selectedId = bestValueId ?? packs.first?.id
    }

    private func purchaseSelected() async {
        guard let purchases, let tokens, let id = selectedId,
              let pack = packs.first(where: { $0.id == id }) else { return }
        errorText = nil
        isPurchasing = true
        defer { isPurchasing = false }
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

#Preview {
    CoinShopView()
}
