//
//  GenerateItineraryView.swift
//  Places
//
//  The itinerary chat screen. On appear it streams a structured itinerary from
//  the selected engine (config → system prompt), rendered as a rich assistant
//  message; the user can then chat to refine it. The input bar is hidden while
//  the model is generating. (Model picker + persistence land in later milestones.)
//

import SwiftUI
import SwiftData
// Scoped import: RiveRuntime also vends a `Color` type, which would make bare
// `Color` ambiguous against SwiftUI's.
import class RiveRuntime.RiveViewModel

struct GenerateItineraryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(TokenStore.self) private var tokens: TokenStore?
    @Environment(PurchasesManager.self) private var purchases: PurchasesManager?
    @Query private var savedPlaces: [SavedPlace]
    @Query(sort: \SavedTrip.createdAt, order: .reverse) private var savedTrips: [SavedTrip]
    let config: TripConfig

    @State private var vm: ItineraryChatViewModel
    @State private var draft = ""
    @State private var showModelPicker = false
    @State private var showPaywall = false
    // Border Pass is charged once per trip. Resumed trips already paid at first generation.
    @State private var borderPassCharged = false
    @State private var showSavedToast = false
    // Created once — never re-instantiate the Rive runtime on body re-renders.
    @State private var riveVM = RiveViewModel(fileName: "shapes")
    @FocusState private var isFocused: Bool

    @AppStorage(AIPreferenceKey.model) private var aiModelRaw = ""

    init(config: TripConfig) {
        self.config = config
        _vm = State(initialValue: ItineraryChatViewModel(config: config))
    }

    /// Resume an existing saved trip for editing (seeds the chat with its plan).
    init(trip: SavedTrip) {
        self.config = trip.config ?? TripConfig(
            travelers: 2, hasKids: false, expectation: "",
            multipleCountries: false, durationDays: 3, durationLabel: "")
        _vm = State(initialValue: ItineraryChatViewModel(resuming: trip))
        _borderPassCharged = State(initialValue: true)
    }

    private let bottomAnchor = "chat-bottom"

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.25)) {
            proxy.scrollTo(bottomAnchor, anchor: .bottom)
        }
    }

    private func submit() {
        let message = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }
        draft = ""
        isFocused = false
        vm.send(message)
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(vm.items) { item in
                            chatRow(item)
                        }
                        // Anchor the auto-scroll target after the last message.
                        Color.clear.frame(height: 1).id(bottomAnchor)
                    }
                    .padding(16)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
                .defaultScrollAnchor(.bottom)
                // Tap anywhere in the chat to dismiss the keyboard.
                .onTapGesture { isFocused = false }
                // Follow the latest message on new turns and when generation ends.
                .onChange(of: vm.items.count) { _, _ in scrollToBottom(proxy) }
                .onChange(of: vm.isGenerating) { _, _ in scrollToBottom(proxy) }
            }
        }
        .background(background)
        // The composer as a bottom safe-area inset — keyboard- and safe-area-aware,
        // so content reflows instead of scrolling off-screen when the keyboard hides.
        .safeAreaInset(edge: .bottom) { footer }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            // First run: let the user pick a model; after that, start immediately.
            if aiModelRaw.isEmpty {
                showModelPicker = true
            } else {
                startGeneration()
            }
        }
        .sheet(isPresented: $showModelPicker) {
            ModelPickerSheet(onDone: { startGeneration() })
        }
        // Out of tokens → offer a top-up (user's coin shop). Dismissing it in any
        // way — closed, cancelled, or purchased — returns to Home.
        .sheet(isPresented: Binding(get: { vm.paymentRequired },
                                    set: { vm.paymentRequired = $0 }),
               onDismiss: { dismiss() }) {
            CoinShopView()
        }
        // Pro-only wall (e.g. hit the free saved-trips cap, or a Pro-only trip).
        .sheet(isPresented: $showPaywall,
               onDismiss: { if vm.items.isEmpty { dismiss() } }) {
            PaywallView()
        }
        // Keep the Home-header balance honest after each generation (server debit).
        .onChange(of: vm.isGenerating) { _, generating in
            if !generating { Task { await tokens?.refresh() } }
        }
        .overlay(alignment: .top) { saveToast }
        .onChange(of: vm.savedTripID) { _, newValue in
            guard newValue != nil else { return }
            withAnimation(.snappy) { showSavedToast = true }
            Task {
                try? await Task.sleep(for: .seconds(2))
                withAnimation(.snappy) { showSavedToast = false }
            }
        }
        .onDisappear { vm.stop() }
    }

    // MARK: Convert-to-trip toast

    @ViewBuilder
    private var saveToast: some View {
        if vm.isSaving || showSavedToast {
            HStack(spacing: 8) {
                if vm.isSaving {
                    ProgressView().controlSize(.small)
                    Text("Saving your trip…")
                } else {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    Text("Saved to My Trips")
                }
            }
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.regularMaterial, in: .capsule)
            .overlay(Capsule().stroke(.primary.opacity(0.06)))
            .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
            .padding(.top, 8)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    private func convertToTrip() {
        // Free users are capped; a NEW save beyond the limit shows the paywall.
        if vm.savedTripID == nil, !(purchases?.isPro ?? false), savedTrips.count >= FreeLimits.savedTrips {
            showPaywall = true
            return
        }
        Task { await vm.saveAsTrip(context: modelContext) }
    }

    private func startGeneration() {
        Task { await startGenerationGated() }
    }

    /// Pro: reorder each day by proximity to cut backtracking (free → paywall).
    private func optimizeDay() {
        guard purchases?.isPro == true else { showPaywall = true; return }
        vm.optimizeDays()
    }

    private func startGenerationGated() async {
        if config.useSavedPlaces {
            vm.preferredPlaceNames = savedPlaces.map(\.name)
        }
        // Longer trips are a Pro perk.
        if !(purchases?.isPro ?? false), config.durationDays > FreeLimits.tripDays {
            showPaywall = true
            return
        }
        // Border Pass: multi-country is a Pro perk; free users pay once per trip.
        if config.multipleCountries, !(purchases?.isPro ?? false), !borderPassCharged {
            let paid = await tokens?.spend(FreeLimits.borderPassTokens, reason: "spend_border") ?? false
            if !paid { vm.paymentRequired = true; return }   // insufficient → coin shop
            borderPassCharged = true
        }
        let kind = AIModelKind(rawValue: aiModelRaw) ?? .onDevice
        vm.start(kind: kind)
    }

    // MARK: Chat rows

    @ViewBuilder
    private func chatRow(_ item: ItineraryChatItem) -> some View {
        switch item.role {
        case .user:
            if case .text(let text) = item.kind {
                HStack {
                    Spacer(minLength: 40)
                    Text(text)
                        .font(.system(size: 16, design: .rounded))
                        .foregroundStyle(Color(.systemBackground))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.primary, in: .rect(cornerRadius: 20, style: .continuous))
                }
            }
        case .assistant:
            switch item.kind {
            case .text(let text):
                if text.isEmpty {
                    typingIndicator
                } else {
                    Text(LocalizedStringKey(text))
                        .font(.system(size: 16, design: .rounded))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            case .itinerary(let partial):
                if let partial {
                    ItineraryMessageView(itinerary: partial, registry: vm.registry)
                } else {
                    planningPlaceholder
                }
            }
        }
    }

    private var typingIndicator: some View {
        HStack(spacing: 6) {
            ProgressView().controlSize(.small)
            Text("Thinking…")
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }

    private var planningPlaceholder: some View {
        HStack(spacing: 10) {
            ProgressView().controlSize(.small)
            Text("Planning your itinerary…")
                .font(.system(size: 15, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.thinMaterial, in: .rect(cornerRadius: 18, style: .continuous))
    }

    // MARK: Footer — input bar is hidden entirely while generating

    @ViewBuilder
    private var footer: some View {
        if !vm.isGenerating {
            composerBar
        }
    }

    // MARK: Header

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
                    .background(Color(.secondarySystemBackground), in: .circle)
            }
            .buttonStyle(PressableButtonStyle())

            Spacer()

            Menu {
                Button {
                    convertToTrip()
                } label: {
                    Label(vm.savedTripID != nil ? "Saved to My Trips" : "Convert to trip",
                          systemImage: vm.savedTripID != nil ? "checkmark.circle" : "suitcase.fill")
                }
                .disabled(!vm.canSave || vm.isSaving)

                Button {
                    optimizeDay()
                } label: {
                    Label("Optimize day", systemImage: "wand.and.stars")
                }
                .disabled(vm.isGenerating)
                Divider()
                Button(role: .destructive) {
                    
                } label: { Label("Delete", systemImage: "trash") }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 44, height: 44)
            }
            .foregroundStyle(.primary)
            .background(Color(.secondarySystemBackground), in: .capsule)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private var background: some View {
        riveVM.view()
            .ignoresSafeArea()
            .blur(radius: 30)
            .background(
                Image("Spline")
                    .blur(radius: 20)
                    .offset(x: 200, y: 100)
            )
    }

    // MARK: Composer — reuses the shared AnimatedBottomBar

    private var composerBar: some View {
        let fillColor = Color.gray.opacity(0.15)
        return AnimatedBottomBar(hint: "Ask for changes…", text: $draft, isFocused: $isFocused) {
            Button { } label: {
                Image(systemName: "plus")
                    .fontWeight(.medium)
                    .foregroundStyle(Color.primary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(fillColor, in: .circle)
            }
            Button { } label: {
                Image(systemName: "magnifyingglass")
                    .fontWeight(.medium)
                    .foregroundStyle(Color.primary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(fillColor, in: .circle)
            }
            Button { } label: {
                Image(systemName: "mic.fill")
                    .fontWeight(.medium)
                    .foregroundStyle(Color.primary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(fillColor, in: .circle)
            }
        } trailingAction: {
            Button { submit() } label: {
                ZStack {
                    Image(systemName: "arrow.up")
                        .fontWeight(.bold)
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.green.gradient, in: .circle)
                        .blur(radius: isFocused ? 0 : 5)
                        .opacity(isFocused ? 1 : 0)

                    Image(systemName: "mic.fill")
                        .foregroundStyle(Color.primary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(fillColor, in: .circle)
                        .blur(radius: !isFocused ? 0 : 5)
                        .opacity(!isFocused ? 1 : 0)
                }
            }
        } mainAction: {
            Button { submit() } label: {
                Image(systemName: "paperplane.fill")
                    .fontWeight(.medium)
                    .foregroundStyle(Color.primary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(fillColor, in: .circle)
            }
        }
        .padding(.horizontal, 15)
        // No bottom gap while the keyboard is up (sit right above it); a little
        // breathing room above the home indicator otherwise.
        .padding(.bottom, isFocused ? 0 : 8)
    }
}

#Preview {
    GenerateItineraryView(config: TripConfig(
        travelers: 2, hasKids: true, expectation: "A relaxed safari with great food",
        multipleCountries: false, durationDays: 5, durationLabel: "3–5 days"
    ))
}
