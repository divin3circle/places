//
//  CreateTripForm.swift
//  Places
//
//  The "Plan a New Trip" step form shown after tapping Start planning. One field
//  per step (people → kids → expectation → countries → duration); each step's
//  pieces slide in via the shared `microAnimations` modifier.
//

import SwiftUI
import SwiftData

struct CreateTripForm: View {
    @Bindable var vm: TripConfigViewModel
    var onBackToPitch: () -> Void
    var onFinish: () -> Void

    @AppStorage(AIPreferenceKey.model) private var aiModelRaw = ""
    @Query private var savedPlaces: [SavedPlace]
    @Environment(PurchasesManager.self) private var purchases: PurchasesManager?
    @Environment(TokenStore.self) private var tokens: TokenStore?

    var body: some View {
        VStack(spacing: 20) {
            progressBar


            currentStep
                .id(vm.step)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            navButtons
        }
        .padding(20)
        // Warm the on-device model while the user fills the form, so the first
        // generation starts faster. Runs once, off the render path, and only when
        // on-device is the active backend (no-op if the model is unavailable).
        .task {
            let kind = AIModelKind(rawValue: aiModelRaw) ?? .onDevice
            if kind == .onDevice {
                ItineraryEngineFactory.prewarmOnDevice()
            }
        }
        // Fresh balance so the Border Pass affordability check is accurate.
        .task { await tokens?.refresh() }
    }

