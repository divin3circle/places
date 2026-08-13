//
//  HomeHeader.swift
//  Places
//
//  Created by Sylus Abel on 30/07/2026.
//

import SwiftUI

struct HomeHeader: View {
  var onProfileTap: () -> Void = {}
  @Environment(SessionStore.self) private var session: SessionStore?
  @Environment(TokenStore.self) private var tokens: TokenStore?
  @State private var showCoins = false

  var body: some View {
    ZStack {
      HStack {
        Button {
          onProfileTap()
        } label: {
          Group {
            if let url = session?.currentProfile?.avatarURL, !url.isEmpty {
              RemoteImage(url, width: 38, height: 38)
            } else {
              Image("profile")
                .resizable()
                .scaledToFill()
            }
          }
          .frame(width: 38, height: 38)
          .clipShape(Circle())
          .overlay {
            Circle()
              .stroke(.gray.opacity(0.1), lineWidth: 1)
          }
        }
        .buttonStyle(.plain)
        Spacer()
        Button {
          showCoins = true
        } label: {
          HStack(spacing: 5) {
            Image("TokenCoin")
              .resizable()
              .scaledToFit()
              .frame(width: 22, height: 22)
            if let balance = tokens?.balance {
              Text("\(balance)")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
            }
          }
          .padding(.leading, 10)
          .padding(.trailing, 12)
          .padding(.vertical, 6)
          .background(Color(.secondarySystemBackground), in: .capsule)
        }
        .compositingGroup()
      }
      .padding(.bottom, 8)
    }
    .background(.background)
    .sheet(isPresented: $showCoins) { CoinShopView() }
    .task { await tokens?.refresh() }
  }
}

#Preview {
  NavigationStack {
    HomeHeader()
  }
}
