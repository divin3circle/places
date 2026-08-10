# Itinerary Grounding on Supabase Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the hardcoded `PlaceCatalog` with a live `GroundingCatalog` (all destinations + coord-bearing experiences from Supabase) that both itinerary engines consume.

**Architecture:** A `GroundingProviding` seam fetches destinations+experiences → `GroundingPlace`s → a `GroundingCatalog` (names + per-bucket entries + resolved places). `ItineraryChatViewModel.start` fetches it, registers it in `PlaceRegistry`, and injects it into the engines via the factory. The edge function is unchanged.

**Tech Stack:** supabase-swift (PostgREST), FoundationModels, CoreLocation, Swift Testing.

## Global Constraints
- iOS 26.5, Swift 6, `-default-isolation=MainActor`; data types `nonisolated`.
- Ground on **all 10 destinations + all 41 experiences** (every one has coords). Fetch-failure → `.empty` catalog, generation still proceeds (no hardcoded fallback).
- **Edge function unchanged.** Verify: `xcodebuild test/build … -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`; interactive on iPhone 17 Pro.

## File Structure
**Create:** `Places/Models/Itinerary/GroundingBucket.swift`, `GroundingPlace.swift`, `GroundingCatalog.swift`, `Places/Services/Itinerary/GroundingRepository.swift`, `Places/Models/Itinerary/PlaceCategory.swift`; tests `PlacesTests/GroundingBucketTests.swift`, `GroundingPlaceTests.swift`, `GroundingCatalogTests.swift`; doc `docs/superpowers/specs/2026-08-09-deep-itinerary-schema-design.md`.
**Modify:** `Places/Services/Itinerary/Tools/FindPlacesTool.swift`, `Places/Services/Itinerary/ItineraryEngine.swift` (factory), `OnDeviceItineraryEngine.swift`, `CloudItineraryEngine.swift`, `Places/View Models/CreateViewModels/ItineraryChatViewModel.swift`, `Places/Views/Create/ItineraryMessageView.swift`, `Places/Models/Itinerary/PlaceCatalog.swift` (delete hardcoded; move out `PlaceCategory`).

---

### Task 1: `GroundingBucket` (TDD)

**Files:** Create `Places/Models/Itinerary/GroundingBucket.swift`; Test `PlacesTests/GroundingBucketTests.swift`.

**Interfaces:**
- Consumes: `PlaceCategory` (existing).
- Produces: `nonisolated enum GroundingBucket { static func forDestination(category:) -> PlaceCategory; static func forExperience(tag:) -> PlaceCategory }`.

- [ ] **Step 1: Write the failing tests.**
```swift
import Testing
@testable import Places

struct GroundingBucketTests {
    @Test func destinationCategories() {
        #expect(GroundingBucket.forDestination(category: "national_park") == .wildlife)
        #expect(GroundingBucket.forDestination(category: "conservancy") == .wildlife)
        #expect(GroundingBucket.forDestination(category: "mountain") == .wildlife)
        #expect(GroundingBucket.forDestination(category: "beach") == .beach)
        #expect(GroundingBucket.forDestination(category: "cultural") == .culture)
        #expect(GroundingBucket.forDestination(category: "unknown") == .city)
    }
    @Test func experienceTags() {
        #expect(GroundingBucket.forExperience(tag: "wildlife_safaris") == .wildlife)
        #expect(GroundingBucket.forExperience(tag: "nature_hiking") == .wildlife)
        #expect(GroundingBucket.forExperience(tag: "cultural_heritage") == .culture)
        #expect(GroundingBucket.forExperience(tag: "arts_crafts") == .culture)
        #expect(GroundingBucket.forExperience(tag: "wellness_relaxation") == .beach)
        #expect(GroundingBucket.forExperience(tag: "food_coffee_tours") == .city)
        #expect(GroundingBucket.forExperience(tag: "nightlife_music") == .city)
    }
}
```
- [ ] **Step 2: Run — expect fail.**
- [ ] **Step 3: Implement.**
```swift
import Foundation

nonisolated enum GroundingBucket {
    static func forDestination(category: String) -> PlaceCategory {
        switch category {
        case "national_park", "conservancy", "mountain": .wildlife
        case "beach": .beach
        case "cultural": .culture
        default: .city
        }
    }
    static func forExperience(tag: String) -> PlaceCategory {
        switch tag {
        case "wildlife_safaris", "nature_hiking": .wildlife
        case "cultural_heritage", "arts_crafts": .culture
        case "wellness_relaxation": .beach
        default: .city   // food_coffee_tours, adventure_sports, nightlife_music
        }
    }
}
```
- [ ] **Step 4: Run — expect pass.**
- [ ] **Step 5: Commit.** `git commit -am "feat: GroundingBucket (DB category → PlaceCategory)"`

