//
//  ChatAvatarCluster.swift
//  Places
//
//  The leading visual of a message row. Trip groups show the trip cover with
//  the travel squad's initials overlapping (Airbnb-style); support rooms show
//  a channel avatar (AI = accent sparkles, customer = app logo).
//

import SwiftUI

struct ChatAvatarCluster: View {
    let room: ChatRoom
    var side: CGFloat = 56

    var body: some View {
        switch room.kind {
        case .tripGroup:
            tripGroup
        case .support(let channel):
            support(channel)
        }
    }

    // MARK: Trip group

    private var tripGroup: some View {
        ZStack(alignment: .bottomTrailing) {
            DownsampledAssetImage(name: room.trip?.coverImageName ?? "sample",
                                  width: side, height: side)
                .frame(width: side, height: side)
                .clipShape(.rect(cornerRadius: 14, style: .continuous))

            // Secondary participant — small, top-trailing.
            if room.participants.count > 1, let second = room.participants.dropFirst().first {
                InitialsAvatar(initial: second.initial, color: second.avatarColor, size: 24)
                    .frame(width: side, height: side, alignment: .topTrailing)
                    .offset(x: 8, y: -6)
            }

            // Primary participant — larger, bottom-trailing.
            if let first = room.participants.first {
                InitialsAvatar(initial: first.initial, color: first.avatarColor, size: 32)
                    .offset(x: 8, y: 8)
            }
        }
        .frame(width: side, height: side)
    }

    // MARK: Support

    @ViewBuilder
    private func support(_ channel: SupportChannel) -> some View {
        if channel.usesAccent {
            Image(systemName: channel.glyph)
                .font(.system(size: side * 0.42, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: side, height: side)
                .background(Color.accentColor.opacity(0.15), in: .circle)
        } else {
            Image("places-icon")
                .resizable()
                .scaledToFill()
                .frame(width: side, height: side)
                .clipShape(.circle)
                .background(Color.primary, in: .circle)
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        ForEach(ChatRoom.mock.prefix(4)) { room in
            ChatAvatarCluster(room: room)
        }
    }
    .padding(40)
}
