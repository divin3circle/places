//
//  ImageLoader.swift
//  Places
//
//  Created by Sylus Abel on 27/07/2026.
//

import SwiftUI
import SDWebImageSwiftUI

struct ImageLoader: View {
    let isOnlineImage: Bool
    let localImageName: String?
    let onlineImageUrl: String?
    var resizeMode: ContentMode = .fit
    
    init(
        isOnlineImage: Bool,
        localImageName: String?,
        localImageExtension: String?,
        onlineImageUrl: String?,
        resizeMode: ContentMode
    ) {
        self.isOnlineImage = isOnlineImage
        self.localImageName = localImageName
        self.onlineImageUrl = onlineImageUrl
        self.resizeMode = resizeMode
    }
    
    var body: some View {
        Group {
            if isOnlineImage {
                WebImage(url: URL(string: onlineImageUrl ?? ImageLoader.fallbackImage))
                    .resizable()
            } else if let localImageName {
                Image(localImageName)
                    .resizable()
            } else {
                WebImage(url: URL(string: ImageLoader.fallbackImage))
                    .resizable()
            }
        }
        .aspectRatio(contentMode: resizeMode)
    }
}

extension ImageLoader {
    static var fallbackImage: String {
        "https://picsum.photos/200/300"
    }
}

#Preview {
    ImageLoader(
        isOnlineImage: false,
        localImageName: "onboarding1",
        localImageExtension: "jpg",
        onlineImageUrl: nil,
        resizeMode: .fit
    )
    
    ImageLoader(
        isOnlineImage: true,
        localImageName: nil,
        localImageExtension: nil,
        onlineImageUrl: "https://picsum.photos/200/300",
        resizeMode: .fill
    )
}
