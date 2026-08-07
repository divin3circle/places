//
//  ChatRoom.swift
//  Places
//
//  A conversation shown in the Messages tab. A trip group has a Trip + the
//  travel squad (participants); support rooms are the two built-in channels.
//  Mock data for now — no backend.
//

import Foundation

enum ChatRoomKind: Hashable {
    case tripGroup
    case support(SupportChannel)
}

enum ChatFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case travelling = "Travelling"
    case support = "Support"

    var id: String { rawValue }
}

struct ChatRoom: Identifiable {
    let id = UUID()
    var kind: ChatRoomKind
    var trip: Trip?
    var participants: [ChatParticipant] = []
    var lastSender: String? = nil
    var lastMessagePreview: String
    /// "26–27 Jun · Ruiru" for trips; nil for support.
    var contextLine: String? = nil
    var lastActivity: Date
    var hasUnread: Bool = false

    var title: String {
        switch kind {
        case .tripGroup:
            participants.map(\.name).joined(separator: ", ")
        case .support(let channel):
            channel.displayName
        }
    }

    var previewLine: String {
        if let lastSender { return "\(lastSender): \(lastMessagePreview)" }
        return lastMessagePreview
    }

    var timestampLabel: String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = calendar.isDate(lastActivity, equalTo: Date(), toGranularity: .year)
            ? "dd/MM"
            : "dd/MM/yy"
        return formatter.string(from: lastActivity)
    }

    func matches(_ filter: ChatFilter) -> Bool {
        switch filter {
        case .all:
            return true
        case .travelling:
            if case .tripGroup = kind { return true }
            return false
        case .support:
            if case .support = kind { return true }
            return false
        }
    }
}

extension ChatRoom {
    private static func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: y, month: m, day: d)) ?? Date(timeIntervalSince1970: 0)
    }

    static let mock: [ChatRoom] = {
        let trips = Trip.dummyTrips
        return [
            ChatRoom(
                kind: .tripGroup, trip: trips[0],
                participants: [.paul, .martin, .mallyne],
                lastSender: "Paul",
                lastMessagePreview: "2pm is okay so I can get time to prep the gear",
                contextLine: "26–27 Jun · Ruiru",
                lastActivity: date(2026, 6, 26), hasUnread: true
            ),
            ChatRoom(
                kind: .tripGroup, trip: trips[1],
                participants: [.lydiah],
                lastMessagePreview: "New message",
                contextLine: "26–27 Apr · Kisumu",
                lastActivity: date(2026, 4, 26), hasUnread: true
            ),
            ChatRoom(
                kind: .support(.aiAgent), trip: nil,
                lastMessagePreview: SupportChannel.aiAgent.defaultPreview,
                lastActivity: date(2026, 4, 2), hasUnread: true
            ),
            ChatRoom(
                kind: .tripGroup, trip: trips[2],
                participants: [.winnie, .mallyne],
                lastMessagePreview: "Reminder – leave a review",
                contextLine: "31 Dec 2025 – 1 Jan 2026 · Nairobi",
                lastActivity: date(2026, 1, 1)
            ),
            ChatRoom(
                kind: .support(.customer), trip: nil,
                lastMessagePreview: SupportChannel.customer.defaultPreview,
                lastActivity: date(2025, 12, 31)
            ),
            ChatRoom(
                kind: .tripGroup, trip: trips[3],
                participants: [.ginny, .mallyne],
                lastSender: "Ginny",
                lastMessagePreview: "Reminder – leave a review",
                contextLine: "1–3 Nov 2025 · Ruaka",
                lastActivity: date(2025, 11, 3)
            ),
            ChatRoom(
                kind: .tripGroup, trip: trips[4],
                participants: [.shamim, .mallyne],
                lastMessagePreview: "Reminder – leave a review",
                contextLine: "1–3 Nov 2025 · Nairobi",
                lastActivity: date(2025, 11, 2)
            ),
            ChatRoom(
                kind: .tripGroup, trip: trips[5],
                participants: [.otieno, .njeri, .paul],
                lastSender: "Njeri",
                lastMessagePreview: "Booked the matatu for the whole crew 🚐",
                contextLine: "12–15 Oct 2025 · Naivasha",
                lastActivity: date(2025, 10, 15)
            ),
        ]
    }()
}
