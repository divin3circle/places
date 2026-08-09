//
//  SplashView.swift
//  Places
//
//  Shown while the session is being restored at launch (phase == .booting),
//  so the user never sees a blank/frozen screen.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 18) {
                Image("places-icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 84, height: 84)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                ProgressView()
                    .tint(.secondary)
            }
        }
    }
}

#Preview {
    SplashView()
}
