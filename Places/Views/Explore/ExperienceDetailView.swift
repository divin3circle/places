//
//  ExperienceDetailView.swift
//  Places
//
//  Standalone, pushable experience detail: a paged image gallery on top, then the
//  shared `ExperienceDetailBody`. Pushed from the category list rows. (The Home
//  "Popular experiences" row reaches the same content via a DestinationTransition
//  morph instead.)
//

import SwiftUI

struct ExperienceDetailView: View {
    let experience: Experience

    private let galleryHeight: CGFloat = 340

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                gallery
                ExperienceDetailBody(experience: experience)
            }
        }
        .scrollIndicators(.hidden)
        .ignoresSafeArea(edges: .top)
    }

    // Paged hero that stretches on pull-down (grows downward, pinned at the top).
    private var gallery: some View {
        GeometryReader { proxy in
            let minY = proxy.frame(in: .global).minY
            let stretch = max(0, minY)
            TabView {
                ForEach(experience.imageNames, id: \.self) { name in
                    RemoteImage(name, width: 400, height: galleryHeight)
                        .frame(maxWidth: .infinity)
                        .frame(height: galleryHeight + stretch)
                        .clipped()
                }
            }
            .frame(width: proxy.size.width, height: galleryHeight + stretch)
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .offset(y: -stretch)
        }
        .frame(height: galleryHeight)
    }
}

#Preview {
    ExperienceDetailView(experience: Experience.preview)
}
