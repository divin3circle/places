//
//  ExperienceDetailBody.swift
//  Places
//
//  Everything below the hero image on an experience detail. Shared by the pushed
//  `ExperienceDetailView` and the `DestinationTransition` morph, so the two entry
//  points render identical content.
//

import SwiftUI

struct ExperienceDetailBody: View {
    let experience: Experience
    /// The morph shows the title + rating on the hero image, so it hides them here.
    var showsTitle: Bool = true

    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            // The morph shows the title + rating on the hero image and the
            // container tucks the body's first rows under that hero, so we skip
            // this whole intro there (it would peek out awkwardly). The pushed
            // detail — which has a normal image gallery, not the morph — keeps it.
            if showsTitle {
                VStack(alignment: .leading, spacing: 10) {
                    Text(experience.title)
                        .font(.system(.title, design: .rounded).bold())

                    Text(experience.description)
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 6) {
                        Image(systemName: "star.fill").font(.footnote)
                        Text("\(experience.rating, format: .number.precision(.fractionLength(2)))")
                            .fontWeight(.semibold)
                        Text("·")
                        Text("\(experience.reviewsCount) reviews").underline()
                    }
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.primary)
                }

                Divider()
            }

            hostRow
            infoRow(icon: "mappin.and.ellipse", title: experience.locationName, subtitle: experience.locationArea)
            infoRow(icon: "clock", title: experience.durationLabel, subtitle: experience.language)

            if experience.freeCancellation {
                cancellationCard
            }

            priceBlock
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        // The morph tucks the body top under the pinned hero, so add clearance
        // there to keep the host row (48pt avatar is the tallest) from being
        // clipped. The pushed detail (real gallery, not the morph) needs none.
        .padding(.top, showsTitle ? 20 : 40)
    }

    private var hostRow: some View {
        HStack(spacing: 14) {
            RemoteImage(experience.hostImageName, width: 48, height: 48)
                .frame(width: 48, height: 48)
                .clipShape(.circle)
            VStack(alignment: .leading, spacing: 2) {
                Text("Hosted by \(experience.hostName)")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                Text(experience.hostTagline)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }

    private func infoRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(.primary)
                .frame(width: 48, height: 48)
                .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                Text(subtitle)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }

    private var cancellationCard: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Free cancellation")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                Text("Up to 1 day before start time")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Image(systemName: "calendar")
                .font(.system(size: 20))
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 18))
    }

    private var priceBlock: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 0) {
                Text("From \(experience.priceLabel)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Text("/ guest")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 12)
            Button("Show dates") {
                // For now, booking hands off to the provider's site (or a search).
                openURL(experience.bookingLink)
            }
            .buttonStyle(.appAccent)
            .frame(width: 160)
        }
        .padding(.top, 4)
    }
}

#Preview {
    ScrollView { ExperienceDetailBody(experience: Experience.preview) }
}
