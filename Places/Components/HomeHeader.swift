//
//  HomeHeader.swift
//  Places
//
//  Created by Sylus Abel on 30/07/2026.
//

import SwiftUI

struct HomeHeader: View {
  var onProfileTap: () -> Void = {}

  var body: some View {
    ZStack {
      HStack {
        Button {
          onProfileTap()
        } label: {
          Image("profile")
            .resizable()
            .scaledToFill()
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
          } label: {
            Image(systemName: "centsign.circle")
              .font(.system(size: 22))
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
  }
}

#Preview {
  NavigationStack {
    HomeHeader()
  }
}
