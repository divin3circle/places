//
// SectionHeader.swift
// Places
//
// Created by Sylus Able on 04/08/2026
//

import SwiftUI

struct SectionHeader: View {
  var title: String = "Section Title"
  var hasButton: Bool = false
  var action: (() -> Void)? = {}
  var buttonText: String? = "View all"

  var body: some View {
    HStack {
      Text(title)
        .font(.title3.bold())
        .fontDesign(.rounded)
        .fontWidth(.expanded)

      if hasButton {
        Spacer(minLength: 0)

        Button {
          action?()
        } label: {
          HStack {
            if let buttonText {
              Text(buttonText)
                .font(.callout)
                .fontDesign(.rounded)
            }
            Image(systemName: "chevron.right")
              .font(.callout)
              .fontDesign(.rounded)
          }
        }
        .foregroundStyle(.secondary)
      } else {
        Spacer()
      }
    }
  }

}
