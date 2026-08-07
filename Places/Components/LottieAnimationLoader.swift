//
//  LottieAnimationLoader.swift
//  Places
//
//  Created by Sylus Abel on 27/07/2026.
//

import SwiftUI
import DotLottie

struct LottieAnimationLoader: View {
    var fileName: String = "feature-animation1"
    var contentMode: UIView.ContentMode = .scaleAspectFill
    var loop: Bool = false
    var loopCount: Int?
    var autoPlay: Bool = false
    
    var body: some View {
        DotLottieAnimation(
            fileName: self.fileName,
            config: AnimationConfig(
                autoplay: autoPlay,
                loop: self.loop,
                loopCount: self.loopCount
            )
        )
        .view()
    }
}

#Preview {
    LottieAnimationLoader()
}
