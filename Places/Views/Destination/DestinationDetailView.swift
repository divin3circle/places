//
//  DestinationDetailView.swift
//  Places
//
//  Rich destination page built on the resizable-header scaffold
//  (DestinationFullView): a collapsing hero that hands its title off to a compact
//  bar, then quick-fact stats, about, highlights, good-to-know, a map, and a
//  gallery, with a sticky "Plan this trip" bar. Arrangement follows common travel
//  place-detail patterns (Airbnb / Google Travel / Wanderlog).
//

import SwiftUI
import MapKit
import SwiftfulRouting
import SwiftData

struct DestinationDetailView: View {
    let destination: DestinationDTO

    @Environment(\.router) private var router
    @Environment(\.openURL) private var openURL
    @Environment(\.modelContext) private var context

    @Query private var savedPlaces: [SavedPlace]
    private var isSaved: Bool {
        savedPlaces.contains { $0.kind == "destination" && $0.refId == destination.id }
    }

    @State private var appeared = false
    @State private var showCreate = false
    @State private var pendingConfig: TripConfig?
    @State private var itineraryConfig: TripConfig?

    private let maxHeader: CGFloat = 380
    private let minHeader: CGFloat = 66

    var body: some View {
        DestinationFullView(
            minimumHeight: minHeader,
            maximumHeight: maxHeader,
            ignoresSafeAreaTop: true,
            isSticky: true
        ) { progress, safeArea in
            header(progress: progress, safeArea: safeArea)
        } content: {
            content
        }
        .background(Color(.systemBackground))
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom) { planBar }
        .task {
            // Small settle so the section reveal reads as intentional.
            try? await Task.sleep(for: .milliseconds(60))
            withAnimation(.snappy(duration: 0.5)) { appeared = true }
        }
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

    // MARK: Header (collapsing hero)

    private func header(progress: CGFloat, safeArea: EdgeInsets) -> some View {
        ZStack(alignment: .bottomLeading) {
            RemoteImage(destination.bannerUrl, width: 500, height: 500)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()

            // Darken toward the bottom (title legibility) and toward the top
            // (buttons + compact title), deepening as the header collapses.
            LinearGradient(
                colors: [.black.opacity(0.35 + progress * 0.3), .clear, .clear, .black.opacity(0.55)],
                startPoint: .top, endPoint: .bottom
            )
            .allowsHitTesting(false)

            // Expanded title block — fades out as the header collapses.
            VStack(alignment: .leading, spacing: 6) {
                Text(destination.name)
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                HStack(spacing: 8) {
                    Text(humanize(destination.category))
                    if let rating = destination.rating {
                        Text("·")
                        Label(String(format: "%.1f", rating), systemImage: "star.fill")
                            .foregroundStyle(.yellow)
                    }
                    Text("·")
                    Text(countryName(destination.countryCode))
                }
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 18)
            .opacity(1 - min(progress * 1.4, 1))

            // Top bar — back / compact title / save + share. Always visible.
            topBar(progress: progress)
                .padding(.top, safeArea.top)
                .frame(maxHeight: .infinity, alignment: .top)
        }
    }

    private func topBar(progress: CGFloat) -> some View {
        ZStack {
            // Compact title fades in as the hero title fades out. White + the top
            // scrim keeps it legible over any banner (light or dark).
            Text(destination.name)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .padding(.horizontal, 60)
                .opacity(max(progress * 1.6 - 0.6, 0))

            HStack {
                circleButton("chevron.left") { router.dismissScreen() }
                Spacer()
                circleButton(isSaved ? "bookmark.fill" : "bookmark") {
                    toggleSaved()
                }
                .foregroundStyle(isSaved ? .accent : .primary)
                ShareLink(item: "\(destination.name) — \(destination.description)") {
                    circleLabel("square.and.arrow.up")
                }
            }
            .padding(.horizontal, 15)
        }
        .frame(height: 44)
    }

    // MARK: Content

