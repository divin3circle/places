//
//  DestinationTransition.swift
//  Places
//
//  Created by Sylus Abel on 31/07/2026.
//

import SwiftUI

struct TransitionConfig {
    var cardCornerRadius: CGFloat = 20
    var detailCornerRadius: CGFloat = 55
    var detailCardHeight: CGFloat = 460
    var animation: Animation = .smooth(duration: 0.34, extraBounce: 0)
}

struct DestinationTransition<Hero: View, Content: View>: View {
    var config: TransitionConfig = .init()
    @ViewBuilder var hero: (_ isExpanded: Bool, _ dismiss: (() -> ())?) -> Hero
    @ViewBuilder var content: (_ safeArea: EdgeInsets, _ dismiss: @escaping () -> ()) -> Content
    
    @State private var showFullScreen: Bool = false
    @State private var sourceRect: CGRect = .zero
    @State private var buttonScale: CGFloat = 1
    
    var body: some View {
        Button {
            withoutAnimations {
                showFullScreen = true
            }
        } label: {
            Rectangle()
                .foregroundStyle(.clear)
                .overlay {
                    if !showFullScreen {
                        hero(false, nil)
                    }
                }
                .clipShape(.rect(cornerRadius: config.cardCornerRadius))
                .contentShape(.rect(cornerRadius: config.cardCornerRadius))
                .onGeometryChange(
                    for: CGRect.self,
                    of: {$0.frame(in: .global)},
                    action: { newValue in
                        buttonScale = newValue.width / sourceRect.width
                })
        }
        .buttonStyle(DestinationButtonStyle())
        .onGeometryChange(
            for: CGRect.self,
            of: {$0.frame(in: .global)},
            action: { newValue in
            sourceRect = newValue
        })
        .fullScreenCover(isPresented: $showFullScreen) {
            TransitionFullScreenCover(
                config: config,
                showFullScreen: $showFullScreen,
                sourceRect: $sourceRect,
                buttonScale: $buttonScale,
                hero: hero,
                content: content
            )
        }
    }
}

