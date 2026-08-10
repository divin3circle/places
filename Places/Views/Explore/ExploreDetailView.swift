//
//  ExploreDetailView.swift
//  Places
//
//  Created by Sylus Abel on 03/08/2026.
//

import SwiftUI
import SDWebImageSwiftUI

/// Destination detail pushed from Explore/Home cards. Opened from a live
/// `DestinationDTO` it renders real data (description, fee, tags); the lightweight
/// `title/imageName` init (e.g. a saved trip's cover tap) shows only what it knows
/// — no fabricated blurb/tags.
struct ExploreDetailView: View {
    let title: String
    let imageName: String
    private let dto: DestinationDTO?

    @State private var showCreate = false
    @State private var pendingConfig: TripConfig?
    @State private var itineraryConfig: TripConfig?

    init(title: String, imageName: String) {
        self.title = title
        self.imageName = imageName
        self.dto = nil
    }

    init(destination: DestinationDTO) {
        self.title = destination.name
        self.imageName = destination.bannerUrl
        self.dto = destination
    }

    private var blurb: String? { dto?.description }
    private var tags: [String] { dto?.interestTags ?? [] }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                heroImage
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 260)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .clipShape(.rect(cornerRadius: 24))

                Text(title)
                    .font(.system(.title, design: .rounded).bold())
                    .fontWidth(.expanded)

                if let fee = dto?.feeLabel {
                    Label("Entry: \(fee)", systemImage: "ticket")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                if let blurb {
                    Text(blurb)
                        .font(.system(size: 15, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                if !tags.isEmpty {
                    tagCloud(tags)
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
        .sheet(isPresented: $showCreate, onDismiss: {
            if let pendingConfig {
                itineraryConfig = pendingConfig
                self.pendingConfig = nil
            }
        }) {
            CreateTripSheet(onGenerate: { config in
                pendingConfig = config
                showCreate = false
            })
        }
        .fullScreenCover(item: $itineraryConfig) { config in
            GenerateItineraryView(config: config)
        }
    }

    @ViewBuilder
    private var heroImage: some View {
        if imageName.hasPrefix("http"), let url = URL(string: imageName) {
            WebImage(url: url).resizable().indicator(.activity)
        } else {
            Image(imageName).resizable()
        }
    }

    @ViewBuilder
    private func tagCloud(_ tags: [String]) -> some View {
        FlowLayout(spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Text(tag.replacingOccurrences(of: "_", with: " ").capitalized)
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
