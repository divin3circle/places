//
//  PrimaryButton.swift
//  Places
//
//  Created by Sylus Abel on 28/07/2026.
//

import SwiftUI

struct PrimaryButton: View {
  var title: String
  /// Defaults to accent (reserved for primary conversion / generate actions like
  /// "Plan this trip"). Onboarding navigation buttons pass `.appPrimary` so only
  /// true conversion CTAs stay coral.
  var kind: AppButtonKind = .appAccent
  var action: () -> Void
  var body: some View {
    Button(action: action) {
      Text(title)
    }
    .buttonStyle(AppButtonStyle(kind: kind, minHeight: 55))
  }
}

#Preview {
  VStack(spacing: 14) {
    PrimaryButton(title: "Plan this trip", action: {})
    PrimaryButton(title: "Continue", kind: .appPrimary, action: {})
  }
  .padding()
}
