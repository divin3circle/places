import SwiftUI
import SwiftfulRouting

struct SecondOnboarding: View {
    @Environment(\.router) var router
    @State private var selectedInterests: Set<TravelInterest> = []
    @State private var currentStep = 1
    // Shuffle once, not on every re-render, so the scene isn't churned.
    @State private var interests = EastAfricaInterestsDataset.shuffled()

    var body: some View {
        VStack(spacing: 0) {
            ProgressViewer(steps: 4, currentStep: $currentStep)
                .padding(.horizontal, 30)
                .padding(.top, 16)

            VStack(alignment: .leading, spacing: 6) {
                Text("What moves you?")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .fontWidth(.expanded)
                Text("Pick the experiences that speak to your soul.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 30)
            .padding(.top, 20)

            GravityContainer(
                items: interests,
                selectedItems: $selectedInterests,
                maxSelections: 5
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(spacing: 12) {
                Text("\(selectedInterests.count) of 5 selected")
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(.secondary)

                PrimaryButton(title: "Continue", kind: .appPrimary) {
                    navigateToThirdOnboarding()
                }
                .disabled(selectedInterests.isEmpty)
                .opacity(selectedInterests.isEmpty ? 0.5 : 1)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 28)
            .padding(.top, 4)
        }
        .toolbar(.hidden, for: .navigationBar)
    }
    
    private func navigateToThirdOnboarding() {
        router.showScreen(.push){_ in 
            ThirdOnboarding()
        }
    }
}

#Preview {
    SecondOnboarding()
}
