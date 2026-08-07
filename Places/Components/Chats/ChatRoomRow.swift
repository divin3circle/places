//
//  ChatRoomRow.swift
//  Places
//
//  A single conversation row in the Messages list: avatar cluster, title
//  (participant names or support channel), last-message preview, an optional
//  "dates · place" line, and a timestamp. Unread rooms read bolder.
//

import SwiftUI

struct ChatRoomRow: View {
    let room: ChatRoom

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ChatAvatarCluster(room: room)
                .frame(width: 66, alignment: .leading)

            VStack(alignment: .leading, spacing: 3) {
                Text(room.title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(room.previewLine)
                    .font(.system(size: 14, design: .rounded))
                    .fontWeight(room.hasUnread ? .semibold : .regular)
                    .foregroundStyle(room.hasUnread ? .primary : .secondary)
                    .lineLimit(1)

                if let context = room.contextLine {
                    Text(context)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 6) {
                Text(room.timestampLabel)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.secondary)
                if room.hasUnread {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 2)
        }
        .padding(.vertical, 12)
        .contentShape(.rect)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 0) {
            ForEach(ChatRoom.mock) { room in
                ChatRoomRow(room: room)
            }
        }
        .padding(.horizontal, 15)
    }
}
