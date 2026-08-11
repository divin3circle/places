//
//  FreeLimits.swift
//  Places
//
//  Free-tier limits in one place (Pro is unlimited). Tune the gates here.
//

import Foundation

nonisolated enum FreeLimits {
    /// Max active saved trips for a free user before the paywall.
    static let savedTrips = 3

    /// Token cost for a free user to plan a multi-country trip (Pro is free).
    static let borderPassTokens = 15
}
