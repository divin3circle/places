//
//  AIAvailability.swift
//  Places
//
//  Whether on-device generation is usable on this device, with a human-readable
//  reason when it isn't (so the model picker can disable + explain it). Wraps
//  SystemLanguageModel availability; degrades to "unavailable" where the
//  framework isn't present.
//

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

enum AIAvailability {
    struct Status {
        let isAvailable: Bool
        let reason: String?
    }

    static var onDevice: Status {
        #if canImport(FoundationModels)
        switch SystemLanguageModel.default.availability {
        case .available:
            return Status(isAvailable: true, reason: nil)
        case .unavailable(let reason):
            return Status(isAvailable: false, reason: message(for: reason))
        @unknown default:
            return Status(isAvailable: false, reason: "On-device AI is unavailable right now.")
        }
        #else
        return Status(isAvailable: false, reason: "This device doesn't support on-device AI.")
        #endif
    }

    #if canImport(FoundationModels)
    private static func message(for reason: SystemLanguageModel.Availability.UnavailableReason) -> String {
        switch reason {
        case .deviceNotEligible:
            return "This iPhone doesn't support Apple Intelligence."
        case .appleIntelligenceNotEnabled:
            return "Turn on Apple Intelligence in Settings to use on-device generation."
        case .modelNotReady:
            return "The on-device model is still downloading. Try again shortly."
        @unknown default:
            return "On-device AI is unavailable right now."
        }
    }
    #endif
}
