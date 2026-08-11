//
//  ExperienceCard.swift
//  Places
//
//  Building blocks for the "Popular experiences" feed row:
//  - `ExperienceHero`: the photo with a "Trending" pill and a save button. Used
//    on its own as the morphing hero inside `DestinationTransition`.
//  - `ExperienceCaption`: the title + price/rating line shown BELOW the photo
//    (Airbnb text-below anatomy).
//

import SwiftUI

/// Photo + overlays only. Fills the frame it's given so it can morph cleanly.
/// When `expanded` (inside the `DestinationTransition` detail), it shows the
/// title + rating on the image instead of the card's Trending pill / bookmark —
/// the container slides the body's first line under the hero, so the title has
/// to live here to stay visible.
struct ExperienceHero: View {
    let experience: Experience
    var cornerRadius: CGFloat = 16
    var expanded: Bool = false
    var isSaved: Bool = false
    var onToggleSave: (() -> Void)? = nil

    var body: some View {
        RemoteImage(experience.coverImage, width: 320, height: 240)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipShape(.rect(cornerRadius: cornerRadius, style: .continuous))
            .overlay(alignment: .topLeading) {
                if experience.isTrending && !expanded {
                    Text("Trending")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: .capsule)
                        .padding(10)
                }
            }
            .overlay(alignment: .topTrailing) {
                if let onToggleSave, !expanded {
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
            .overlay(alignment: .bottomLeading) {
                if expanded {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(experience.title)
                            .font(.system(.title2, design: .rounded).bold())
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill").font(.footnote)
                            Text("\(experience.rating, format: .number.precision(.fractionLength(2))) · \(experience.reviewsCount) reviews")
                        }
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.white.opacity(0.95))
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        LinearGradient(colors: [.clear, .black.opacity(0.65)],
                                       startPoint: .center, endPoint: .bottom)
                    )
                }
            }
    }
}

/// Title + "From KSh X / guest · ★ rating" — sits under the photo.
struct ExperienceCaption: View {
    let experience: Experience
    var width: CGFloat = 300

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(experience.title)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(2)
            Text("From \(experience.priceLabel) / guest · ★ \(experience.rating, format: .number.precision(.fractionLength(2)))")
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(width: width, alignment: .leading)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 8) {
        ExperienceHero(experience: Experience.preview, isSaved: true, onToggleSave: {})
            .frame(width: 300, height: 210)
        ExperienceCaption(experience: Experience.preview)
    }
    .padding()
}
