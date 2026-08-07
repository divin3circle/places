//
//  ExperienceCategoryCard.swift
//  Places
//
//  A plain, equal-size category tile for the "Explore experiences nearby" row:
//  a rounded-square photo with the label below. Scannable, no animation.
//

import SwiftUI

struct ExperienceCategoryCard: View {
    let category: ExperienceCategory
    var side: CGFloat = 150

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            DownsampledAssetImage(name: category.imageName, width: side, height: side)
                .frame(width: side, height: side)
                .clipShape(.rect(cornerRadius: 20, style: .continuous))

            Text(category.label)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .frame(width: side, alignment: .leading)
        }
        .frame(width: side)
    }
}

#Preview {
    HStack(spacing: 14) {
        ExperienceCategoryCard(category: ExperienceCategory.all[0])
        ExperienceCategoryCard(category: ExperienceCategory.all[6])
    }
    .padding()
}
