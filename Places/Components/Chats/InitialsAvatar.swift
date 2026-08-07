//
//  InitialsAvatar.swift
//  Places
//
//  A colored circle with a participant's initial — the avatar fallback while we
//  have no per-person photos. The `.background` ring keeps it legible when it
//  overlaps a trip cover.
//

import SwiftUI

struct InitialsAvatar: View {
    let initial: String
    let color: Color
    var size: CGFloat = 34
    var ringWidth: CGFloat = 2

    var body: some View {
        Text(initial)
            .font(.system(size: size * 0.42, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(color, in: .circle)
            .overlay(Circle().stroke(Color(.systemBackground), lineWidth: ringWidth))
    }
}

#Preview {
    HStack {
        InitialsAvatar(initial: "P", color: .blue)
        InitialsAvatar(initial: "M", color: .orange, size: 44)
    }
    .padding()
}
