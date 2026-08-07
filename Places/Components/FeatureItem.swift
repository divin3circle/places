//
//  FeatureItem.swift
//  Places
//
//  Created by Sylus Abel on 27/07/2026.
//

import SwiftUI

struct FeatureItem: View {
    var feature: Feature
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .frame(width: 45, height: 45)
                    .foregroundStyle(feature.color.opacity(0.1))
                Image(systemName: feature.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(feature.color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(feature.title)
                    .font(.system(size: 18).bold())
                    .fontDesign(.rounded)
                    .fontWidth(.expanded)
                Text(feature.subtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(.gray)
                    .fontDesign(.rounded)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    FeatureItem(feature: Features.list[0])
        .padding(.horizontal, 30)
}
