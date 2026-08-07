//
//  ExploreDetailView.swift
//  Places
//
//  Created by Sylus Abel on 03/08/2026.
//

import SwiftUI

/// A modest destination/trip detail pushed from Explore cards. Uses the sample
/// `Destination` for the blurb + interest tags until real data is wired.
/// TODO: pass a real `Destination` once the catalog/backend exists.
struct ExploreDetailView: View {
    let title: String
    let imageName: String

    @State private var showCreate = false

    private var destination: Destination? { Destination.samples.first }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 260)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .clipShape(.rect(cornerRadius: 24))

                Text(title)
                    .font(.system(.title, design: .rounded).bold())
                    .fontWidth(.expanded)

                if let destination {
                    Text(destination.description)
                        .font(.system(size: 15, design: .rounded))
                        .foregroundStyle(.secondary)

                    tagCloud(for: destination)
                }

                PrimaryButton(title: "Plan this trip") { showCreate = true }
                    .padding(.top, 4)
            }
            .padding(.horizontal, 15)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCreate) { CreateTripView() }
    }

    @ViewBuilder
    private func tagCloud(for destination: Destination) -> some View {
        FlowLayout(spacing: 8) {
            ForEach(destination.interestTags, id: \.self) { tag in
                Text(destination.getUIFriendlyTag(tag).capitalized)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.accent.opacity(0.12), in: .capsule)
            }
        }
    }
}

/// Minimal wrapping layout for tag pills (SwiftUI `Layout`, iOS 16+).
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview {
    NavigationStack {
        ExploreDetailView(title: "Maasai Mara", imageName: "sample")
    }
}
