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

    private var gallery: some View {
        TabView {
            ForEach(experience.imageNames, id: \.self) { name in
                DownsampledAssetImage(name: name, width: 400, height: 340)
                    .frame(maxWidth: .infinity)
                    .frame(height: 340)
                    .clipped()
            }
        }
        .frame(height: 340)
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }
}

#Preview {
    ExperienceDetailView(experience: Experience.preview)
}