    private var progressBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Color(.systemGray5))
                Capsule().fill(Color.primary)
                    .frame(width: max(0, proxy.size.width * vm.progress))
            }
        }
        .frame(height: 5)
        .animation(.snappy, value: vm.progress)
    }

    @ViewBuilder
    private var currentStep: some View {
        switch vm.step {
        case 0: peopleStep
        case 1: kidsStep
        case 2: expectationStep
        case 3: countriesStep
        case 4: durationStep
        default: preferencesStep
        }
    }

    // MARK: Steps

    private var peopleStep: some View {
        stepScaffold(icon: "person.2.fill", title: "How many travelers?", subtitle: "Including you.") {
            stepper(value: vm.travelers, unit: vm.travelers == 1 ? "traveler" : "travelers",
                    onMinus: vm.decrementTravelers, onPlus: vm.incrementTravelers)
        }
    }

    private var kidsStep: some View {
        stepScaffold(icon: "figure.and.child.holdinghands", title: "Traveling with kids?", subtitle: "We'll tailor family-friendly stops.") {
            yesNo(isYes: vm.hasKids) { vm.hasKids = $0 }
        }
    }

    private var expectationStep: some View {
        stepScaffold(icon: "sparkles", title: "In one sentence, what are you hoping for?", subtitle: "Optional — the more you share, the better.") {
            TextField("e.g. A relaxed safari with great food", text: $vm.expectation, axis: .vertical)
                .font(.system(size: 16, design: .rounded))
                .lineLimit(2...4)
                .padding(14)
                .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 16))
        }
    }

    private var countriesStep: some View {
        stepScaffold(icon: "globe.americas.fill", title: "Visiting multiple countries?", subtitle: "Cross-border routes take more planning.") {
            yesNo(isYes: vm.multipleCountries) { vm.multipleCountries = $0 }
        }
    }

    private var durationStep: some View {
        stepScaffold(icon: "calendar", title: "How long is the trip?", subtitle: nil) {
            VStack(spacing: 14) {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(DurationPreset.allCases) { preset in
                            FilterPill(label: preset.rawValue, isSelected: vm.durationPreset == preset) {
                                withAnimation(.snappy) { vm.durationPreset = preset }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .scrollIndicators(.hidden)
                // Bleed past the form's 20pt padding so pills run edge-to-edge.
                .padding(.horizontal, -20)

                if vm.durationPreset == .custom {
                    stepper(value: vm.customDays, unit: vm.customDays == 1 ? "day" : "days",
                            onMinus: vm.decrementDays, onPlus: vm.incrementDays)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }

    private var preferencesStep: some View {
        stepScaffold(icon: "slider.horizontal.3", title: "A few preferences", subtitle: "Fine-tune the plan.") {
            VStack(alignment: .leading, spacing: 34) {
                HStack(spacing: 12) {
                    Image(systemName: "calendar")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text("Start date")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                    Spacer()
                    DatePicker("", selection: $vm.startDate, in: Date.now..., displayedComponents: .date)
                        .labelsHidden()
                        .datePickerStyle(.compact)
                }
                .padding(14)
                .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Budget currency")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                    HStack(spacing: 10) {
                        choicePill("USD $", selected: vm.currency == .usd) { withAnimation(.snappy) { vm.currency = .usd } }
                        choicePill("KSh", selected: vm.currency == .kes) { withAnimation(.snappy) { vm.currency = .kes } }
                    }
                }

                if !savedPlaces.isEmpty {
                    Toggle(isOn: $vm.useSavedPlaces) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Base on your saved places")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                            Text("Prefer the \(savedPlaces.count) place\(savedPlaces.count == 1 ? "" : "s") you've bookmarked.")
                                .font(.system(size: 13, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(.accent)
                }
            }
        }
    }

    // MARK: Scaffold + controls

    @ViewBuilder
    private func stepScaffold<Content: View>(
        icon: String, title: String, subtitle: String?,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundStyle(.primary)
                .microAnimations(delay: 0.05, slideDirection: .Top, offsetAmount: 12)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(.title2, design: .rounded).bold())
                    .fixedSize(horizontal: false, vertical: true)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            .microAnimations(delay: 0.12, slideDirection: .Bottom, offsetAmount: 16)

            if vm.isLastStep {
                // Content-dense final step — no animation; content flows from here.
                content()
                    .microAnimations(delay: 0.22, slideDirection: .Bottom, offsetAmount: 20)
            } else {
                // Fill the roomy full-height sheet with the reused trip animation.
                CreateTripView(symbolFont: .title, tint: .primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                    .microAnimations(delay: 0.18, slideDirection: .Bottom, offsetAmount: 16)
                content()
                    .microAnimations(delay: 0.28, slideDirection: .Bottom, offsetAmount: 20)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func stepper(value: Int, unit: String, onMinus: @escaping () -> Void, onPlus: @escaping () -> Void) -> some View {
        HStack(spacing: 20) {
            circleButton("minus") { withAnimation(.snappy) { onMinus() } }
            VStack(spacing: 0) {
                Text("\(value)")
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .contentTransition(.numericText())
                Text(unit)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .frame(minWidth: 90)
            circleButton("plus") { withAnimation(.snappy) { onPlus() } }
        }
        .frame(maxWidth: .infinity)
    }

    private func circleButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 52, height: 52)
                .background(Color(.secondarySystemBackground), in: .circle)
        }
        .buttonStyle(PressableButtonStyle())
    }

    private func yesNo(isYes: Bool, set: @escaping (Bool) -> Void) -> some View {
        HStack(spacing: 10) {
            choicePill("No", selected: !isYes) { withAnimation(.snappy) { set(false) } }
            choicePill("Yes", selected: isYes) { withAnimation(.snappy) { set(true) } }
        }
    }

    private func choicePill(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(selected ? Color(.systemBackground) : .primary)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    selected ? AnyShapeStyle(Color.primary) : AnyShapeStyle(Color(.secondarySystemBackground)),
                    in: .rect(cornerRadius: 16)
                )
        }
        .buttonStyle(PressableButtonStyle())
    }

    // MARK: Nav

    private var navButtons: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Button {
                    if vm.isFirstStep { onBackToPitch() } else { withAnimation(.snappy) { vm.back() } }
                } label: {
                    Text("Back")
                }
                .buttonStyle(.appOutline)
                .frame(maxWidth: 120)

                Button {
                    if vm.isLastStep { onFinish() } else { withAnimation(.snappy) { vm.next() } }
                } label: {
                    HStack(spacing: 6) {
                        Text(vm.isLastStep ? "Generate itinerary" : "Next")
                        if needsBorderPass {
                            Label("\(FreeLimits.borderPassTokens)", systemImage: "centsign.circle.fill")
                                .labelStyle(.titleAndIcon)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                        }
                    }
                }
                .buttonStyle(vm.isLastStep ? AppButtonStyle(kind: .appAccent) : AppButtonStyle(kind: .appPrimary))
                .disabled(needsBorderPass && !canAffordBorderPass)
            }

            if needsBorderPass {
                Text(borderPassCallout)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(canAffordBorderPass ? Color.secondary : Color.red)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: Border Pass (free users pay to plan multi-country trips)

    /// Free user on the final step with multi-country selected → a Border Pass applies.
    private var needsBorderPass: Bool {
        vm.isLastStep && vm.multipleCountries && !(purchases?.isPro ?? false)
    }
    private var canAffordBorderPass: Bool {
        (tokens?.balance ?? 0) >= FreeLimits.borderPassTokens
    }
    private var borderPassCallout: String {
        if canAffordBorderPass {
            return "Multi-country trips use a \(FreeLimits.borderPassTokens)-token Border Pass. Go Pro for free multi-country planning."
        }
        return "You need \(FreeLimits.borderPassTokens) tokens for a Border Pass — you have \(tokens?.balance ?? 0). Top up or go Pro."
    }
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            CreateTripForm(vm: TripConfigViewModel(), onBackToPitch: {}, onFinish: {})
                .presentationDetents([.medium])
        }
}
