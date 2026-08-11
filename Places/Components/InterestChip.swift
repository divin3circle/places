import SwiftUI

struct InterestChip: View {
    let interest: TravelInterest
    let isSelected: Bool
    var onTap: (() -> Void)? = nil
    
    @State private var isPressed = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            onTap?()
        }) {
            VStack(spacing: 2) {
                Image(systemName: interest.icon)
                    .font(.system(size: iconSize, weight: .semibold))
                    .imageScale(.medium)
                Text(interest.label)
                    .font(.system(size: labelSize, weight: .medium, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(width: chipSize, height: chipSize)
            .background(backgroundColor)
            .foregroundStyle(foregroundColor)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(borderColor, lineWidth: isSelected ? 2 : 0)
            )
            .shadow(
                color: shadowColor,
                radius: isPressed ? 4 : 8,
                x: 0,
                y: isPressed ? 2 : 4
            )
            .scaleEffect(isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isSelected)
        }
        .buttonStyle(.plain)
        .pressEvents(
            onPress: { isPressed = true },
            onRelease: { isPressed = false }
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(interest.label), \(isSelected ? "selected" : "not selected")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint("Double tap to \(isSelected ? "deselect" : "select")")
    }
    
    private var chipSize: CGFloat { 64 }
    private var iconSize: CGFloat { 26 }
    private var labelSize: CGFloat { 10 }
    
    private var backgroundColor: Color {
        if isSelected {
            return .accent
        }
        return colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6)
    }
    
    private var foregroundColor: Color {
        isSelected ? .white : .primary
    }
    
    private var borderColor: Color {
        isSelected ? .accent : .clear
    }
    
    private var shadowColor: Color {
        colorScheme == .dark ? .black.opacity(0.3) : .black.opacity(0.12)
    }
}

// MARK: - Press Gesture Helper

private struct PressEvents: ViewModifier {
    let onPress: () -> Void
    let onRelease: () -> Void
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onPress() }
                    .onEnded { _ in onRelease() }
            )
    }
}

private extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressEvents(onPress: onPress, onRelease: onRelease))
    }
}

// MARK: - Snapshot Helper for Physics Engine

extension InterestChip {
    /// Render this chip to a UIImage for use as a physics body texture
    static func snapshot(interest: TravelInterest, selected: Bool, size: CGFloat = 64) -> UIImage {
        let view = InterestChip(interest: interest, isSelected: selected)
            .frame(width: size, height: size)
        let renderer = ImageRenderer(content: view)
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage ?? UIImage()
    }
}