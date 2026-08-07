//
//  HomeHeader.swift
//  Places
//
//  Created by Sylus Abel on 30/07/2026.
//

import SwiftUI

struct ChatsHeader: View {

  var body: some View {
    ZStack {
      HStack {
        Text("Messages")
              .font(.title3.bold())
              .fontDesign(.rounded)
          
        Spacer()
        HStack(spacing: 16) {
          Button {
          } label: {
            Image(systemName: "magnifyingglass")
              .font(.system(size: 22))
              .fontDesign(.rounded)
          }
          .compositingGroup()
          Button {
          } label: {
            Image(systemName: "gear")
              .font(.system(size: 22))
              .fontDesign(.rounded)
              .foregroundStyle(.foreground)
          }
        }
      }
      .padding(.bottom, 8)
    }
    .background(.background)
  }
}

#Preview {
  NavigationStack {
    ChatsHeader()
  }
}
