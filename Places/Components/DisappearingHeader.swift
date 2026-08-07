//
//  DisappearingHeader.swift
//  Places
//
//  Created by Sylus Abel on 30/07/2026.
//

import SwiftUI

extension ScrollView {
    @ViewBuilder
    func scrollableHeader<Header: View>(
        dismissDistance: CGFloat,
        @ViewBuilder header: @escaping () -> Header
    ) -> some View {
        self
            .modifier(DisappearingHeaderModifier(dismissDistance: dismissDistance, header: header))
    }
}

fileprivate struct DisappearingHeaderModifier<Header: View>: ViewModifier {
    var dismissDistance: CGFloat
    @ViewBuilder var header: Header
    
    @State private var scrollOffset: CGFloat = 0
    @State private var scrollPhase: ScrollPhase = .idle
    @State private var scrollDiretion: UIAccessibilityScrollDirection? = nil
    @State private var shiftScrollOffset: CGFloat = 0
    @State private var headerProgress: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .top, spacing: 0) {
                header
                    .compositingGroup()
                    .offset(y: headerProgress * -dismissDistance)
                    .opacity(1 - headerProgress)
            }
            .onScrollGeometryChange(for: CGFloat.self) {
                let maxHeight = $0.contentSize.height - $0.containerSize.height
                let offset = $0.contentOffset.y - $0.contentInsets.top
                return min(offset, maxHeight)
            } action: { oldValue, newValue in
                scrollOffset = newValue
                scrollDiretion = scrollPhase == .interacting ? (newValue > oldValue ? .up : .down) : nil
                if scrollDiretion != nil {
                    let offset = newValue.rounded() - shiftScrollOffset
                    let progress = max(min(offset / dismissDistance, 1), 0)
                    headerProgress = progress
                }
            }
            .onScrollPhaseChange { oldPhase, newPhase in
                scrollPhase = newPhase
                if newPhase != .interacting {
                    scrollDiretion = nil
                    withAnimation(animation) {
                        if headerProgress > 0.5 && scrollOffset > dismissDistance {
                            headerProgress = 1
                        } else {
                            headerProgress = 0
                        }
                    }
                    shiftScrollOffset = max(scrollOffset - (headerProgress * dismissDistance), 0)
                }
            }
            .onChange(of: scrollDiretion) { oldValue, newValue in
                guard newValue != nil else { return }
                shiftScrollOffset = max(scrollOffset - (headerProgress * dismissDistance), 0)
            }

    }
    
    var animation: Animation {
        .interpolatingSpring(duration: 0.3, bounce: 0, initialVelocity: 0)
    }
}

#Preview {
    AppTab()
}
