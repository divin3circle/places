//
//  ItineraryPDF.swift
//  Places
//
//  Pro perk: export a saved itinerary as a shareable PDF. Renders a print-styled
//  SwiftUI page over `GeneratedItinerary` via `ImageRenderer` into a single
//  content-sized PDF page, and a small `UIActivityViewController` wrapper for the
//  share sheet.
//

import SwiftUI
import UIKit

/// Print-styled page for the exported PDF (A4 width).
struct ItineraryPDFPage: View {
    let itinerary: GeneratedItinerary
    let currency: Currency

    private static let pageWidth: CGFloat = 595   // A4 @ 72dpi

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text(itinerary.title)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                if !itinerary.summary.isEmpty {
                    Text(itinerary.summary)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            }

            ForEach(Array(itinerary.days.enumerated()), id: \.offset) { i, day in
                VStack(alignment: .leading, spacing: 8) {
                    Text("Day \(i + 1) · \(day.title)")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.accent)
                    if !day.subtitle.isEmpty {
                        Text(day.subtitle).font(.system(size: 12)).foregroundStyle(.secondary)
                    }
                    ForEach(Array(day.activities.enumerated()), id: \.offset) { _, act in
                        HStack(alignment: .top, spacing: 8) {
                            Text((act.startTime?.isEmpty == false ? act.startTime! : "•"))
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .frame(width: 46, alignment: .leading)
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(alignment: .firstTextBaseline) {
                                    Text(act.title).font(.system(size: 13, weight: .semibold))
                                    Spacer(minLength: 8)
                                    if let price = act.displayPrice(in: currency) {
                                        Text(price).font(.system(size: 12)).foregroundStyle(.secondary)
                                    }
                                }
                                if !act.description.isEmpty {
                                    Text(act.description).font(.system(size: 12)).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    Divider()
                }
            }

            Text("Made with Places").font(.system(size: 10)).foregroundStyle(.tertiary)
        }
        .padding(28)
        .frame(width: Self.pageWidth, alignment: .leading)
        .background(.white)
    }
}

/// Render an itinerary to a temporary PDF file. Returns nil on failure.
@MainActor
func renderItineraryPDF(_ itinerary: GeneratedItinerary, currency: Currency) -> URL? {
    let renderer = ImageRenderer(content: ItineraryPDFPage(itinerary: itinerary, currency: currency))
    renderer.proposedSize = ProposedViewSize(width: 595, height: nil)

    let safeName = (itinerary.title.isEmpty ? "Itinerary" : itinerary.title)
        .replacingOccurrences(of: "/", with: "-")
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(safeName).pdf")

    var success = false
    renderer.render { size, renderInContext in
        var box = CGRect(origin: .zero, size: size)
        guard let consumer = CGDataConsumer(url: url as CFURL),
              let ctx = CGContext(consumer: consumer, mediaBox: &box, nil) else { return }
        ctx.beginPDFPage(nil)
        renderInContext(ctx)
        ctx.endPDFPage()
        ctx.closePDF()
        success = true
    }
    return success ? url : nil
}

/// Identifiable wrapper so a URL can drive `.sheet(item:)`.
struct ShareItem: Identifiable {
    let id = UUID()
    let url: URL
}

/// Minimal share-sheet wrapper.
struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
