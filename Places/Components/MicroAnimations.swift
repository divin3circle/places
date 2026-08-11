//
//  MicroAnimations.swift
//  Places
//
//  Created by Sylus Abel on 27/07/2026.
//

import SwiftUI

enum SlideDirection {
    case Top, Bottom, Left, Right
}

struct MicroAnimations: ViewModifier {
    let delay: Double
    let direction: SlideDirection
    let offsetAmount: CGFloat

    @State var isVisible: Bool = false
    
    private var initialOffset: CGSize {
        switch direction {
        case .Top:
            return CGSize(width: 0, height: -offsetAmount)
        case .Bottom:
            return CGSize(width: 0, height: offsetAmount)
        case .Left:
            return CGSize(width: -offsetAmount, height: 0)
        case .Right:
            return CGSize(width: offsetAmount, height: 0)
        }
    }
    
    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(isVisible ? .zero : initialOffset)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        isVisible = true
                    }
                }
            }
    }
}

extension View {
    func microAnimations(delay: Double, slideDirection: SlideDirection, offsetAmount: CGFloat) -> some View {
        self.modifier(MicroAnimations(delay: delay, direction: slideDirection, offsetAmount: offsetAmount))
    }
}
