//
//  CreateTripView.swift
//  Places
//
//  Created by Sylus Abel on 03/08/2026.
//

import SwiftUI

struct CreateTripView: View {
    @Environment(\.dismiss) private var dismiss
    var symbols: [String] = ["figure.walk.suitcase.rolling", "airplane.departure", "map", "sparkle.text.clipboard.fill"]
    var symbolFont: Font = .title
    var tint: Color = .primary
    
    @State private var trim: CGFloat = 0
    @State private var rotation: CGFloat = 0
    @State private var isAnimating: Bool = false
    var body: some View {
        Rectangle()
            .foregroundStyle(.clear)
            .modifier(
                CreateTripModifier(
                    symbols: symbols,
                    symbolFont: symbolFont,
                    tint: tint,
                    trim: trim,
                    rotation: rotation
                )
            )
            .task {
                guard !isAnimating else { return }
                isAnimating = true
                
                try? await Task.sleep(for: .seconds(0.1))
                withAnimation(.easeInOut(duration: 1.5)) {
                    trim = 1
                }
                
                try? await Task.sleep(for: .seconds(0.5))
                withAnimation(.linear(duration: 15).repeatForever(autoreverses: false)) {
                    rotation = 360
                }

            }
    }
}
@Animatable
fileprivate struct CreateTripModifier: ViewModifier {
    @AnimatableIgnored var symbols: [String]
    @AnimatableIgnored var symbolFont: Font
    @AnimatableIgnored var tint: Color
    
    var trim: CGFloat
    var rotation: CGFloat
    
    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader {
                    let size = $0.size
                    let circleSize = min(size.width, size.height)
                    let dashLength = (CGFloat.pi * circleSize) / CGFloat(symbols.count * 2)
                    let dashPhase = -dashLength / 2
                    let strokeStyle = StrokeStyle(
                        lineWidth: 3,
                        dash: [dashLength],
                        dashPhase: dashPhase
                    )
                    
                    ZStack {
                        Circle()
                            .trim(from: 0, to: trim)
                            .stroke(tint, style: strokeStyle)
                            .rotationEffect(.init(degrees: rotation))
                            .rotation3DEffect(.init(degrees: 62), axis: (x: 1, y: 0, z: 0), anchor: .center, perspective: 0)
                            .rotation3DEffect(.init(degrees: -20), axis: (x: 0, y: 0, z: 1), anchor: .center, perspective: 0)
                        
                        ZStack {
                            ForEach(symbols.indices,id: \.self) { index in
                                let radius = circleSize / 2
                                let angle = (CGFloat(index) / CGFloat(symbols.count)) * 360 + rotation
                                let angleInRadians = (CGFloat.pi * angle) / 180
                                let rotation3D = cos((62 * CGFloat.pi) / 180)
                                let x = cos(angleInRadians) * radius
                                let y = sin(angleInRadians) * radius * rotation3D

                                let start = CGFloat(index) / CGFloat(symbols.count)
                                let end = CGFloat(index + 1) / CGFloat(symbols.count)
                                let scaleProgress = max(min((trim - start) / (end - start), 1), 0)

                                Image(systemName: symbols[index])
                                    .font(symbolFont)
                                    .foregroundStyle(tint)
                                    .shadow(color: tint.opacity(0.15), radius: 2, x: 1, y: 2)
                                    .shadow(color: tint.opacity(0.1), radius: 8, x: 4, y: 8)
                                    .scaleEffect(scaleProgress)
                                    .rotationEffect(.init(degrees: 20))
                                    .offset(x: x, y: y)

                            }
                        }
                        .rotationEffect(.init(degrees: -20))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
    }
}

#Preview {
    let symbols: [String] = ["figure.walk.suitcase.rolling", "airplane.departure", "map", "sparkle.text.clipboard.fill"]
    Color.black
        .sheet(isPresented: .constant(true)) {
            CreateTripView(symbols: symbols, symbolFont: .title, tint: .primary)
        }
}
