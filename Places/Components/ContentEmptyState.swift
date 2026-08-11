//
//  ContentEmptyState.swift
//  Places
//
//  Shown inside a section when its fetch returns zero rows.
//

import SwiftUI

struct ContentEmptyState: View {
    var icon: String = "tray"
    var message: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(message)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}
