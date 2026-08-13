//
//  OfflineBanner.swift
//  Places
//
//  Slim status strip pinned under the status bar when the device is offline.
//  Airbnb-style: the app stays usable on cached/local content; this just tells
//  the user why fresh content isn't loading.
//

import SwiftUI

struct OfflineBanner: View {
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 12, weight: .semibold))
            Text("You're offline — showing saved content")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.darkGray))
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

#Preview {
    VStack { OfflineBanner(); Spacer() }
}
