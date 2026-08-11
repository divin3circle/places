//
//  ChatParticipant.swift
//  Places
//
//  A member of a chat room — a fellow traveller in a trip group. Avatars are
//  initials-on-a-colored-circle for now (only `profile` is a real face asset);
//  `imageName` is a hook for real photos later.
//

import SwiftUI

struct ChatParticipant: Identifiable, Hashable {
    let id = UUID()
    let name: String
    var imageName: String? = nil
    var avatarColor: Color

    var initial: String { String(name.prefix(1)).uppercased() }
}

extension ChatParticipant {
    /// The signed-in user, sourced from the profile mock.
    static let me = ChatParticipant(
        name: UserProfile.current.name,
        imageName: UserProfile.current.avatarImageName,
        avatarColor: .accentColor
    )

    // A small roster of mock travel-squad members with distinct avatar colors.
    static let paul = ChatParticipant(name: "Paul", avatarColor: .blue)
    static let martin = ChatParticipant(name: "Martin", avatarColor: .green)
    static let mallyne = ChatParticipant(name: "Mallyne", avatarColor: .orange)
    static let lydiah = ChatParticipant(name: "Lydiah", avatarColor: .pink)
    static let winnie = ChatParticipant(name: "Winnie", avatarColor: .purple)
    static let ginny = ChatParticipant(name: "Ginny", avatarColor: .teal)
    static let shamim = ChatParticipant(name: "Shamim", avatarColor: .indigo)
    static let otieno = ChatParticipant(name: "Otieno", avatarColor: .brown)
    static let njeri = ChatParticipant(name: "Njeri", avatarColor: .red)
}
