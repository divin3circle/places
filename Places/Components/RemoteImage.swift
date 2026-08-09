//
//  RemoteImage.swift
//  Places
//
//  Drop-in for DownsampledAssetImage that auto-detects its source: an http(s)
//  URL renders remotely (disk-cached by SDWebImage); anything else is a local
//  asset name. Fills the frame the caller gives it — callers apply .frame/.clipShape,
//  exactly as they did with DownsampledAssetImage.
//

import SwiftUI
import SDWebImageSwiftUI

struct RemoteImage: View {
    let source: String
    var width: CGFloat
    var height: CGFloat

    init(_ source: String, width: CGFloat, height: CGFloat) {
        self.source = source
        self.width = width
        self.height = height
    }

    var body: some View {
        if source.hasPrefix("http"), let url = URL(string: source) {
            WebImage(url: url)
                .resizable()
                .indicator(.activity)
                .scaledToFill()
        } else {
            DownsampledAssetImage(name: source, width: width, height: height)
        }
    }
}
