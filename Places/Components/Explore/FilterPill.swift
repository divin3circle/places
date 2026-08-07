//
//  FilterPill.swift
//  Places
//
//  Created by Sylus Abel on 03/08/2026.
//

import SwiftUI

/// A horizontal capsule filter chip (icon + label) used in the Explore filter
/// row. Accent-filled when selected, with a springy selection animation.
struct FilterPill: View {
    var icon: String?
    var label: String
    var isSelected: Bool
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                }
                Text(label)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(isSelected ? Color(.systemBackground) : .primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background {
                Capsule()
                    .fill(isSelected ? AnyShapeStyle(Color.primary) : AnyShapeStyle(Color(.systemGray6)))
            }
        }
        .buttonStyle(.plain)
        .animation(.snappy(duration: 0.25), value: isSelected)
    }
}

#Preview {
    HStack {
        FilterPill(icon: "binoculars.fill", label: "Safari", isSelected: true, onTap: {})
        FilterPill(icon: "sun.max.fill", label: "Beaches", isSelected: false, onTap: {})
    }
    .padding()
}
