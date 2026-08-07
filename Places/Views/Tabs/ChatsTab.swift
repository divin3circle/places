//
//  ChatsTab.swift
//  Places
//
//  Created by Sylus Abel on 07/08/2026.
//

import SwiftUI

/// The Messages list (the "Lounges" tab): an All / Travelling / Support filter
/// row and a list of chat rooms (trip groups + support). Lives inside AppTab's
/// ScrollView + disappearing header; rows are built lazily.
struct ChatsTab: View {
    @StateObject private var vm = ChatsViewModel()

    var body: some View {
        LazyVStack(spacing: 0) {
            filterBar

            ForEach(vm.visibleRooms) { room in
                Button {
                    // TODO: push ChatThreadView(room:) once the thread screen exists.
                } label: {
                    ChatRoomRow(room: room)
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
        .animation(.snappy, value: vm.filter)
    }

    private var filterBar: some View {
        HStack(spacing: 8) {
            ForEach(ChatFilter.allCases) { filter in
                FilterPill(label: filter.rawValue, isSelected: vm.filter == filter) {
                    vm.filter = filter
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 8)
        .padding(.top, 16)
    }
}

#Preview {
    ScrollView { ChatsTab() }
        .safeAreaPadding(.horizontal, 15)
}