---

### Task 2: `GroundingPlace` (TDD)

**Files:** Create `Places/Models/Itinerary/GroundingPlace.swift`; Test `PlacesTests/GroundingPlaceTests.swift`.

**Interfaces:**
- Consumes: `DestinationDTO`, `ExperienceDTO`, `PlaceCategory`, `ResolvedPlace`, `GroundingBucket`.
- Produces: `nonisolated struct GroundingPlace: Identifiable` with `name/latitude/longitude/imageURL/subtitle/bucket/id/resolvedPlace`; `init(destination:)`; `init?(experience:)`.

> **Before implementing, READ `Places/Models/Itinerary/PlaceRegistry.swift`** to confirm the exact `ResolvedPlace` initializer labels (expected `ResolvedPlace(name:coordinate:imageName:imageURL:subtitle:)` with defaults). Adjust the `resolvedPlace` code to match.

- [ ] **Step 1: Write the failing tests.**
```swift
import Testing
import Foundation
@testable import Places

struct GroundingPlaceTests {
    private func dest() -> DestinationDTO {
        DestinationDTO(id: "ke_mara", name: "Maasai Mara", category: "national_park", countryCode: "KE",
            latitude: -1.5, longitude: 35.1, description: "", bannerUrl: "https://b.jpg", images: [],
            nonResidentFeeUsd: nil, feeLabel: nil, vehicleFeeGuidelines: nil, paymentInfrastructure: nil,
            interestTags: [], bestSeason: nil, closestHub: nil, rating: 4.9, bestTimeToVisit: nil,
            priceRange: nil, isPopular: true)
    }
    private func exp(lat: Double?, lng: Double?) -> ExperienceDTO {
        ExperienceDTO(id: UUID(), title: "Game Drive", images: ["https://e.jpg"], categoryTag: "wildlife_safaris",
            categoryLabel: "Wildlife safaris", cityId: "nairobi", pricePerGuest: 1, currency: "KSh",
            rating: 4, reviewsCount: 0, isTrending: false, hostName: "", hostTagline: "", hostImageUrl: nil,
            locationName: "", locationArea: "", durationLabel: "", language: "", description: "",
            latitude: lat, longitude: lng)
    }

    @Test func mapsDestination() {
        let p = GroundingPlace(destination: dest())
        #expect(p.name == "Maasai Mara")
        #expect(p.bucket == .wildlife)
        #expect(p.imageURL == "https://b.jpg")
        #expect(p.resolvedPlace.coordinate.latitude == -1.5)
        #expect(p.resolvedPlace.imageURL?.absoluteString == "https://b.jpg")
    }
    @Test func mapsExperienceWithCoords() {
        let p = GroundingPlace(experience: exp(lat: -1.3, lng: 36.8))
        #expect(p != nil)
        #expect(p?.bucket == .wildlife)
        #expect(p?.imageURL == "https://e.jpg")
    }
    @Test func dropsExperienceWithoutCoords() {
        #expect(GroundingPlace(experience: exp(lat: nil, lng: nil)) == nil)
    }
}
```
- [ ] **Step 2: Run — expect fail.**
- [ ] **Step 3: Implement.**
```swift
import Foundation
import CoreLocation

nonisolated struct GroundingPlace: Identifiable {
    let name: String
    let latitude: Double
    let longitude: Double
    let imageURL: String
    let subtitle: String
    let bucket: PlaceCategory

    var id: String { name }

    var resolvedPlace: ResolvedPlace {
        ResolvedPlace(
            name: name,
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            imageURL: URL(string: imageURL),
            subtitle: subtitle
        )
    }
}

extension GroundingPlace {
    init(destination d: DestinationDTO) {
        self.init(name: d.name, latitude: d.latitude, longitude: d.longitude,
                  imageURL: d.bannerUrl, subtitle: d.category,
                  bucket: GroundingBucket.forDestination(category: d.category))
    }
    init?(experience e: ExperienceDTO) {
        guard let lat = e.latitude, let lng = e.longitude else { return nil }
        self.init(name: e.title, latitude: lat, longitude: lng,
                  imageURL: e.images.first ?? "", subtitle: e.categoryLabel,
                  bucket: GroundingBucket.forExperience(tag: e.categoryTag))
    }
}
```
(If `ResolvedPlace` has no memberwise init with those labels, adapt to its actual init.)
- [ ] **Step 4: Run — expect pass.**
- [ ] **Step 5: Commit.** `git commit -am "feat: GroundingPlace + DTO mappers"`