    private var content: some View {
        VStack(alignment: .leading, spacing: 26) {
            reveal(0) { quickFacts }
            reveal(1) { about }
            if !destination.interestTags.isEmpty { reveal(2) { highlights } }
            if hasGoodToKnow { reveal(3) { goodToKnow } }
            reveal(4) { locationSection }
            if !galleryImages.isEmpty { reveal(5) { gallery } }
        }
        .padding(.horizontal, 20)
        .padding(.top, 22)
        .padding(.bottom, 30)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // Quick-fact stat cards: rating · entry · best time.
    private var quickFacts: some View {
        HStack(spacing: 12) {
            if let rating = destination.rating {
                statCard(icon: "star.fill", value: String(format: "%.1f", rating), label: "Rating", tint: .yellow)
            }
            if let fee = feeValue {
                statCard(icon: "ticket.fill", value: fee, label: "Entry", tint: .accent)
            }
            if let best = shortBestTime {
                statCard(icon: "calendar", value: best, label: "Best time", tint: .accent)
            }
        }
    }

    private var about: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("About")
            Text(destination.description)
                .font(.system(size: 15, design: .rounded))
                .foregroundStyle(.secondary)
                .lineSpacing(3)
        }
    }

    private var highlights: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Highlights")
            FlowTags(tags: destination.interestTags.map(humanize))
        }
    }

    private var goodToKnow: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Good to know")
            VStack(spacing: 0) {
                infoRow("sun.max.fill", "Best season", destination.bestSeason)
                infoRow("airplane", "Closest hub", destination.closestHub)
                infoRow("car.fill", "Vehicle fees", destination.vehicleFeeGuidelines)
                infoRow("creditcard.fill", "Payments", destination.paymentInfrastructure)
            }
            .background(.thinMaterial, in: .rect(cornerRadius: 16, style: .continuous))
        }
    }

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Location")
            Button {
                openInMaps()
            } label: {
                Map(interactionModes: []) {
                    Marker(destination.name, coordinate: coordinate)
                }
                .frame(height: 170)
                .clipShape(.rect(cornerRadius: 16, style: .continuous))
                .overlay(alignment: .bottomTrailing) {
                    Label("Open in Maps", systemImage: "arrow.up.forward")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(.regularMaterial, in: .capsule)
                        .padding(10)
                }
            }
            .buttonStyle(PressableButtonStyle())
        }
    }

    private var gallery: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Gallery")
            ScrollView(.horizontal) {
                LazyHStack(spacing: 12) {
                    ForEach(Array(galleryImages.enumerated()), id: \.offset) { _, url in
                        RemoteImage(url, width: 260, height: 180)
                            .frame(width: 260, height: 180)
                            .clipShape(.rect(cornerRadius: 16, style: .continuous))
                            .transition(.opacity)
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)
            .padding(.horizontal, -20)
            .safeAreaPadding(.horizontal, 20)
        }
    }

    // Sticky bottom CTA — price + tickets + plan.
    private var planBar: some View {
        HStack(spacing: 12) {
            if let fee = feeValue {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Entry").font(.system(size: 11, design: .rounded)).foregroundStyle(.secondary)
                    Text(fee).font(.system(size: 16, weight: .bold, design: .rounded))
                }
            }
            Button {
                openURL(bookingLink)
            } label: {
                Image(systemName: "ticket.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 48, height: 48)
                    .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(PressableButtonStyle())

            PrimaryButton(title: "Plan this trip") { showCreate = true }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(.bar)
    }

    /// Booking/tickets link — the DB value, or a Google search fallback.
    private var bookingLink: URL {
        if let s = destination.bookingUrl, !s.isEmpty, let url = URL(string: s) { return url }
        let q = destination.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? destination.name
        return URL(string: "https://www.google.com/search?q=\(q)+tickets")!
    }

    // MARK: Building blocks

    private func statCard(icon: String, value: String, label: String, tint: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 16)).foregroundStyle(tint)
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .lineLimit(1).minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(.thinMaterial, in: .rect(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder
    private func infoRow(_ icon: String, _ label: String, _ value: String?) -> some View {
        if let value, !value.isEmpty {
            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 14)).foregroundStyle(.secondary)
                        .frame(width: 22)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(label)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                        Text(value)
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
                .padding(14)
            }
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 19, weight: .semibold, design: .rounded))
    }

    private func circleButton(_ systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { circleLabel(systemName) }
            .buttonStyle(PressableButtonStyle())
    }

    private func circleLabel(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 16, weight: .semibold))
            .frame(width: 40, height: 40)
            .background(.regularMaterial, in: .circle)
            .contentTransition(.symbolEffect(.replace))
    }

    // Staggered reveal for content sections.
    @ViewBuilder
    private func reveal<V: View>(_ index: Int, @ViewBuilder _ content: () -> V) -> some View {
        content()
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 14)
            .animation(.snappy(duration: 0.45).delay(Double(index) * 0.06), value: appeared)
    }

    // MARK: Data helpers

    private var coordinate: CLLocationCoordinate2D {
        .init(latitude: destination.latitude, longitude: destination.longitude)
    }

    private var galleryImages: [String] {
        destination.images.filter { !$0.isEmpty }
    }

    private var feeValue: String? {
        if let f = destination.feeLabel, !f.isEmpty { return f }
        if let usd = destination.nonResidentFeeUsd { return "$\(Int(usd))" }
        if let pr = destination.priceRange, !pr.isEmpty { return pr }
        return nil
    }

    private var shortBestTime: String? {
        guard let t = destination.bestTimeToVisit ?? destination.bestSeason, !t.isEmpty else { return nil }
        // Keep the stat compact — take the leading phrase before any separator.
        return t.split(whereSeparator: { ";,(".contains($0) }).first.map(String.init)?
            .trimmingCharacters(in: .whitespaces)
    }

    private var hasGoodToKnow: Bool {
        [destination.bestSeason, destination.closestHub,
         destination.vehicleFeeGuidelines, destination.paymentInfrastructure]
            .contains { ($0?.isEmpty == false) }
    }

    private func humanize(_ s: String) -> String {
        s.replacingOccurrences(of: "_", with: " ").capitalized
    }

    private func countryName(_ code: String) -> String {
        Locale.current.localizedString(forRegionCode: code) ?? code
    }

    private func toggleSaved() {
        if let existing = savedPlaces.first(where: { $0.kind == "destination" && $0.refId == destination.id }) {
            context.delete(existing)
        } else {
            context.insert(SavedPlace(destination: destination))
        }
        try? context.save()
    }

    private func openInMaps() {
        let q = destination.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "maps://?ll=\(destination.latitude),\(destination.longitude)&q=\(q)") {
            openURL(url)
        }
    }
}

/// Simple wrapping tag pills.
private struct FlowTags: View {
    let tags: [String]
    var body: some View {
        FlexWrap(spacing: 8, runSpacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.accent)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(.accent.opacity(0.12), in: .capsule)
            }
        }
    }
}

/// Minimal wrapping HStack (iOS 16+ Layout).
private struct FlexWrap: Layout {
    var spacing: CGFloat = 8
    var runSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > maxWidth { x = 0; y += rowHeight + runSpacing; rowHeight = 0 }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX { x = bounds.minX; y += rowHeight + runSpacing; rowHeight = 0 }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
