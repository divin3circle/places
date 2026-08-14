//
//  AppTour.swift
//  Places
//
//  Created by Sylus Abel on 14/08/2026.
//

import SwiftUI

struct AppTour: View {
    @Environment(\.colorScheme) var colorScheme
    
    var items: [Item]
    var back: () -> () = {}
    var onComplete: () -> () = {}

    @State private var currentIndex: Int = 0

    /// Nil when `items` is empty, so the zoom/blur chrome degrades instead of trapping.
    private var currentItem: Item? {
        items.indices.contains(currentIndex) ? items[currentIndex] : nil
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            screenshotView()
                .compositingGroup()
                .scaleEffect(currentItem?.zoomScale ?? 1, anchor: currentItem?.zoomAnchor ?? .center)
                .padding(.top, 35)
                .padding(.horizontal, 30)
                .padding(.bottom, 220)
            
            VStack(spacing: 10) {
                textContent()
                indicatorView()
                continueButton()
            }
            .padding(.top, 20)
            .padding(.horizontal, 15)
            .frame(height: 210)
            .background {
                glassBlur(15)
            }
            
            backButton()
        }
    }
    
    @ViewBuilder
    private func glassBlur(_ radius: CGFloat) -> some View {
        let tint: Color = colorScheme == .dark ? .black.opacity(0.5) : .white.opacity(0.5)
        
        Rectangle()
            .fill(tint)
            .glassEffect(.clear, in: .rect)
            .blur(radius: radius/4)
            .padding([.horizontal, .bottom], -radius * 2)
            .padding(.top, -radius/2)
            .opacity((currentItem?.zoomScale ?? 1) != 1 ? 1 : 0)
            .ignoresSafeArea()
    }
    
    @ViewBuilder
    private func textContent() -> some View {
        GeometryReader {
            let size = $0.size
            
            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    ForEach(items.indices, id: \.self) { index in
                        let item = items[index]
                        let isActive = currentIndex == index
                        
                        VStack(spacing: 6) {
                            Text(item.title)
                                .font(.title2)
                                .fontDesign(.rounded)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                            
                            Text(item.subtitle)
                                .font(.callout)
                                .fontDesign(.rounded)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.secondary)
                            
                        }
                        .frame(width: size.width)
                        .compositingGroup()
                        .blur(radius: isActive ? 0 : 30)
                        .opacity(isActive ? 1 : 0)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollDisabled(true)
            .scrollTargetBehavior(.paging)
            .scrollClipDisabled()
            .scrollPosition(id: .init(get: {
                return currentIndex
            }, set: { _  in }))
        }
    }
    
    @ViewBuilder
    private func screenshotView() -> some View {
        GeometryReader {
            let size = $0.size
            
            Rectangle()
                .fill(.background)
            
            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(items.indices, id: \.self) { index in
                        let item = items[index]
                        
                        Group {
                            if let screenshot = item.screenshot {
                                Image(uiImage: screenshot)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            } else {
                                Rectangle()
                                    .fill(.background)
                            }
                        }
                        .frame(width: size.width, height: size.height)
                        
                    }
                }
                .scrollTargetLayout()
            }
            .scrollDisabled(true)
            .scrollTargetBehavior(.viewAligned)
            .scrollIndicators(.hidden)
            .scrollPosition(id: .init(get: {
                return currentIndex
            }, set: { _  in }))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private func indicatorView() -> some View {
        HStack(spacing: 6) {
            ForEach(items.indices, id: \.self) { index in
                let isActive: Bool = currentIndex == index
                
                Capsule()
                    .fill(.accent.opacity(isActive ? 1 : 0.4))
                    .frame(width: isActive ? 25 : 6, height: 6)
            }
        }
        .padding(.bottom, 5)
    }
    
    @ViewBuilder
    private func continueButton() -> some View {
        PrimaryButton(title: "Continue", kind: .appPrimary) {
            // Check the edge before advancing — `withAnimation` mutates synchronously,
            // so testing afterwards would finish the tour a tap early.
            guard currentIndex < items.count - 1 else {
                onComplete()
                return
            }
            withAnimation(animation) {
                currentIndex += 1
            }
        }
            .microAnimations(delay: 0.5, slideDirection: .Bottom, offsetAmount: 0)
            .padding(.horizontal, 30)
    }
    
    @ViewBuilder
    private func backButton() -> some View {
        Button {
            guard currentIndex > 0 else {
                back()
                return
            }
            withAnimation(animation) {
                currentIndex -= 1
            }
        } label: {
            Image(systemName: "chevron.left")
                .font(.title3)
                .frame(width: 20, height: 30)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.leading, 15)
        .padding(.top, 5)
    }
    
    struct Item: Identifiable {
        var id: Int
        var title: String
        var subtitle: String
        var screenshot: UIImage?
        var zoomScale: CGFloat = 1
        var zoomAnchor: UnitPoint = .center
    }
    
    var animation: Animation {
        .interpolatingSpring(duration: 0.65, bounce: 0, initialVelocity: 0)
    }
}

#Preview {
    AppTourOnboarding()
}
