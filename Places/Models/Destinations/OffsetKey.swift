//
// OffsetKey.swift
// Places
// Created by Sylus Abel on 04/08/2026
//

import Foundation
import SwiftUI

struct OffsetKey: PreferenceKey {
  static var defaultValue: CGFloat = 0
  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = nextValue()
  }
}

extension View {
  @ViewBuilder
  func offset(completion: @escaping (CGFloat) -> Void) -> some View {
    self
      .overlay {
        GeometryReader {
          let minX = $0.frame(in: .scrollView).minX
          Color.clear
            .preference(key: OffsetKey.self, value: minX)
            .onPreferenceChange(
              OffsetKey.self,
              perform: { value in
                completion(value)
              })
        }
      }
  }
}

extension [PopularDestination] {
  func indexOf(_ card: PopularDestination) -> Int {
    return self.firstIndex(of: card) ?? 0
  }
}
