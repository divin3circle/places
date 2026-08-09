//
//  ExperienceRow.swift
//  Places
//
//  A horizontal list row for the category list screen: thumbnail on the left,
//  title + meta + price on the right, with a save button on the image.
//

import SwiftUI

struct ExperienceRow: View {
    let experience: Experience
    var isSaved: Bool = false
    var onToggleSave: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            DownsampledAssetImage(name: experience.coverImage, width: 118, height: 118)
                .frame(width: 118, height: 118)
                .clipShape(.rect(cornerRadius: 16, style: .continuous))
                .overlay(alignment: .topLeading) {
                    if experience.isTrending {
                        Text("Trending")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial, in: .capsule)
                            .padding(6)
                    }
                }
                .overlay(alignment: .topTrailing) {
                    if let onToggleSave {
                        Button(action: onToggleSave) {
                            Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(isSaved ? Color.accentColor : .white)
                                .contentTransition(.symbolEffect(.replace))
                                .shadow(color: .black.opacity(0.35), radius: 3, y: 1)
                                .frame(width: 34, height: 34)
                                .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .padding(2)
                    }
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(experience.title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                Text("\(experience.categoryLabel) · \(experience.durationLabel.replacingOccurrences(of: "Around ", with: "").replacingOccurrences(of: " experience", with: ""))")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.secondary)
                Text("★ \(experience.rating, format: .number.precision(.fractionLength(2))) · \(experience.reviewsCount) reviews")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.secondary)
                Text("From \(experience.priceLabel) / guest")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.primary)
                    .padding(.top, 2)
            }

            Spacer(minLength: 0)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ExperienceRow(experience: Experience.preview, onToggleSave: {})
        ExperienceRow(experience: Experience.preview, isSaved: true, onToggleSave: {})
    }
    .padding()
}
