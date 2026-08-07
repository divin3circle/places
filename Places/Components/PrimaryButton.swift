//
//  PrimaryButton.swift
//  Places
//
//  Created by Sylus Abel on 28/07/2026.
//

import SwiftUI

struct PrimaryButton: View {
  var title: String
  var action: () -> Void
  var body: some View {
    Button(action: action) {
      Text(title)
        .bold()
        .frame(height: 55)
        .frame(maxWidth: .infinity)
        .background(.accent, in: Capsule())
        .tint(.white)
    }
  }
}

#Preview {
  PrimaryButton(title: "Login", action: {})
}
