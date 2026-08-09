import Testing
import UIKit
@testable import Places

@MainActor
struct AvatarImageTests {
    private func solidImage(_ side: CGFloat) -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: side, height: side)).image { ctx in
            UIColor.systemBlue.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: side, height: side))
        }
    }

    @Test func downscalesLargeImage() {
        let data = AvatarImage.jpegData(from: solidImage(1200))
        #expect(data != nil)
        let out = UIImage(data: data!)!
        #expect(max(out.size.width, out.size.height) <= 512)
    }

    @Test func keepsSmallImageWithinBound() {
        let data = AvatarImage.jpegData(from: solidImage(200))
        let out = UIImage(data: data!)!
        #expect(max(out.size.width, out.size.height) <= 512)
    }
}
