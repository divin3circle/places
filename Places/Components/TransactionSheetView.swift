//
//  TransactionSheetView.swift
//  Places
//
//  Created by Sylus Abel on 03/08/2026.
//

import SwiftUI

struct TransactionSheetView: View {
    var card: Card
    var body: some View {
        Text("Hello, \(card.cardTitle)")
    }
}

#Preview {
    TransactionSheetView(card: Card.dummyCards[0])
}
