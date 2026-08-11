//
//  DownsampledAssetImage.swift
//  Places
//
//  Created by Sylus Abel on 04/08/2026.
//

import SwiftUI
import UIKit

/// Renders a bundled asset image downsampled to its on-screen size, decoded on a
/// background thread. The travel photos in the catalog are ~4000×6000 (up to
/// ~70 MP); drawing them with `Image(name).resizable()` at card size forces a
/// full-resolution decode on the main thread, which stalls first appearance of
/// any screen that shows several at once (the Explore-tab hang). Decoding to the
/// display size off-main keeps the UI responsive, and thumbnails are cached so
/// later appearances are instant.
struct DownsampledAssetImage: View {
    let name: String
    /// The point size the image is displayed at — used to pick a decode target.
    let width: CGFloat
    let height: CGFloat
    var contentMode: ContentMode = .fill
    /// Fill shown while the background decode runs. Pass `.clear` when a colored
    /// base sits behind the image (e.g. a sponsor's accent tint) so no grey flashes.
    var placeholderColor: Color = Color(.secondarySystemBackground)

    @State private var thumbnail: UIImage?

    var body: some View {
        Group {
            if let thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                // Brief placeholder while the background decode runs.
                Rectangle()
                    .fill(placeholderColor)
            }
        }
        .task(id: name) { await load() }
    }

    private func load() async {
        // `.task` runs on the MainActor, so reading the screen scale here is safe.
        let scale = UIScreen.main.scale
        let target = CGSize(width: width * scale, height: height * scale)
        let key = "\(name)@\(Int(target.width))x\(Int(target.height))" as NSString

        if let cached = ThumbnailCache.shared.object(forKey: key) {
            thumbnail = cached
            return
        }

        let decoded = await Task.detached(priority: .userInitiated) { () -> UIImage? in
            guard let full = UIImage(named: name) else { return nil }
            return full.preparingThumbnail(of: target) ?? full
        }.value

        guard let decoded else { return }
        ThumbnailCache.shared.setObject(decoded, forKey: key)
        thumbnail = decoded
    }
}

/// Process-wide cache of decoded thumbnails, keyed by name + pixel size.
private enum ThumbnailCache {
    static let shared = NSCache<NSString, UIImage>()
}
