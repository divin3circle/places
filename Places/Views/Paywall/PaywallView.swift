//
//  PaywallView.swift
//  Places
//
//  Created by Sylus Abel on 11/08/2026.
//
//  The "Unlock Places Pro" paywall. Binds to PurchasesManager (plain SubOption
//  data — no RevenueCat types here), buys the selected plan, and offers a
//  "buy tokens instead" path to the coin shop. Design references (Mobbin):
//  Buddy / Speak / Liven / GoodRx — value hero, feature checklist, selectable
//  plan rows with a best-value badge, one pinned CTA, Restore + legal links.
//

import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PurchasesManager.self) private var purchases: PurchasesManager?
    @Environment(TokenStore.self) private var tokens: TokenStore?

    @State private var selectedId: String?
    @State private var isPurchasing = false
    @State private var errorText: String?
    @State private var showCoins = false

    private let features: [(icon: String, text: String)] = [
        ("infinity", "Unlimited AI itineraries"),
        ("globe.europe.africa.fill", "Plan trips across multiple countries"),
        ("bolt.fill", "500 tokens every month"),
        ("sparkles", "Priority, higher-quality planning"),
        ("bell.slash.fill", "No upsells — ever"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    hero
                    featureCard
                    planList
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
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Restore") { Task { await restore() } }
                        .font(.system(size: 15, design: .rounded))
                        .tint(.secondary)
                }
            }
            .sheet(isPresented: $showCoins) { CoinShopView() }
            .task { ensureSelection() }
            .onChange(of: purchases?.subscriptions.map(\.id) ?? []) { _, _ in ensureSelection() }
        }
    }

    // MARK: Hero

    private var hero: some View {
        VStack(spacing: 10) {
            Image(systemName: "crown.fill")
                .font(.system(size: 38))
                .foregroundStyle(.accent)
            Text("Unlock Places Pro")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .fontWidth(.expanded)
                .multilineTextAlignment(.center)
            Text("Plan smarter, travel further — unlimited itineraries and monthly tokens.")
                .font(.system(size: 15, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: Features

    private var featureCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            ForEach(features, id: \.text) { f in
                HStack(spacing: 12) {
                    Image(systemName: f.icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.accent)
                        .frame(width: 24)
                    Text(f.text)
                        .font(.system(size: 15, design: .rounded))
                    Spacer(minLength: 0)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.accentColor.opacity(0.06), in: .rect(cornerRadius: 20, style: .continuous))
    }

    // MARK: Plans

    private var planList: some View {
        VStack(spacing: 10) {
            let subs = purchases?.subscriptions ?? []
            if subs.isEmpty {
                VStack(spacing: 10) {
                    ProgressView()
                    Text("Loading plans…")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                ForEach(subs) { planRow($0) }
            }
        }
    }

    private func planRow(_ plan: SubOption) -> some View {
        let selected = plan.id == selectedId
        return Button {
            withAnimation(.snappy(duration: 0.15)) { selectedId = plan.id }
        } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(plan.title)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                        if plan.isBestValue {
                            Text("BEST VALUE")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(.accent, in: .capsule)
                        }
                    }
                    Text("\(plan.monthlyTokens) tokens / month")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(.secondary)
                    if let trial = plan.trialLabel {
                        Text(trial)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.green)
                    }
                }
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: 1) {
                    Text(plan.priceString)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                    Text(plan.periodLabel)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(.secondary)
                }
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

    // MARK: CTA

    private var ctaBar: some View {
        VStack(spacing: 12) {
            PrimaryButton(title: ctaTitle) { Task { await purchaseSelected() } }
                .disabled(isPurchasing || selectedId == nil)
                .opacity(selectedId == nil ? 0.6 : 1)
                .overlay { if isPurchasing { ProgressView().tint(.white) } }

            HStack(spacing: 14) {
                Button("Buy tokens instead") { showCoins = true }
                    .foregroundStyle(.accent)
                Text("·").foregroundStyle(.secondary)
                // TODO: swap in your real Terms / Privacy URLs before submission.
                Link("Terms", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                    .foregroundStyle(.secondary)
                Link("Privacy", destination: URL(string: "https://places.app/privacy")!)
                    .foregroundStyle(.secondary)
            }
            .font(.system(size: 12, design: .rounded))
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(.bar)
    }

    private var ctaTitle: String {
        guard let id = selectedId,
              let plan = purchases?.subscriptions.first(where: { $0.id == id }) else { return "Continue" }
        if let trial = plan.trialLabel { return "Start \(trial)" }
        return plan.id == "$rc_lifetime" ? "Unlock Lifetime" : "Start \(plan.title)"
    }

    // MARK: Actions

    private func ensureSelection() {
        guard selectedId == nil, let subs = purchases?.subscriptions, !subs.isEmpty else { return }
        selectedId = subs.first(where: \.isBestValue)?.id ?? subs.first?.id
    }

    private func purchaseSelected() async {
        guard let purchases, let id = selectedId else { return }
        errorText = nil
        isPurchasing = true
        defer { isPurchasing = false }
        let previous = tokens?.balance ?? 0
        switch await purchases.purchase(id: id) {
        case .success:
            await tokens?.awaitCredit(above: previous)   // wait for the webhook's token grant
            dismiss()
        case .cancelled:
            break
        case .failed(let msg):
            errorText = msg
        }
    }

    private func restore() async {
        guard let purchases else { return }
        if await purchases.restore() { dismiss() }
        else { errorText = "No purchases found to restore." }
    }
}

#Preview {
    PaywallView()
}
