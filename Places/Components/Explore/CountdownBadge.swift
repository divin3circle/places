//
//  CountdownBadge.swift
//  Places
//
//  Created by Sylus Abel on 03/08/2026.
//

import SwiftUI

/// A live countdown pill (days + HH:MM:SS) to a target date. Ticks every second
/// via `TimelineView` — no manual timers to manage.
struct CountdownBadge: View {
    let target: Date

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = max(0, Int(target.timeIntervalSince(context.date)))
            let days = remaining / 86_400
            let hours = (remaining % 86_400) / 3_600
            let minutes = (remaining % 3_600) / 60
            let seconds = remaining % 60

            HStack(spacing: 4) {
                Text("\(days)")
                    .foregroundStyle(.primary)
                Text(String(format: "%02d:%02d:%02d", hours, minutes, seconds))
                    .foregroundStyle(.secondary)
            }
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .monospacedDigit()
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color(.systemGray6), in: .capsule)
        }
    }
}

#Preview {
    CountdownBadge(target: Calendar.current.date(byAdding: .day, value: 120, to: Date())!)
}
