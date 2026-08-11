//
//  ProgressViewer.swift
//  Places
//
//  Created by Sylus Abel on 28/07/2026.
//

import SwiftUI

struct ProgressViewer: View {
    var steps: Int
    @Binding var currentStep: Int

    private var spacing: CGFloat { 4 }

    var body: some View {
        GeometryReader { geometry in
            let segmentWidth = (geometry.size.width - spacing * CGFloat(steps - 1)) / CGFloat(steps)

            HStack(spacing: spacing) {
                ForEach(0..<steps, id: \.self) { step in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.gray.opacity(0.3))
                            .frame(width: segmentWidth, height: 5)

                        Capsule()
                            .fill(.foreground)
                            .frame(
                                width: currentStep >= step ? segmentWidth : 0,
                                height: 5
                            )
                    }
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: currentStep)
        }
        .frame(height: 6)
    }
}
