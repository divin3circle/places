//
//  AvatarImage.swift
//  Places
//
//  Downscale + JPEG-encode a picked photo before uploading it as an avatar.
//

import UIKit

enum AvatarImage {
    /// Aspect-fit downscale to `maxDimension`, then JPEG-encode.
    static func jpegData(from image: UIImage, maxDimension: CGFloat = 512, quality: CGFloat = 0.8) -> Data? {
        let longest = max(image.size.width, image.size.height)
        let scale = longest > maxDimension ? maxDimension / longest : 1
        let target = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        return resized.jpegData(compressionQuality: quality)
    }
}
