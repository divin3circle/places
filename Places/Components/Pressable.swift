//
//  Pressable.swift
//  Places
//
//  Shared tap micro-feedback: a subtle scale-down while pressed. The single
//  sanctioned "micro" interaction under the Quiet Hierarchy motion budget.
//

import SwiftUI

private struct PressableModifier: ViewModifier {
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: isPressed)
            .onLongPressGesture(
                minimumDuration: 0,
                maximumDistance: .infinity,
                pressing: { isPressed = $0 },
                perform: {}
            )
    }
}

extension View {
    /// Subtle scale-down while pressed (~0.97, 0.12s). Use on views that handle
    /// their own tap via `.onTapGesture` (NOT inside a `Button` label — use
    /// `.buttonStyle(PressableButtonStyle())` there to avoid gesture conflicts).
    func pressable() -> some View {
        modifier(PressableModifier())
    }
}

/// The `Button` equivalent of `.pressable()`. Reads `configuration.isPressed`
/// so it never fights the button's own tap handling.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

