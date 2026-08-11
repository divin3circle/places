//
//  WalletTab.swift
//  Places
//
//  Created by Sylus Abel on 02/08/2026.
//

import SwiftUI

struct WalletTab: View {
    @State private var selectedCard: Card? = nil
    @State private var info: Info = .init()
  
    var body: some View {
        GeometryReader { geo in
                ScrollView(.vertical) {
                    VStack(spacing: -150) {
                        ForEach(Card.dummyCards) { card in
                            CardView(card)
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .safeAreaPadding(15)
                .scrollDisabled(isCardSelected)
                .navigationTitle(isNavigationTitleHidden ? "" : "Wallet")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        if isCardSelected {
                            Button("Close", systemImage: "xmark") {
                                withAnimation(animation) {
                                    selectedCard = nil
                                }
                            }
                            .zIndex(isCardSelected ? 1 : 0)
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(isCardSelected ? "Edit Card" : "Create Card", systemImage: isCardSelected ? "creditcard.and.numbers" : "plus") {
                            
                        }
                    }
                    
                    if !isCardSelected {
                        ToolbarSpacer(.fixed, placement: .topBarTrailing)
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        if !isCardSelected {
                            Button("Search", systemImage: "magnifyingglass") {
                                
                            }
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Options", systemImage: "ellipsis") {
                            
                        }
                    }
                }
                .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y + $0.contentInsets.top } action: { oldValue, newValue in
                    info.scrollOffset = newValue
                }
                .onGeometryChange(for: CGFloat.self, of: { $0.frame(in: .global).minY }, action: { newValue in
                    info.minY = newValue - info.safeArea.top
                })
                .onGeometryChange(for: CGSize.self, of: { $0.size }, action: { newValue in
                    info.containerSize = newValue
                })
                .sheet(item: $selectedCard) { card in
                    let spacing: CGFloat = 30
                    let minSheetHeight: CGFloat = info.containerSize.height - info.minY - (290 + spacing)
                    let maxSheetHeight: CGFloat = info.containerSize.height - info.minY - 40
                    
                    TransactionSheetView(card: card)
                        .presentationDetents([.height(minSheetHeight), .height(maxSheetHeight)])
                        .presentationBackgroundInteraction(.enabled(upThrough: .height(maxSheetHeight)))
                        .interactiveDismissDisabled()
                        .presentationBackground(.thinMaterial)
                }
                
                .onGeometryChange(for: EdgeInsets.self) { $0.safeAreaInsets  } action: { newValue in
                    info.safeArea = newValue
                }
            }
    }

    @ViewBuilder
    func CardView(_ card: Card) -> some View {
        let isCurrent = card.id == selectedCardId
        let currentIndex = Card.dummyCards.firstIndex(where: { $0.id == card.id}) ?? 0
        let selectedCardIndex = Card.dummyCards.firstIndex(where: { $0.id == selectedCardId}) ?? 0
        
        Rectangle()
            .foregroundStyle(.clear)
            .overlay {
                Image(card.cardBackground)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
            .overlay {
                VStack {
                    HStack {
                        Text(card.cardCategory)
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .fontWidth(.expanded)
                            .foregroundColor(.white)

                        Spacer()
                    }
                    Spacer(minLength: 0)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(card.cardTitle)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("**** **** **** 1234")
                            .monospaced()
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                   
                }
                .padding(20)
                .contentShape(.rect)
            }
            .clipShape(.rect(cornerRadius: 20))
            .frame(height: isCurrent ? 250 : 225)
            .zIndex(isCurrent ? 1 : 0)
            .onTapGesture {
                withAnimation(animation) {
                    selectedCard = card
                }
            }
            .visualEffect { [info, isCardSelected] content, proxy in
                let rect = proxy.frame(in: .scrollView)
                let bounds = info.containerSize
                
                let pushOffset = selectedCardIndex < currentIndex ? (bounds.height + 45 - rect.minY) : -rect.minY
                let scale = selectedCardIndex < currentIndex ? 1 : 0.95
                return content
                    .scaleEffect(isCardSelected ? (isCurrent ? 1 : scale) : 1, anchor: .top)
                    .offset(y: isCardSelected ? pushOffset : 0)
            }
            .allowsHitTesting(isCardSelected ? isCurrent : true)
    }
    
    var isNavigationTitleHidden: Bool {
        return info.scrollOffset > 1 || isCardSelected
    }
    
    var selectedCardId: String? {
        return selectedCard?.id
    }
    
    var isCardSelected: Bool {
        return selectedCardId != nil
    }
    
    struct Info {
        var scrollOffset: CGFloat = 0
        var containerSize: CGSize = .zero
        var safeArea: EdgeInsets = .init()
        var minY: CGFloat = 0
    }
    
    var animation: Animation = .interactiveSpring(response: 0.55, dampingFraction: 0.8)
}

#Preview {
    WalletTab()
}