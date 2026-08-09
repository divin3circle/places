//
//  ToastView.swift
//  Places
//
//  Minimal top toast for transient success/error feedback. Auto-dismisses.
//  Usage: `@State private var toast: ToastData?` then `.toast($toast)`.
//

import SwiftUI

struct ToastData: Equatable {
    let message: String
    var isError: Bool = false
}

private struct ToastModifier: ViewModifier {
    @Binding var toast: ToastData?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let toast {
                    HStack(spacing: 8) {
                        Image(systemName: toast.isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                        Text(toast.message)
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(toast.isError ? Color.red : Color.green))
                    .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
                    .padding(.top, 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .task {
                        try? await Task.sleep(for: .seconds(2.5))
                        withAnimation { self.toast = nil }
                    }
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: toast)
    }
}

extension View {
    func toast(_ toast: Binding<ToastData?>) -> some View {
        modifier(ToastModifier(toast: toast))
    }
}
