//
//  CloudItineraryEngine.swift
//  Places
//
//  Cloud backend: generates itineraries by calling a Supabase Edge Function that
//  proxies OpenAI (the OpenAI key lives ONLY in the function's secret, never here).
//  Non-streaming — it awaits one complete `GeneratedItinerary` and yields it once.
//  Map pins + images come from the same PlaceRegistry as on-device: we pre-register
//  the whole catalog and let the function ground the model's placeNames to it.
//

import Foundation

@MainActor
final class CloudItineraryEngine: ItineraryEngine {
    private let config: TripConfig
    private let registry: PlaceRegistry
    private let catalog: GroundingCatalog
    private var task: Task<Void, Never>?

    init(config: TripConfig, registry: PlaceRegistry, catalog: GroundingCatalog) {
        self.config = config
        self.registry = registry
        self.catalog = catalog
    }

    func generateItinerary(request: String) -> AsyncThrowingStream<GeneratedItinerary, Error> {
        run(mode: .generate, instruction: nil, current: nil)
    }

    func refine(current: GeneratedItinerary, instruction: String) -> AsyncThrowingStream<GeneratedItinerary, Error> {
        run(mode: .refine, instruction: instruction, current: current)
    }

    func stop() {
        task?.cancel()
        task = nil
    }

    private func run(
        mode: CloudItineraryRequest.Mode,
        instruction: String?,
        current: GeneratedItinerary?
    ) -> AsyncThrowingStream<GeneratedItinerary, Error> {
        AsyncThrowingStream { continuation in
            let task = Task { @MainActor in
                do {
                    // Same registry mechanism as on-device: pre-register the palette
                    // so any grounded placeName resolves to a pin + image.
                    for place in catalog.resolvedPlaces { registry.register(place) }

                    let payload = CloudItineraryRequest(
                        mode: mode,
                        config: .init(config),
                        placeNames: catalog.names,
                        instruction: instruction,
                        current: current
                    )
                    ItineraryLog.debug("☁️ [Cloud] \(mode.rawValue) request")
                    let itinerary = try await ItineraryCloudClient.generate(payload)
                    ItineraryLog.debug("☁️ [Cloud] ✅ received itinerary")
                    continuation.yield(itinerary)
                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish()
                } catch {
                    ItineraryLog.debug("☁️ [Cloud] ❌ \(error)")
                    continuation.finish(throwing: error)
                }
            }
            self.task = task
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
