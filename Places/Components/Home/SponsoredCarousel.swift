//
// SponsoredCarousel.swift
// Places
//
// Created by Sylus Abel on 05/08/2026
//

import SwiftUI

struct SponsoredCarousel: View {
    @EnvironmentObject var model: SponsoredViewModel
    var width = UIScreen.main.bounds.width
    /// Shared with the full-screen `SponsoredDetails` (hosted by `AppTab`) so the
    /// tapped card morphs into the detail via `matchedGeometryEffect`.
    var animation: Namespace.ID

  var body: some View {
      ZStack {
          VStack {
              ZStack {
                  ForEach(model.cards.indices.reversed(),id: \.self) { index in
                      HStack {
                          SponsoredCardView(card: model.cards[index], animation: animation)
                              .frame(width: getCardWidth(index: index), height: getCardHeight(index: index), alignment: .center)
                              .offset(x: getCadOffset(index: index))
                              .rotationEffect(.init(degrees: getCardRotation(index: index)))
                          
                          Spacer(minLength: 0)
                      }
                      .frame(height: 400)
                      .contentShape(Rectangle())
                      .offset(x: model.cards[index].offset)
                      .gesture(DragGesture(minimumDistance: 0)
                          .onChanged({ (value ) in
                          onChanged(value: value, index: index)
                          })
                              .onEnded({ (value ) in
                              onEnd(value: value, index: index)
                              })
                      
                      )
                  }
              }
              .padding(.top, 4)
              .padding(.horizontal, 30)
              Button {
                  resetView()
              } label: {
                  Image(systemName: "chevron.left")
                      .font(.system(size: 20, weight: .semibold))
                      .foregroundStyle(.accent)
                      .padding()
                      .background(.thinMaterial)
                      .clipShape(Circle())
                      .shadow(radius: 3)
              }
              .padding(.top, 35)
              Spacer()
          }
      }
  }
    
    private func resetView() {
        for index in model.cards.indices {
            withAnimation {
                model.cards[index].offset = 0
                model.swippedCard = 0
            }
        }
    }
    
    private func onChanged(value: DragGesture.Value, index: Int) {
        if value.translation.width < 0 {
            model.cards[index].offset = value.translation.width
        }
    }
    
    private func onEnd(value: DragGesture.Value, index: Int) {
        withAnimation {
            if -value.translation.width > width / 3 {
                model.cards[index].offset = -width
                model.swippedCard += 1
            } else {
                model.cards[index].offset = 0
            }
        }
    }
    
    private func getCardRotation(index: Int) -> Double {
        let boxWidth = Double(width / 3)
        let offset = Double(model.cards[index].offset)
        let angle: Double = 5
        
        return (offset / boxWidth) * angle
    }
    
    private func getCardHeight(index: Int) -> CGFloat {
        let height: CGFloat = 400
        let cardHeight = index - model.swippedCard <= 2 ? CGFloat(
            index - model.swippedCard
        ) * 35 : 70
        
        return height - cardHeight
    }
    
    private func getCardWidth(index: Int) -> CGFloat {
        let boxWidth = width - 60 - 60
        
        return boxWidth
    }
    
    private func getCadOffset(index: Int) -> CGFloat {
        return index - model.swippedCard <= 2 ? CGFloat(index - model.swippedCard) * 30 : 60
    }
}

#Preview {
    @Previewable @Namespace var ns
    SponsoredCarousel(animation: ns)
        .environmentObject(SponsoredViewModel())
}