fileprivate struct TransitionFullScreenCover<Hero: View, Content: View>: View {
    var config: TransitionConfig
    @Binding var showFullScreen: Bool
    @Binding var sourceRect: CGRect
    @Binding var buttonScale: CGFloat
    
    @ViewBuilder var hero: (_ isExpanded: Bool, _ dismiss: (() -> ())?) -> Hero
    @ViewBuilder var content: (_ safeArea: EdgeInsets, _ dismiss: @escaping () -> ()) -> Content
    
    @State private var animatesContents: Bool = false
    @State private var dragScale: CGFloat = 1
    @State private var safeArea: EdgeInsets = .init()
    @State private var isDismissing = false
    
    var body: some View {
        let cornerRadius = animatesContents ? config.detailCornerRadius : config.cardCornerRadius
        
        ScrollView {
            VStack(spacing: 0) {
                Rectangle()
                    .foregroundStyle(.clear)
                    .overlay(content: {
                        hero(animatesContents, dismiss)
                    })
                    .frame(
                        width: animatesContents ? nil : sourceRect.width,
                        height: animatesContents ? config.detailCardHeight : sourceRect.height
                    )
                    .offset(
                        x: animatesContents ? 0 : sourceRect.minX,
                        y: animatesContents ? 0 : sourceRect.minY
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .visualEffect { [animatesContents] content, proxy in
                        let minY = proxy.frame(in: .scrollView).minY
                        let height = animatesContents ? (proxy.size.height + 10) : 0
                        
                        return content
                            .offset(y: -minY > height ? -(minY + height) : 0)
                            .offset(y: minY > 0 ? -minY : 0)
                    }
                    .zIndex(1000)
                
                content(safeArea, dismiss)
            }
        }
        .scrollIndicators(.hidden)
        .background(.background)
        .mask(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: cornerRadius)
                .frame(
                    width: animatesContents ? nil : sourceRect.width,
                    height: animatesContents ? nil : sourceRect.height
                )
                .offset(
                    x: animatesContents ? 0 : sourceRect.minX,
                    y: animatesContents ? 0 : sourceRect.minY
                )
        }
        .overlay(alignment: .topLeading){
            DismissButton()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .frame(
                    width: animatesContents ? nil : sourceRect.width,
                    height: animatesContents ? config.detailCardHeight : sourceRect.height
                )
                .offset(
                    x: animatesContents ? 0 : sourceRect.minX,
                    y: animatesContents ? safeArea.top: sourceRect.minY
                )
        }
        .gesture(
            DestinationGesture { recognizer, scrollView in
                handleGesture(recognizer, scrollView)
            }
        )
        .scaleEffect(dragScale, anchor: .center)
        .scaleEffect(buttonScale)
        .ignoresSafeArea()
        .onGeometryChange(for: EdgeInsets.self) { $0.safeAreaInsets } action: { newValue in
            safeArea = newValue
        }
        .task {
            guard !animatesContents else { return }
            withAnimation(config.animation) {
                animatesContents = true
            }
        }
        .presentationBackground {
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(animatesContents ? 1 : 0)
        }
    }
    
    @ViewBuilder
    private func DismissButton() -> some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .frame(width: 20, height: 30)
                .contentShape(.circle)
        }
        .buttonStyle(.glass)
        .padding(.trailing, 15)
        .animation(.linear(duration: 0.15)) { $0.opacity(animatesContents ? 1 : 0) }
        .opacity((dragScale - 0.95) / 0.05)

    }
    
    private func dismiss() {
        withAnimation(config.animation, completionCriteria: .removed) {
            dragScale = 1
            animatesContents = false
        } completion: {
            withoutAnimations {
                showFullScreen = false
            }
        }
    }
    
    private func handleGesture(_ gesture: UIPanGestureRecognizer, _ scrollView: UIScrollView?) {
        let translation = gesture.translation(in: gesture.view).y
        let atTop = (scrollView?.contentOffset.y ?? 0) <= 0

        switch gesture.state {
        case .began, .changed:
            // Only own the drag when at the top AND pulling down. Take ownership
            // once and kill the scroll view's rubber-band so it can't fight our
            // manual offset pin every frame — that tug-of-war is what makes the
            // hero jitter (the visualEffect amplifies the oscillating minY).
            if translation > 0 && atTop && !isDismissing {
                isDismissing = true
                scrollView?.bounces = false
            }
            guard isDismissing else { return }
            // Pin the scroll to the top so it can't overscroll → kills the
            // hero/content separation gap.
            scrollView?.contentOffset.y = 0
            let progress = max(min(translation / config.detailCardHeight, 1), 0)
            dragScale = 1 - (progress * 0.2)
        default:
            guard isDismissing else { return }
            isDismissing = false
            scrollView?.bounces = true
            if dragScale < 0.9 {
                dismiss()
            } else {
                withAnimation(config.animation) {
                    dragScale = 1
                }
            }
        }
    }
}

private struct DestinationButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .keyframeAnimator(initialValue: 1.0, trigger: configuration.isPressed) { content, scale in
                content
                    .scaleEffect(scale)
            } keyframes: { _ in
                if configuration.isPressed {
                    CubicKeyframe(0.95, duration: 0.15)
                } else {
                    CubicKeyframe(1, duration: 0.15)
                }
            }
    }
}

fileprivate struct DestinationGesture: UIGestureRecognizerRepresentable {
    var handle: (UIPanGestureRecognizer, UIScrollView?) -> ()

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let gesture = UIPanGestureRecognizer()
        gesture.delegate = context.coordinator
        return gesture
    }

    func updateUIGestureRecognizer(_ recognizer: UIPanGestureRecognizer, context: Context) {

    }

    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context: Context) {
        handle(recognizer, context.coordinator.scrollView)
    }

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator{
        Coordinator()
    }

    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        weak var scrollView: UIScrollView?

        // Recognize alongside the ScrollView instead of deferring to it, and
        // capture the inner scroll view so the handler can read/clamp its offset.
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            if let scrollview = otherGestureRecognizer.view as? UIScrollView {
                scrollView = scrollview
            }
            return true
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let pangesture = gestureRecognizer as? UIPanGestureRecognizer else {
                return false
            }

            let velocity = pangesture.velocity(in: pangesture.view)

            return velocity.y > abs(velocity.x)
        }
    }
}

fileprivate extension View {
    func withoutAnimations(block: @escaping () -> ()) {
        DispatchQueue.main.async {
            var  transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                block()
            }
        }
    }
}

#Preview {
    AppTab()
}
