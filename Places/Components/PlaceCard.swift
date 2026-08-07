//
//  PlaceCard.swift
//  Places
//
//

import SwiftUI

struct PlaceCard: View {
    let image: String
    let title: String
    let subtitle: String
    var badge: String? = nil
    var width: CGFloat = 260
    var imageHeight: CGFloat = 190
    var isSaved: Bool = false
    var onToggleSave: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            DownsampledAssetImage(name: image, width: width, height: imageHeight)
                .frame(width: width, height: imageHeight)
                .clipShape(.rect(cornerRadius: 16, style: .continuous))
                .overlay(alignment: .topLeading) {
                    if let badge {
                        Text(badge.uppercased())
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(0.5)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.ultraThinMaterial, in: .capsule)
                            .padding(10)
                    }
                }
                .overlay(alignment: .topTrailing) {
                    if let onToggleSave {
                        Button(action: onToggleSave) {
                            Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(isSaved ? Color.accentColor : .white)
                                .contentTransition(.symbolEffect(.replace))
                                .shadow(color: .black.opacity(0.35), radius: 3, y: 1)
                                .frame(width: 40, height: 40)
                                .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .padding(4)
                    }
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(width: width, alignment: .leading)
        }
        .frame(width: width)
    }
}

#Preview {
    HStack(spacing: 14) {
        PlaceCard(image: "onboarding1", title: "Maasai Mara", subtitle: "Safari · ★ 4.9")
        PlaceCard(image: "onboarding2", title: "Serengeti", subtitle: "Wildlife · ★ 4.8", badge: "Sponsored")
    }
    .padding()
}
