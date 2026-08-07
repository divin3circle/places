//
//  SupportChannel.swift
//  Places
//
//  The two built-in support conversations, shown like Airbnb Support: an AI
//  agent for app help / tutorials, and general customer support.
//

import SwiftUI

enum SupportChannel: Hashable {
    /// Feature help, tutorials, "how do I…". AI-assisted → subtle accent.
    case aiAgent
    /// General customer support.
    case customer

    var displayName: String {
        switch self {
        case .aiAgent: "Places AI"
        case .customer: "Places Support"
        }
    }

    /// SF Symbol for the AI channel; the customer channel uses the app logo asset.
    var glyph: String {
        switch self {
        case .aiAgent: "sparkles"
        case .customer: "bubble.left.and.bubble.right.fill"
        }
    }

    /// Only the AI channel carries accent (AI assistance is a "generate" action).
    var usesAccent: Bool { self == .aiAgent }

    var defaultPreview: String {
        switch self {
        case .aiAgent: "Ask me anything about Places"
        case .customer: "Welcome — how can we help?"
        }
    }
}
