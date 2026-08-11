# Itinerary Grounding on Supabase — Design Spec

**Date:** 2026-08-09
**App:** Places (iOS 26.5, SwiftUI, Swift 6, `-default-isolation=MainActor`)
**Depends on:** the itinerary subsystem (`PlaceRegistry`, `ResolvedPlace`, `ItineraryEngine`/`Factory`, `FindPlacesTool`, `CloudItineraryEngine`, `ItineraryChatViewModel`) and Supabase content (`destinations`, `experiences`).

## Goal
Replace the hardcoded `PlaceCatalog` (16 places) with a live grounding catalog fetched from Supabase — **all 10 destinations + all 41 experiences** (every one has coordinates) — so generated itineraries reference real DB content with real coordinates and images. Both engines consume it. **The edge function is unchanged** (it already accepts `placeNames` from the request). Also produce a **design-only** spec for the future "deep" itinerary.

## Locked decisions
1. **Grounding scope:** destinations + experiences (~51 places).
2. **Deep schema:** design-only doc this step (no `@Generable`/edge-function changes).
3. **Fetch-failure:** graceful — empty catalog, generation still proceeds (no hardcoded fallback).

## Components

### 1. `GroundingPlace` (Models/Itinerary/GroundingPlace.swift)
```
nonisolated struct GroundingPlace: Identifiable {
    let name: String
    let latitude: Double
    let longitude: Double
    let imageURL: String
    let subtitle: String
    let bucket: PlaceCategory   // for the on-device findPlaces tool
    var id: String { name }
    var resolvedPlace: ResolvedPlace  // name, CLLocationCoordinate2D, imageURL: URL?, subtitle
}
init(destination: DestinationDTO)      // imageURL = bannerUrl, subtitle = category, bucket = GroundingBucket…
init?(experience: ExperienceDTO)       // nil if lat/lng missing; imageURL = images.first ?? "", subtitle = categoryLabel
```

### 2. `GroundingBucket` (Models/Itinerary/GroundingBucket.swift)
Maps DB categories → the 5 `PlaceCategory` buckets (grounded in real values):
- **destination category:** `national_park`, `conservancy`, `mountain` → `.wildlife`; `beach` → `.beach`; `cultural` → `.culture`. (default → `.city`)
- **experience category_tag:** `wildlife_safaris`, `nature_hiking` → `.wildlife`; `cultural_heritage`, `arts_crafts` → `.culture`; `wellness_relaxation` → `.beach`; `food_coffee_tours`, `adventure_sports`, `nightlife_music` → `.city`. (default → `.city`)
```
nonisolated enum GroundingBucket {
    static func forDestination(category: String) -> PlaceCategory
    static func forExperience(tag: String) -> PlaceCategory
}
```

### 3. `GroundingCatalog` (Models/Itinerary/GroundingCatalog.swift)
Instance replacing the static `PlaceCatalog`:
```
nonisolated struct GroundingCatalog {
    let places: [GroundingPlace]
    var names: [String] { places.map(\.name) }
    func entries(in category: PlaceCategory) -> [GroundingPlace] { places.filter { $0.bucket == category } }
    var resolvedPlaces: [ResolvedPlace] { places.map(\.resolvedPlace) }
    static let empty = GroundingCatalog(places: [])
}
```

### 4. `GroundingProviding` + `SupabaseGroundingRepository` (Services/Itinerary/GroundingRepository.swift)
```
protocol GroundingProviding { func fetchGroundingPlaces() async throws -> [GroundingPlace] }
struct SupabaseGroundingRepository: GroundingProviding {
    // async let destinations/experiences via client.from(...).select().execute().value (DestinationDTO/ExperienceDTO)
    // return destinations.map(GroundingPlace.init(destination:)) + experiences.compactMap(GroundingPlace.init(experience:))
}
```

### 5. Engine rewiring
- `ItineraryEngineFactory.make(…)` gains `catalog: GroundingCatalog`.
- `FindPlacesTool.init(catalog: GroundingCatalog, registry: PlaceRegistry)` — `call(kind:)` → `catalog.entries(in: category)`, registers each in `registry`, returns the names string.
- `OnDeviceItineraryEngine` — builds `FindPlacesTool(catalog:registry:)`; refine pre-registers `catalog.resolvedPlaces` and lists `catalog.names`.
- `CloudItineraryEngine` — pre-registers `catalog.resolvedPlaces`; `placeNames = catalog.names`.
- **Delete** the hardcoded `PlaceCatalog` (entries/all/entries(in:)/resolve) and `PlaceCatalogEntry`. **Keep** `PlaceCategory` (move to its own file `Models/Itinerary/PlaceCategory.swift`).

### 6. `ItineraryChatViewModel.start(kind:)`
Before creating the engine:
```
let catalog: GroundingCatalog
do { catalog = GroundingCatalog(places: try await grounding.fetchGroundingPlaces()) }
catch { catalog = .empty; ItineraryLog.debug("grounding fetch failed: \(error)") }
catalog.resolvedPlaces.forEach(registry.register)
engine = ItineraryEngineFactory.make(kind:config:systemPrompt:registry:catalog:catalog, resumeTranscript:…)
```
Inject `grounding: GroundingProviding = SupabaseGroundingRepository()` into the VM (default arg). Cache the fetched catalog in-memory for the session (refine reuses it).

### 7. Images
`ResolvedPlace.imageURL` gets the Supabase URL. `ItineraryMessageView`'s remote path switches `AsyncImage` → `RemoteImage` (SDWebImage caching); the "Places on this trip" carousel + activity rows render from `imageURL`.

## Fetch timing / degradation
Fetch in `start()` (brief; the chat already shows a generating state). On failure → `.empty`: cloud sends no enum (free-form names, no pins), on-device tool returns nothing. Generation still runs; no hardcoded fallback.

## Testing (Swift Testing)
- `GroundingBucket`: every destination category + all 8 experience tags → expected bucket.
- `GroundingPlace`: destination mapping; experience-with-coords mapping; experience missing coords → `nil` (compactMap drops it).
- `GroundingCatalog`: `names`, `entries(in:)` filters by bucket, `resolvedPlaces` produce a valid coordinate + `imageURL` URL.
(SupabaseGroundingRepository network call is integration — verified live, not unit-tested.)

## Deep-itinerary schema — separate design doc
`docs/superpowers/specs/2026-08-09-deep-itinerary-schema-design.md` (design-only, future phase): per-activity `startTime`/`notes`/`priceEstimate`, per-day + trip cost totals, and the **cloud-first tool-calling approach** for price estimation. No code this step.

## Scope
**In:** `GroundingPlace`/`GroundingBucket`/`GroundingCatalog`/`GroundingProviding`+repo, fetch+register+inject in `start()`, engine/tool/factory rewiring, delete hardcoded `PlaceCatalog`(+Entry), `ItineraryMessageView` `RemoteImage`, tests, deep-schema design doc.
**Out:** building the deep itinerary; offline caching of grounding; edge-function changes; cross-device transcript sync.
