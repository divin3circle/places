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
        HStack(spacing: 16) {
          Button {
            showCoins = true
          } label: {
            HStack(spacing: 5) {
              Image(systemName: "centsign.circle")
                .font(.system(size: 22))
              if let balance = tokens?.balance {
                Text("\(balance)")
                  .font(.system(size: 15, weight: .semibold, design: .rounded))
                  .contentTransition(.numericText())
              }
            }
            .fontDesign(.rounded)
            .foregroundStyle(.accent)
          }
          .compositingGroup()
          Button {
          } label: {
            Image(systemName: "bell")
              .font(.system(size: 22))
              .fontDesign(.rounded)
              .foregroundStyle(.foreground)
          }
          .overlay(
            Circle()
              .fill(.accent)
              .frame(width: 8, height: 8)
              .background(Color.red)
              .clipShape(Circle())
              .offset(x: -3, y: 4),
            alignment: .topTrailing
          )
        }
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
