//
//  EACity.swift
//  Places
//
//  The East-African city an Experiences feed is scoped to. Defaults to Nairobi.
//  No device geolocation yet — the city is a stored default the section titles
//  and filtering key off of.
//

import Foundation

enum EACity: String, CaseIterable, Identifiable {
    case nairobi
    case kampala
    case arusha
    case darEsSalaam

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .nairobi: "Nairobi"
        case .kampala: "Kampala"
        case .arusha: "Arusha"
        case .darEsSalaam: "Dar es Salaam"
        }
    }
}