---

### Task 3: `GroundingCatalog` (TDD)

**Files:** Create `Places/Models/Itinerary/GroundingCatalog.swift`; Test `PlacesTests/GroundingCatalogTests.swift`.

**Interfaces:**
- Produces: `nonisolated struct GroundingCatalog { let places; var names; func entries(in:); var resolvedPlaces; static let empty }`.

- [ ] **Step 1: Write the failing tests.**
```swift
import Testing
import Foundation
@testable import Places

struct GroundingCatalogTests {
    private func place(_ name: String, _ bucket: PlaceCategory) -> GroundingPlace {
        GroundingPlace(name: name, latitude: 0, longitude: 0, imageURL: "https://x.jpg", subtitle: "s", bucket: bucket)
    }
    @Test func namesAndBucketFilter() {
        let c = GroundingCatalog(places: [place("A", .wildlife), place("B", .city), place("C", .wildlife)])
        #expect(c.names == ["A", "B", "C"])
        #expect(c.entries(in: .wildlife).map(\.name) == ["A", "C"])
        #expect(c.resolvedPlaces.count == 3)
        #expect(c.entries(in: .lake).isEmpty)
    }
    @Test func emptyCatalog() {
        #expect(GroundingCatalog.empty.names.isEmpty)
    }
}
```
- [ ] **Step 2: Run — expect fail.**
- [ ] **Step 3: Implement.**
```swift
import Foundation

nonisolated struct GroundingCatalog {
    let places: [GroundingPlace]
    var names: [String] { places.map(\.name) }
    func entries(in category: PlaceCategory) -> [GroundingPlace] { places.filter { $0.bucket == category } }
    var resolvedPlaces: [ResolvedPlace] { places.map(\.resolvedPlace) }
    static let empty = GroundingCatalog(places: [])
}
```
- [ ] **Step 4: Run — expect pass.**
- [ ] **Step 5: Commit.** `git commit -am "feat: GroundingCatalog"`

---

### Task 4: `GroundingProviding` + repository

**Files:** Create `Places/Services/Itinerary/GroundingRepository.swift`. Build-verify.

**Interfaces:**
- Produces: `protocol GroundingProviding { func fetchGroundingPlaces() async throws -> [GroundingPlace] }`; `struct SupabaseGroundingRepository: GroundingProviding`.

