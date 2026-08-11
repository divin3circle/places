//
//  DiscoveryCollectionCard.swift
//  Places
//
//  A tall editorial tile for the Explore "Collections" row: a gradient cover
//  with a big glyph, title, and one-line subtitle (Matter-style). Tapping opens
//  the collection's filtered destinations.
//

import SwiftUI

struct DiscoveryCollectionCard: View {
    let collection: DiscoveryCollection
    var width: CGFloat = 220
    var height: CGFloat = 260

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: collection.gradient,
                           startPoint: .topTrailing, endPoint: .bottomLeading)

            Image(systemName: collection.systemImage)
                .font(.system(size: 84, weight: .semibold))
                .foregroundStyle(.white.opacity(0.16))
                .rotationEffect(.degrees(-8))
                .offset(x: width * 0.32, y: -height * 0.18)

            LinearGradient(colors: [.clear, .black.opacity(0.35)],
                           startPoint: .center, endPoint: .bottom)

            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: collection.systemImage)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.bottom, 2)
                Text(collection.title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                Text(collection.subtitle)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(2)
            }
            .padding(18)
        }
        .frame(width: width, height: height)
        .clipShape(.rect(cornerRadius: 24, style: .continuous))
    }
}

#Preview {
    ScrollView(.horizontal) {
        HStack(spacing: 16) {
            ForEach(DiscoveryCollection.all) { DiscoveryCollectionCard(collection: $0) }
        }
        .padding()
    }
}
