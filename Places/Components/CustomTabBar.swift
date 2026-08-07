//
//  CustomTabBar.swift
//  Places
//
//  Created by Sylus Abel on 30/07/2026.
//

import SwiftUI

extension View {
    func hideNativeTabBar() -> some View {
        self
            .toolbarVisibility(.hidden, for: .tabBar)
    }
}

/// A native SwiftUI, Instagram-style tab bar: five evenly-spaced, icon-only
/// slots with a prominent center "Create" action. Built from `Button`s (not a
/// UISegmentedControl) so it hit-tests reliably underneath the scroll drag
/// gesture in `CustomTabBarModifier` — see [[custom-tabbar-drag-swallows-taps]].
struct CustomTabBar: View {
    @Binding var selection: AppTabs
    /// Fired by the center hero button — an action, not a tab switch.
    var onCreate: () -> Void
    /// Called on any interaction so the host can un-hide the bar (reset progress).
    var onInteraction: () -> Void = {}

    private let leadingTabs: [AppTabs] = [.home, .explore]
    private let trailingTabs: [AppTabs] = [.lounges, .profile]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(leadingTabs, id: \.self, content: tabButton)
            createButton
            ForEach(trailingTabs, id: \.self, content: tabButton)
        }
        .frame(height: 48)
        .frame(maxWidth: .infinity)
        .animation(.snappy(duration: 0.25), value: selection)
    }

    private func tabButton(_ tab: AppTabs) -> some View {
        let isSelected = selection == tab
        return Button {
            onInteraction()
            selection = tab
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tab.tabImage)
                    .font(.system(size: 19, weight: isSelected ? .semibold : .regular))
                Text(tab.rawValue)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
            }
            .foregroundStyle(isSelected ? Color.accentColor : Color.primary.opacity(0.45))
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    private var createButton: some View {
        Button {
            onInteraction()
            onCreate()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 46, height: 34)
                .background(.accent, in: .rect(cornerRadius: 12))
                .frame(maxWidth: .infinity)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

extension View {
    func adoptForCustomTabBar(_ progress: Binding<CGFloat>) -> some View {
        self
            .modifier(CustomTabBarModifier(progress: progress))
    }
}

fileprivate struct CustomTabBarModifier: ViewModifier {
    @Binding var progress: CGFloat
    @GestureState private var isDragging: Bool = false
    @State private var isScrolledUp: Bool?
    @State private var shiftOffset: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0
    @State private var isLargerContent: Bool = false
    @State private var scrollPhase: ScrollPhase = .idle
    func body(content: Content) -> some View {
        content
            .toolbarVisibility(.hidden, for: .tabBar)
            .safeAreaPadding(.bottom, 50)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(.rect)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .scrollView)
                    .updating($isDragging) { _, out, _ in
                    out = true
                    }.onEnded { value in
                        guard scrollPhase != .idle else { return }
                        let velocity = value.velocity.height / 5
                        let resultOffset = scrollOffset + velocity
                        let rawProgress = (resultOffset - shiftOffset) / distance
                        let clampedProgress = max(0, min(1, rawProgress))

                        withAnimation(animation) {
                            self.progress = resultOffset > (distance / 2) && isLargerContent ? (clampedProgress > 0.5 ? 1 : 0) : 0
                        }
                        isScrolledUp = nil
                        shiftOffset = scrollOffset - (progress * distance)
                    }
            )
            .onScrollPhaseChange({ oldPhase, newPhase in
                scrollPhase = newPhase
            })
            .onScrollGeometryChange(for: CGFloat.self, of: { $0.contentSize.height - $0.containerSize.height }, action: { oldValue, newValue in
                isLargerContent = newValue > 0
            })
            .onScrollGeometryChange(for: CGFloat.self) {
                $0.contentOffset.y + $0.contentInsets.top
            } action: { oldValue, newValue in
                guard isDragging else { return }
                scrollOffset = newValue
                _ = oldValue < newValue

                if self.isScrolledUp != isScrolledUp {
                    self.isScrolledUp = isScrolledUp
                    self.shiftOffset = newValue
                }

                let rawProgress = (newValue - shiftOffset) / distance
                let clampedProgress = max(0, min(1, rawProgress))

                withAnimation(animation) {
                    self.progress = clampedProgress
                }
            }
    }

    private var distance: CGFloat {
        return 100
    }

    private var animation: Animation {
        .interpolatingSpring(duration: 0.25, bounce: 0, initialVelocity: 0)
    }
}

#Preview {
   AppTab()
}
