//
//  AppButtonStyle.swift
//  Places
//
//

import SwiftUI

enum AppButtonKind {
    case appPrimary
    case appAccent
    case appOutline
}

struct AppButtonStyle: ButtonStyle {
    var kind: AppButtonKind = .appPrimary
    var minHeight: CGFloat = 50

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.semibold)
            .fontDesign(.rounded)
            .frame(maxWidth: .infinity, minHeight: minHeight)
            .foregroundStyle(foreground)
            .background(Capsule().fill(background))
            .overlay {
                if kind == .appOutline {
                    Capsule().stroke(Color(.systemGray3), lineWidth: 1.5)
                }
            }
            .contentShape(.capsule)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }

    private var foreground: Color {
        switch kind {
        case .appPrimary: Color(.systemBackground)
        case .appAccent: .white
        case .appOutline: .primary
        }
    }

    private var background: AnyShapeStyle {
        switch kind {
        case .appPrimary: AnyShapeStyle(Color.primary)
        case .appAccent: AnyShapeStyle(Color.accentColor)
        case .appOutline: AnyShapeStyle(Color.clear)
        }
    }
}

extension ButtonStyle where Self == AppButtonStyle {
    static var appPrimary: AppButtonStyle { AppButtonStyle(kind: .appPrimary) }
    static var appAccent: AppButtonStyle { AppButtonStyle(kind: .appAccent) }
    static var appOutline: AppButtonStyle { AppButtonStyle(kind: .appOutline) }
}

#Preview {
    VStack(spacing: 14) {
        Button("Show dates") {}.buttonStyle(.appAccent)
        Button("View Trip") {}.buttonStyle(.appPrimary)
        Button("Edit") {}.buttonStyle(.appOutline)
    }
    .padding()
}
