//
//  AppearancePickerRow.swift
//  Places
//
//  Created by Sylus Abel on 03/08/2026.
//

import SwiftUI

/// A settings row for the app's appearance (System / Light / Dark). Binds to the
/// same `@AppStorage` key that `PlacesApp` reads, so changing it re-themes the
/// whole app immediately.
///
/// The segmented control is built from `Button`s rather than a `.segmented`
/// `Picker` on purpose: this screen scrolls inside a `DragGesture(minimumDistance: 0)`
/// (`CustomTabBarModifier`), which swallows taps to a UIKit-backed segmented
/// control. Plain buttons hit-test reliably and give us full styling control.
struct AppearancePickerRow: View {
    @Binding var selection: AppearanceMode
    @Namespace private var highlight

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 18) {
                Image(systemName: selection.icon)
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(.primary)
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: 30, alignment: .leading)

                Text("Appearance")
                    .font(.system(size: 17))
                    .fontDesign(.rounded)
                    .foregroundStyle(.primary)

                Spacer(minLength: 8)
            }

            segmentedControl
        }
        .padding(.vertical, 12)
    }

    private var segmentedControl: some View {
        HStack(spacing: 0) {
            ForEach(AppearanceMode.allCases) { mode in
                Button {
                    withAnimation(.snappy(duration: 0.25)) {
                        selection = mode
                    }
                } label: {
                    Text(mode.title)
                        .font(.system(size: 14, weight: .semibold))
                        .fontDesign(.rounded)
                        .foregroundStyle(selection == mode ? Color(.systemBackground) : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background {
                            if selection == mode {
                                Capsule()
                                    .fill(Color.primary)
                                    .matchedGeometryEffect(id: "highlight", in: highlight)
                            }
                        }
                        .contentShape(.capsule)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.primary.opacity(0.06), in: .capsule)
    }
}

#Preview {
    @Previewable @State var mode: AppearanceMode = .system
    return AppearancePickerRow(selection: $mode)
        .padding(.horizontal, 36)
}
