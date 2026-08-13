//
//  ProfileTab.swift
//  Places
//
//  Created by Sylus Abel on 03/08/2026.
//

import SwiftUI

struct ProfileTab: View {
  @State private var isLargeHeader: Bool = false
  @State private var topInset: CGFloat = 0
  @State private var scrollPhase: ScrollPhase = .idle

  var body: some View {
    ScrollView(.vertical) {
      LazyVStack {
        ProfileSettingsList()
      }
      .padding(.bottom, 40)
      .safeAreaInset(edge: .top, spacing: 0) {
        ProfileHeader(isLargerHeader: $isLargeHeader, topInset: $topInset)

      }
    }
    .scrollIndicators(.hidden)
    .onScrollGeometryChange(for: CGFloat.self) {
      $0.contentInsets.top
    } action: { oldValue, newValue in
      topInset = newValue
    }
    .onScrollGeometryChange(for: CGFloat.self) {
      $0.contentOffset.y + $0.contentInsets.top
    } action: { oldValue, newValue in
      if scrollPhase == .interacting {
        withAnimation(.spring()) {
          isLargeHeader = newValue < -10 || (isLargeHeader && newValue < 0)
        }
      }
    }
    .onScrollPhaseChange { oldPhase, newPhase in
      scrollPhase = newPhase
    }
  }
}

#Preview {
  ProfileTab()
}