- [ ] **Step 1: Implement.**
```swift
import Foundation
import Supabase

protocol GroundingProviding {
    func fetchGroundingPlaces() async throws -> [GroundingPlace]
}

struct SupabaseGroundingRepository: GroundingProviding {
    func fetchGroundingPlaces() async throws -> [GroundingPlace] {
        async let dests: [DestinationDTO] = SupabaseService.client.from("destinations").select().execute().value
        async let exps: [ExperienceDTO] = SupabaseService.client.from("experiences").select().execute().value
        let (d, e) = try await (dests, exps)
        return d.map(GroundingPlace.init(destination:)) + e.compactMap(GroundingPlace.init(experience:))
    }
}
```
- [ ] **Step 2: Verify build.** `xcodebuild build …` → BUILD SUCCEEDED. (If passing the failable `init(experience:)` to `compactMap` as a function reference doesn't infer, use `e.compactMap { GroundingPlace(experience: $0) }`.)
- [ ] **Step 3: Commit.** `git commit -am "feat: SupabaseGroundingRepository"`

---

### Task 5: Rewire engines + tool + factory to the catalog

**Files:** Modify `FindPlacesTool.swift`, `ItineraryEngine.swift`, `OnDeviceItineraryEngine.swift`, `CloudItineraryEngine.swift`. Build-verify.

> **READ all four files first** — the edits below are targeted but must match the real code.

- [ ] **Step 1: `FindPlacesTool`** — add `let catalog: GroundingCatalog` stored + `init(catalog:registry:)`. In `call(arguments:)`, replace `PlaceCatalog.entries(in: arguments.category)` with `catalog.entries(in: arguments.category)` (a `[GroundingPlace]`); register each `place.resolvedPlace` in the registry; build the return string from `place.name` + `place.subtitle`.
- [ ] **Step 2: `ItineraryEngineFactory.make`** — add parameter `catalog: GroundingCatalog`; pass it to both engine initializers.
- [ ] **Step 3: `OnDeviceItineraryEngine`** — accept `catalog: GroundingCatalog` in init; build `FindPlacesTool(catalog: catalog, registry: registry)`. In `refine`, replace `PlaceCatalog.all`/`PlaceCatalog.all.map(\.name)` with `catalog.resolvedPlaces` (register) and `catalog.names` (the prompt list).
- [ ] **Step 4: `CloudItineraryEngine`** — accept `catalog: GroundingCatalog` in init; replace `registry` pre-registration with `catalog.resolvedPlaces.forEach(registry.register)` and `placeNames: catalog.names`.
- [ ] **Step 5: Verify build.** (Will fail until `PlaceCatalog` deletion in Task 7 if any residual refs remain — resolve those refs here to the catalog.)
- [ ] **Step 6: Commit.** `git commit -am "feat: itinerary engines consume GroundingCatalog"`

---

### Task 6: Fetch + inject in `ItineraryChatViewModel.start`

**Files:** Modify `Places/View Models/CreateViewModels/ItineraryChatViewModel.swift`. Build-verify.

> **READ the file first** (esp. `start(kind:)`, the `registry` property, and how the engine is made).

- [ ] **Step 1:** Add `private let grounding: GroundingProviding` with a default in init: `grounding: GroundingProviding = SupabaseGroundingRepository()`. Add `private var catalog: GroundingCatalog = .empty` (session cache).
- [ ] **Step 2:** In `start(kind:)`, before making the engine:
```swift
do { catalog = GroundingCatalog(places: try await grounding.fetchGroundingPlaces()) }
catch { catalog = .empty; ItineraryLog.debug("grounding fetch failed: \(error)") }
catalog.resolvedPlaces.forEach(registry.register)
```
Then pass `catalog: catalog` to `ItineraryEngineFactory.make(…)`.
- [ ] **Step 3: Verify build.**
- [ ] **Step 4: Commit.** `git commit -am "feat: fetch live grounding before generation"`

---

### Task 7: Delete hardcoded `PlaceCatalog`; extract `PlaceCategory`; remote itinerary images

**Files:** Modify `Places/Models/Itinerary/PlaceCatalog.swift`, Create `Places/Models/Itinerary/PlaceCategory.swift`, Modify `Places/Views/Create/ItineraryMessageView.swift`. Build + interactive verify.

- [ ] **Step 1:** Move the `PlaceCategory` enum into its own `PlaceCategory.swift` (unchanged content). Delete `PlaceCatalogEntry` and the whole `PlaceCatalog` enum (entries/all/entries(in:)/resolve). Grep to confirm no remaining refs: `grep -rn "PlaceCatalog\b\|PlaceCatalogEntry" Places` → only comments, if any.
- [ ] **Step 2:** In `ItineraryMessageView`, replace the remote-image branch (`AsyncImage(url: place.imageURL)`) with `RemoteImage(place.imageURL?.absoluteString ?? "", width: …, height: …)` for the activity row + the "Places on this trip" carousel. (Read the file for the exact frames.)
- [ ] **Step 3: Verify build.** `xcodebuild build …` → BUILD SUCCEEDED.
- [ ] **Step 4: Interactive verify** on iPhone 17 Pro (signed in): create a trip → generate → the map pins + place cards + activity images reflect **real DB destinations/experiences**; a refine still resolves names; airplane-mode generate still produces an itinerary (no pins) without crashing.
- [ ] **Step 5: Commit.** `git commit -am "feat: remove hardcoded PlaceCatalog; itinerary uses live grounding"`

---

### Task 8: Deep-itinerary schema — design doc

**Files:** Create `docs/superpowers/specs/2026-08-09-deep-itinerary-schema-design.md`. (Doc only.)

- [ ] **Step 1: Write the design doc** covering: proposed `@Generable` additions — `ItineraryActivity.startTime: String` ("HH:mm"), `.notes: String`, `.priceEstimate: Int` (KSh, per guest) + `.priceIsEstimate: Bool`; `ItineraryDay.estimatedCost: Int`; `GeneratedItinerary.estimatedTotal: Int`. The **cloud-first tool-calling approach** for price estimation (a `priceLookup` tool grounded in `experiences.price_per_guest` + `destinations.non_resident_fee_usd`, general-knowledge fallback), the target of **3–4 activities/day**, per-day + trip totals, and why on-device does a simpler subset. Edge-function `itinerarySchema` additions. Mark it **future phase, not implemented**.
- [ ] **Step 2: Commit.** `git commit -am "docs: deep-itinerary schema design (future phase)"`

---

## Deferred (out of scope)
Building the deep itinerary; offline caching of grounding; edge-function changes; transcript cross-device sync.
