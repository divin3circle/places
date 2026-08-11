//
//  ItineraryEngine.swift
//  Places
//
//  The adapter that lets the itinerary chat swap backends (on-device vs cloud).
//  `generateItinerary` streams the structured itinerary snapshots; `reply`
//  streams cumulative assistant text for follow-up turns.
//

import Foundation

/// Release-stripped debug logging for the itinerary engine + tools.
enum ItineraryLog {
    nonisolated static func debug(_ message: @autoclosure () -> String) {
        #if DEBUG
        print(message())
        #endif
    }
}

@MainActor
protocol ItineraryEngine: AnyObject {
    /// Streams progressively-filled itinerary snapshots (on-device) or a single
    /// complete one (cloud). The neutral `GeneratedItinerary` type keeps this
    /// backend-agnostic — the cloud engine can't construct `PartiallyGenerated`.
    func generateItinerary(request: String) -> AsyncThrowingStream<GeneratedItinerary, Error>
    /// A follow-up edit regenerates the whole itinerary (a new version) from the
    /// current one plus the instruction.
    func refine(current: GeneratedItinerary, instruction: String) -> AsyncThrowingStream<GeneratedItinerary, Error>
    func prewarm()
    func stop()
    var transcriptData: Data? { get }
}

extension ItineraryEngine {
    func prewarm() {}
    var transcriptData: Data? { nil }
}

enum EngineError: LocalizedError {
    case notImplemented
    case unavailable(String)

    var errorDescription: String? {
        switch self {
        case .notImplemented: "Cloud generation isn't wired up yet — switch to on-device for now."
        case .unavailable(let message): message
        }
    }
}

enum ItineraryEngineFactory {
    @MainActor
    static func make(kind: AIModelKind, config: TripConfig, systemPrompt: String, registry: PlaceRegistry, catalog: GroundingCatalog, resumeTranscript: Data? = nil) -> ItineraryEngine {
        switch kind {
        case .onDevice:
            #if canImport(FoundationModels)
            return OnDeviceItineraryEngine(systemPrompt: systemPrompt, registry: registry, catalog: catalog, resumeFrom: resumeTranscript)
            #else
            return CloudItineraryEngine(config: config, registry: registry, catalog: catalog)
            #endif
        case .cloud:
            return CloudItineraryEngine(config: config, registry: registry, catalog: catalog)
        }
    }

    /// Warm the on-device model ahead of time (call when the user shows intent to
    /// generate, e.g. entering the create wizard). Non-blocking; no-op if the
    /// on-device model isn't available. Callers gate on the model preference.
    @MainActor
    static func prewarmOnDevice() {
        #if canImport(FoundationModels)
        OnDeviceItineraryEngine.prewarmModel()
        #endif
    }
}
