//
//  ExploreSearchBar.swift
//  Places
//
//  Created by Sylus Abel on 03/08/2026.
//

import SwiftUI

/// The glassy search field embedded in the Explore hero. Filtering is done
/// locally by the parent for now (no backend).
struct ExploreSearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search by atmosphere, or destination", text: $text)
                .font(.system(size: 15, design: .rounded))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(.regularMaterial, in: .capsule)
        .overlay(Capsule().stroke(.white.opacity(0.25), lineWidth: 1))
        .animation(.snappy(duration: 0.2), value: text.isEmpty)
    }
}

#Preview {
    ExploreSearchBar(text: .constant(""))
        .padding()
        .background(.black)
}
