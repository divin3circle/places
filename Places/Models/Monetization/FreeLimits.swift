//
//  FreeLimits.swift
//  Places
//
//  Free-tier limits in one place (Pro is unlimited). Tune the gates here.
//

import Foundation

nonisolated enum FreeLimits {
    /// Max active saved trips for a free user before the paywall (3rd is Pro).
    static let savedTrips = 2

    /// Token cost for a free user to plan a multi-country trip (Pro is free).
    static let borderPassTokens = 15

    /// Max trip length (days) for a free user; longer trips are Pro.
    static let tripDays = 5

    /// Max bookmarks for a free user before the paywall (6th is Pro).
    static let bookmarks = 5
}
