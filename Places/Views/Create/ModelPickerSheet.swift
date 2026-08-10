//
//  ModelPickerSheet.swift
//  Places
//
//  Lets the user choose how itineraries are generated — on-device (Apple
//  Intelligence) or cloud. Shown the first time they generate and editable from
//  Profile settings. The on-device option is disabled (with a reason) on devices
//  that lack Apple Intelligence. The choice + optional API key persist via
//  @AppStorage.
//

import SwiftUI

struct ModelPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AIPreferenceKey.model) private var aiModelRaw = ""

    /// Called after the user confirms (used to kick off generation on first run).
    var onDone: (() -> Void)? = nil

    @State private var selection: AIModelKind = .onDevice
    private let onDeviceStatus = AIAvailability.onDevice

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("How should we generate?")
                    .font(.title2.bold())
                    .fontDesign(.rounded)
                Text("On-device is private and works offline. Cloud is more capable. You can change this anytime in Settings.")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            optionCard(.onDevice, enabled: onDeviceStatus.isAvailable, note: onDeviceStatus.reason)
            optionCard(.cloud, enabled: true, note: "Generated securely on our servers.")

            Spacer(minLength: 0)

            Button {
                aiModelRaw = selection.rawValue
                onDone?()
                dismiss()
            } label: {
                Text("Continue")
            }
            .buttonStyle(.appAccent)
            .disabled(selection == .onDevice && !onDeviceStatus.isAvailable)
        }
        .padding(.horizontal, 20)
        .padding(.top, 28)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(.systemBackground))
        .presentationDetents([.height(420)])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color(.systemBackground))
        .animation(.snappy, value: selection)
        .onAppear {
            if let saved = AIModelKind(rawValue: aiModelRaw) {
                selection = saved
            } else if !onDeviceStatus.isAvailable {
                selection = .cloud
            }
        }
    }

    private func optionCard(_ kind: AIModelKind, enabled: Bool, note: String?) -> some View {
        let isSelected = selection == kind
        return Button {
            if enabled { selection = kind }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: kind.icon)
                    .font(.system(size: 20))
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(kind.title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                    Text(note ?? kind.subtitle)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 8)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
            .foregroundStyle(.primary)
            .padding(14)
            .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color.primary : .clear, lineWidth: 1.5)
            )
            .opacity(enabled ? 1 : 0.5)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

#Preview {
    Color.clear.sheet(isPresented: .constant(true)) { ModelPickerSheet() }
}
