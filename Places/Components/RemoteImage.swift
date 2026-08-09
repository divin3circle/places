//
//  RemoteImage.swift
//  Places
//
//  Auto-detects source: an http(s) URL renders remotely (disk-cached by
//  SDWebImage); anything else is a local asset name. Content always passes URLs;
//  the local branch remains only for genuinely-local imagery.
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
                .transition(.fade(duration: 0.25))
                .scaledToFill()
                .frame(width: width, height: height)
                .clipped()
        } else {
            DownsampledAssetImage(name: source, width: width, height: height)
        }
    }
}
