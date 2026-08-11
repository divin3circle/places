//
//  Card.swift
//  Places
//
//  Created by Sylus Abel on 03/08/2026.
//

import Foundation

struct Card: Identifiable {
    var id: String = UUID().uuidString
    var cardBackground: String
    var cardTitle: String
    var cardCategory: String
    var cardType: String
}

struct ImageModel: Identifiable {
    var id: String = UUID().uuidString
    var altText: String
    var image: String
}

extension Card {
    static let dummyCards: [Card] = [
        .init(cardBackground: "card-1", cardTitle: "Sylus A.", cardCategory: "DEBIT", cardType: "Mastercard"),
        .init(cardBackground: "card-2", cardTitle: "Amos B.", cardCategory: "DEBIT", cardType: "Mastercard"),
        .init(cardBackground: "card-3", cardTitle: "Grace V.", cardCategory: "CREDIT", cardType: "Visa"),
        .init(cardBackground: "card-4", cardTitle: "Mercy M.", cardCategory: "DEBIT", cardType: "Visa")
        ]
}
