//
//  SettingsRow.swift
//  Places
//
//  Created by Sylus Abel on 03/08/2026.
//

import SwiftUI

/// Trailing accessory shown on the right edge of a `SettingsRow`.
enum SettingsRowAccessory {
  case none
  case chevron
  case externalLink
  case value(String)
  case badge(text: String, tint: Color)
}

/// A single tappable settings row. Mirrors the `FeatureItem` aesthetic:
/// a 38pt tinted circle with an SF Symbol, a rounded title, and an optional
/// trailing accessory (chevron / external-link arrow / value / badge).
struct SettingsRow: View {
  var icon: String
  var iconColor: Color = .primary
  var title: String
  var accessory: SettingsRowAccessory = .none
  var onTap: (() -> Void)? = nil

  var body: some View {
    Button {
      onTap?()
    } label: {
      HStack(spacing: 18) {
        Image(systemName: icon)
          .font(.system(size: 22, weight: .regular))
          .foregroundStyle(iconColor)
          .frame(width: 30, alignment: .leading)

        Text(title)
          .font(.system(size: 17))
          .fontDesign(.rounded)
          .foregroundStyle(.primary)

        Spacer(minLength: 8)

        accessoryView
      }
      .padding(.vertical, 16)
      .contentShape(.rect)
    }
    .buttonStyle(.plain)
    .disabled(onTap == nil)
  }

  @ViewBuilder
  private var accessoryView: some View {
    switch accessory {
    case .none:
      EmptyView()
    case .chevron:
      Image(systemName: "chevron.right")
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(.tertiary)
    case .externalLink:
      Image(systemName: "arrow.up.right")
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(.tertiary)
    case .value(let text):
      Text(text)
        .font(.system(size: 16))
        .fontDesign(.rounded)
        .foregroundStyle(.secondary)
        .lineLimit(1)
    case .badge(let text, let tint):
      Text(text)
        .font(.system(size: 13, weight: .semibold))
        .fontDesign(.rounded)
        .foregroundStyle(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(tint.opacity(0.12), in: .capsule)
    }
  }
}

#Preview {
  VStack(spacing: 0) {
    SettingsRow(icon: "envelope.fill", title: "Email", accessory: .value("sylusabl@icloud.com"))
    SettingsRow(
      icon: "shippingbox.fill", iconColor: .accent, title: "Current plan",
      accessory: .badge(text: "Pro", tint: .accent))
    SettingsRow(
      icon: "airplane", iconColor: .accent, title: "My Trips", accessory: .chevron, onTap: {})
    SettingsRow(
      icon: "doc.text.fill", title: "Terms of Service", accessory: .externalLink, onTap: {})
  }
  .padding(.horizontal, 20)
}
