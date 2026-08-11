//
//  SettingsSection.swift
//  Places
//
//  Created by Sylus Abel on 03/08/2026.
//

import SwiftUI

/// Groups settings rows as a flat list on the plain background — no card, no
/// tinted fill, no dividers (Airbnb-style). Groups are separated by whitespace
/// from the parent stack. An optional subtle title can head the group.
struct SettingsSection<Content: View>: View {
  var title: String?
  @ViewBuilder var content: Content

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      if let title {
        Text(title)
          .font(.system(size: 13, weight: .semibold))
          .fontDesign(.rounded)
          .foregroundStyle(.secondary)
          .textCase(.uppercase)
          .padding(.bottom, 4)
      }

      VStack(spacing: 0) {
        content
      }
    }
  }
}

#Preview {
  ScrollView {
    VStack(spacing: 24) {
      SettingsSection {
        SettingsRow(icon: "person", title: "Personal information", accessory: .chevron, onTap: {})
        SettingsRow(icon: "shield", title: "Login & security", accessory: .chevron, onTap: {})
        SettingsRow(icon: "bell", title: "Notifications", accessory: .chevron, onTap: {})
      }
    }
    .padding(20)
  }
}
