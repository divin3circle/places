//
//  OnDeviceItineraryEngine.swift
//  Places
//
//  On-device generation via Apple FoundationModels. A single LanguageModelSession
//  (seeded with the config-derived system prompt + the findPlaces tool) is reused
//  across turns so context is preserved. Structured itinerary streaming for the
//  first turn; free-text streaming for follow-ups.
//

#if canImport(FoundationModels)
import Foundation
import FoundationModels

@MainActor
final class OnDeviceItineraryEngine: ItineraryEngine {
    private var session: LanguageModelSession
    private let registry: PlaceRegistry
    private let catalog: GroundingCatalog
    private let systemPrompt: String
    private var currentTask: Task<Void, Never>?

    init(systemPrompt: String, registry: PlaceRegistry, catalog: GroundingCatalog, resumeFrom transcriptData: Data? = nil) {
        ItineraryLog.debug("🧭 [Engine] init — availability: \(SystemLanguageModel.default.availability)")
        self.registry = registry
        self.catalog = catalog
        self.systemPrompt = systemPrompt
        let tool = FindPlacesTool(catalog: catalog, registry: registry)
        // Resume a prior conversation (full memory) when we have a saved transcript.
        if let transcriptData,
           let transcript = try? JSONDecoder().decode(Transcript.self, from: transcriptData) {
            ItineraryLog.debug("🧭 [Engine] resuming from saved transcript (\(transcriptData.count) bytes)")
            session = LanguageModelSession(tools: [tool], transcript: transcript)
        } else {
            session = LanguageModelSession(tools: [tool], instructions: systemPrompt)
        }
    }

    /// Encoded session transcript for persistence (restores memory on reopen).
    var transcriptData: Data? {
        try? JSONEncoder().encode(session.transcript)
    }

    func prewarm() {
        ItineraryLog.debug("🧭 [Engine] prewarm")
        session.prewarm()
    }

    /// One long-lived warmer session, kept alive so `prewarm()` isn't cancelled by
    /// immediate deallocation. The weights it loads are shared with the real session.
    private static var warmer: LanguageModelSession?

    /// Eagerly load the shared on-device model ahead of a real session (e.g. while
    /// the user fills the create wizard) so the first generation starts faster.
    /// Non-blocking — `prewarm()` loads in the background — and a no-op when the
    /// model is unavailable.
    static func prewarmModel() {
        guard case .available = SystemLanguageModel.default.availability else { return }
        if warmer == nil { warmer = LanguageModelSession() }
        warmer?.prewarm()
        ItineraryLog.debug("🧭 [Engine] prewarmModel — warming shared model")
    }

    func generateItinerary(request: String) -> AsyncThrowingStream<GeneratedItinerary, Error> {
        AsyncThrowingStream { continuation in
            // Defensive: turn an unavailable model into a clear error instead of an
            // infinite spinner (the picker gates on this, but state can change).
            let availability = SystemLanguageModel.default.availability
            guard case .available = availability else {
                ItineraryLog.debug("🧭 [Engine] NOT available at stream time: \(availability)")
                continuation.finish(throwing: EngineError.unavailable("On-device AI is unavailable: \(availability)"))
                return
            }
            let task = Task { @MainActor in
                do {
                    ItineraryLog.debug("🧭 [Engine] generateItinerary — opening stream (request \(request.count) chars)")
                    // Prime the structured decode with a concrete example and use
                    // greedy sampling + no in-prompt schema — the code-along's proven
                    // recipe for combining tool-calling with @Generable streaming.
                    let prompt = Prompt {
                        request
                        "Here is an example of the desired format, but do not copy its content:"
                        GeneratedItinerary.example
                    }
                    let stream = session.streamResponse(
                        to: prompt,
                        generating: GeneratedItinerary.self,
                        includeSchemaInPrompt: false,
                        options: GenerationOptions(sampling: .greedy)
                    )
                    var count = 0
                    for try await snapshot in stream {
                        count += 1
                        if count == 1 { ItineraryLog.debug("🧭 [Engine] ✅ first snapshot received") }
                        continuation.yield(GeneratedItinerary(partial: snapshot.content))
                    }
                    ItineraryLog.debug("🧭 [Engine] stream finished after \(count) snapshot(s)")
                    continuation.finish()
                } catch {
                    ItineraryLog.debug("🧭 [Engine] ❌ stream error: \(error)")
                    continuation.finish(throwing: error)
                }
            }
            currentTask = task
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    func refine(current: GeneratedItinerary, instruction: String) -> AsyncThrowingStream<GeneratedItinerary, Error> {
        AsyncThrowingStream { continuation in
            // Everything (availability check, session creation, streaming) runs inside
            // the async task so the send tap never blocks / freezes the UI.
            let task = Task { @MainActor in
                do {
                    let availability = SystemLanguageModel.default.availability
                    guard case .available = availability else {
                        throw EngineError.unavailable("On-device AI is unavailable: \(availability)")
                    }
                    ItineraryLog.debug("🧭 [Engine] refine — \(instruction.count) chars")

                    // Refine on a FRESH session with NO tools: a second structured
                    // generation on a tool-bearing session hangs (tool loop / stall).
                    // Pre-register the whole palette so any chosen place still maps,
                    // and hand the model the exact names to pick from in the prompt.
                    let places = catalog.resolvedPlaces
                    for place in places { registry.register(place) }
                    let placeList = places.map(\.name).joined(separator: ", ")

                    let seeded = systemPrompt
                        + "\n\nCurrent itinerary to revise:\n" + Self.describe(current)
                        + "\n\nUse ONLY these exact real place names for any activity's placeName:\n" + placeList
                    let refineSession = LanguageModelSession(instructions: seeded)

                    let prompt = Prompt {
                        "Apply this change to the itinerary: \(instruction)."
                        "Return the COMPLETE updated itinerary (every day) in the same structured format, using only the listed place names."
                        "Here is an example of the desired format, but do not copy its content:"
                        GeneratedItinerary.example
                    }
                    let stream = refineSession.streamResponse(
                        to: prompt,
                        generating: GeneratedItinerary.self,
                        includeSchemaInPrompt: false,
                        options: GenerationOptions(sampling: .greedy)
                    )
                    var count = 0
                    for try await snapshot in stream {
                        count += 1
                        if count == 1 { ItineraryLog.debug("🧭 [Engine] ✅ refine first snapshot") }
                        continuation.yield(GeneratedItinerary(partial: snapshot.content))
                    }
                    // Commit as the live session only once it finished cleanly, so a
                    // superseded refine never leaves a half-streamed session behind.
                    session = refineSession
                    continuation.finish()
                } catch {
                    ItineraryLog.debug("🧭 [Engine] ❌ refine error: \(error)")
                    continuation.finish(throwing: error)
                }
            }
            currentTask = task
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// Compact plain-text rendering of an itinerary to seed a refine session.
    private static func describe(_ it: GeneratedItinerary) -> String {
        var lines = ["Title: \(it.title)", "Summary: \(it.summary)"]
        for (i, day) in it.days.enumerated() {
            lines.append("Day \(i + 1): \(day.title) — \(day.subtitle)")
            for a in day.activities {
                lines.append("  - [\(a.kind.rawValue)] \(a.title) @ \(a.placeName): \(a.description)")
            }
        }
        return lines.joined(separator: "\n")
    }

    func stop() {
        currentTask?.cancel()
        currentTask = nil
    }
}
#endif
