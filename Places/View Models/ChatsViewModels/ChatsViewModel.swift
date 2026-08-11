//
//  ChatsViewModel.swift
//  Places
//
//  Backs the Messages tab: owns the (mock) chat rooms and the active filter,
//  and exposes the filtered + sorted list the list view renders. Follows the
//  app's ObservableObject convention (see SponsoredViewModel).
//

import Foundation
import Combine

final class ChatsViewModel: ObservableObject {
    @Published var rooms: [ChatRoom] = ChatRoom.mock
    @Published var filter: ChatFilter = .all

    /// Rooms matching the active filter, newest activity first.
    var visibleRooms: [ChatRoom] {
        rooms
            .filter { $0.matches(filter) }
            .sorted { $0.lastActivity > $1.lastActivity }
    }
}
