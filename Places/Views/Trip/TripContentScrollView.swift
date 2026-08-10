//
//  TripContentScrollView.swift
//  Places
//
//  Created by Sylus Abel on 10/08/2026.
//

import SwiftUI

struct TripContentScrollView<ScrollContent: View, SheetContent: View, BottomBar: View>: View {
    @ViewBuilder var scrollContent: (_ progress: CGFloat) -> ScrollContent
    @ViewBuilder var sheetContent: (_ progress: CGFloat) -> SheetContent
    @ViewBuilder var bottomBar: (_ progress: CGFloat) -> BottomBar
    
    @State private var sheetHeight: CGFloat = 150
    @State private var storedSheetHeight: CGFloat = 0
    @State private var storedTranslation: CGFloat = 0
    @State private var isScrolledUp: Bool = false
    
    @State private var sheetOffset: CGFloat = 0
    @State private var storedSheetOffset: CGFloat = 0
    
    @State private var sheetScrollPosition: ScrollPosition = .init()
    @State private var isSheetScrolledDisabled: Bool = false
    @State private var isElligibleForGesture: Bool = false
    @State private var sheetScrollOffset: CGFloat = 0
    

    
    var body: some View {
        GeometryReader {
            let size = $0.size
            let safeArea = $0.safeAreaInsets
            // sheetOffset is 0 collapsed and negative when raised; negate so progress
            // climbs 0 → 1 as the sheet expands (drives scale + fade handoffs).
            let progress: CGFloat = min(max(-sheetOffset / (size.height - sheetHeight), 0), 1)
            let scale = 1 - (progress *  0.1)
            let sheetShape =  UnevenRoundedRectangle(
                topLeadingRadius: 30,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 30
            )
            
            ZStack(alignment: .bottom) {
                Rectangle()
                    .fill(.black)
                    .ignoresSafeArea(.all)
                
                ScrollView(.vertical) {
                    scrollContent(progress)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onScrollGeometryChange(for: Bool.self, of: { $0.contentSize.height > ($0.contentSize.height - maximumSheetHeight) }, action: { oldValue, newValue in
                    isElligibleForGesture = newValue
                })
                .background {
                    let cornerRadius = 30 + (progress * 15)
                    UnevenRoundedRectangle(
                        topLeadingRadius: cornerRadius,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: cornerRadius
                    )
                        .fill(.background)
                }
                .scrollClipDisabled()
                .contentShape(.rect)
                .gesture(CustomGesture {
                    handleMainGesture($0)
                })
                .scaleEffect(scale, anchor: .bottom)
                .ignoresSafeArea()
                
                ScrollView(.vertical) {
                    sheetContent(progress)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .safeAreaPadding(.top, 30)
                .scrollPosition($sheetScrollPosition)
                .scrollDisabled(isSheetScrolledDisabled || sheetOffset == 0)
                .onScrollGeometryChange(for: CGFloat.self, of: { $0.contentOffset.y + $0.contentInsets.top }, action: { oldValue, newValue in
                    sheetScrollOffset = newValue
                })
                .scrollClipDisabled()
                .mask {
                    sheetShape
                        .padding(.top, -safeArea.top * progress)
                }
                .background {
                    sheetShape
                        .fill(.background)
                        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: -5)
                        .padding(.top, -safeArea.top * progress)
                        .padding(.bottom, -safeArea.bottom)
                }
                .overlay(alignment: .top) {
                    Capsule()
                        .fill(.gray.opacity(0.4))
                        .frame(width: 35, height: 6)
                        .frame(width: 50, height: 26, alignment: .bottom)
                        .contentShape(.rect)
                        .gesture(
                            CustomGesture(
                                handle: {  let state = $0.state
                                    if state == .began || state == .changed {
                                        isSheetScrolledDisabled = true
                                    }
                                    else {
                                        isSheetScrolledDisabled = false
                                    }
                                })
                        )
                        // Ride the top of the sheet; drop below the notch when expanded.
                        .padding(.top, 6 + safeArea.top * progress)
                }
                .contentShape(.rect)
                .offset(y: size.height - sheetHeight)
                .offset(y: sheetOffset)
                .gesture(CustomGesture {
                    handleSheetGesture($0, size: size)
                })
                .background(alignment: .top) {
                    bottomBar(progress)
                        .visualEffect { content, proxy in
                            content
                                .offset(y: -(proxy.size.height + 5))
                        }
                        .offset(y: size.height - sheetHeight)
                        .offset(y: sheetOffset)
                }
            }
        }
        .toolbarVisibility(.hidden, for: .navigationBar)
        .toolbarVisibility(.hidden, for: .tabBar)
    }
    
    private func handleMainGesture(_ gesture: UIPanGestureRecognizer) {
        let state = gesture.state
        let translation = gesture.translation(in: gesture.view).y
        let velocity = gesture.velocity(in: gesture.view).y / 10
        
        switch state {
        case .began:
            updateMainTranslation(value: -translation)
        case .changed:
            if velocity < 0 {
                if !isScrolledUp {
                    updateMainTranslation(value: -translation)
                }
                isScrolledUp = true
            } else {
                if isScrolledUp {
                    updateMainTranslation(value: -translation)
                }
                isScrolledUp = false
            }
            let offset = storedTranslation + translation
            sheetHeight = min(max(storedSheetHeight + offset, minimumSheetHeight), maximumSheetHeight)
        case .ended, .failed, .cancelled:
            updateMainTranslation(true, value: 0)
            
            withAnimation(animation) {
                if (sheetHeight + velocity) < 110 && isElligibleForGesture {
                    sheetHeight = minimumSheetHeight
                } else {
                    sheetHeight = maximumSheetHeight
                }
            }
        default: ()
        }
    }
    
    func updateMainTranslation(_ reset: Bool = false, value: CGFloat) {
        if reset {
            storedSheetHeight = 0
            storedTranslation = 0
            isScrolledUp = false
        } else {
            storedSheetHeight = sheetHeight
            storedTranslation = value
        }
    }
    
    private func handleSheetGesture(_ gesture: UIPanGestureRecognizer, size: CGSize) {
        let state = gesture.state
        let translation = gesture.translation(in: gesture.view).y
        let velocity = gesture.velocity(in: gesture.view).y / 10
        let threshold: CGFloat = 3
        
        switch state {
        case .began:
            if sheetScrollOffset <= threshold && velocity < 0 && sheetOffset == 0 {
                isSheetScrolledDisabled = true
            }
            
            if sheetScrollOffset <= threshold && velocity > 0 && storedSheetOffset != 0 {
                isSheetScrolledDisabled = true
            }
        case .changed:
            guard isSheetScrolledDisabled else { return }
            
            sheetOffset = -min(max(-translation + storedSheetOffset, 0), size.height - sheetHeight)
        case .ended, .failed, .cancelled:
            guard isSheetScrolledDisabled else { return }
            
            withAnimation(animation) {
                if -(sheetOffset + velocity) > (size.height / 3) {
                    sheetOffset = -(size.height - sheetHeight)
                } else {
                    sheetOffset = 0
                    sheetScrollPosition.scrollTo(y: 0)
                }
            }
            storedSheetOffset = -sheetOffset
            isSheetScrolledDisabled = false
        default: ()
        }
    }
    
    var maximumSheetHeight: CGFloat {
        return 150
    }
    
    var minimumSheetHeight: CGFloat {
        return 70
    }
    
    var animation: Animation {
        .snappy(duration: 0.3, extraBounce: 0)
    }
}

fileprivate struct CustomGesture: UIGestureRecognizerRepresentable {
    var handle: (UIPanGestureRecognizer) -> ()
    
    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        Coordinator()
    }
    
    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let gesture = UIPanGestureRecognizer()
        gesture.delegate = context.coordinator
        return gesture
    }
    
    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context: Context) {
        handle(recognizer)
    }
    
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            return true
        }
    }
}

#Preview {
    TripContentScrollView { _ in
        Color.indigo.containerRelativeFrame(.vertical)
    } sheetContent: { _ in
        VStack(alignment: .leading, spacing: 12) {
            ForEach(0..<12, id: \.self) { Text("Row \($0)") }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    } bottomBar: { _ in
        Text("Trip Details")
            .padding(.vertical, 8).padding(.horizontal, 15)
            .background(.ultraThinMaterial, in: .capsule)
    }
}
