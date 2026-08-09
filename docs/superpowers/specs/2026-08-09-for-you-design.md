# "For You" Personalization — Design Spec

**Date:** 2026-08-09
**App:** Places (iOS 26.5, SwiftUI, Swift 6, `-default-isolation=MainActor`)
**Depends on:** Phase 2 data layer (`ContentStore`, `ContentProviding`, `Loadable`, `RemoteImage`, DTOs) and the auth phase (`SessionStore.currentProfile.interests`).

## Goal
Render the Home "For You" row from live Supabase content personalized to the user's picked interests — a **mix of destinations + experiences** — falling back to **trending** when there are no interests/matches. Replace the hardcoded `forYouItems`.

## Architecture
`ContentStore` gains `forYou: Loadable<[ForYouItem]>` + `loadForYou(interests:)`. The repo gains three granular fetches; the **store composes** the mix + fallback (unit-testable). `HomeTab` loads it in `.task` from `session?.currentProfile?.interests` and renders via the existing `loadableSection` + `PlaceCard`.

## Locked decisions
1. **Content:** a mix of destinations + experiences matching interests.
2. **Fallback:** trending experiences when interests empty or the mix is empty.

## Components

### 1. `ForYouItem` (Models/Content/ForYouItem.swift)
```
nonisolated enum ForYouItem: Identifiable {
    case destination(DestinationDTO)
    case experience(ExperienceDTO)
    var id: String            // "d-<id>" / "e-<uuid>"
    var imageURL: String      // destination.bannerUrl / experience.images.first ?? ""
    var title: String         // destination.name / experience.title
    var subtitle: String      // destination.subtitleLabel / "categoryLabel · KSh price"
}
```

### 2. `ForYouMapping` (Models/Content/ForYouMapping.swift)
`nonisolated enum ForYouMapping { static func destinationTags(for interests: [String]) -> [String] }` — deduped union from this map (grounded in the real `destinations.interest_tags`):
- wildlife_safaris → [wildlife_core, big_five, game_drive, rhino, elephants, birdwatching, great_migration, luxury_safari, photography]
- nature_hiking → [hiking, nature, mountaineering, trekking_primates, kilimanjaro_views, eco_conservation]
- cultural_heritage → [arts_culture, heritage, history_culture]
- arts_crafts → [arts_culture]
- adventure_sports → [adventure_camping, watersports, cycling]
- wellness_relaxation → [coastal_relaxation, beaches, honeymoon, snorkeling]
- food_coffee_tours → []  (experiences only)
- nightlife_music → []    (experiences only)

### 3. `ContentProviding` additions (Services/ContentRepository.swift)
```
func fetchExperiences(categoryTags: [String]) async throws -> [ExperienceDTO]
func fetchDestinations(matchingTags: [String]) async throws -> [DestinationDTO]
func fetchTrendingExperiences() async throws -> [ExperienceDTO]
```
Prod (PostgREST):
- experiences by tags: `.in("category_tag", value: categoryTags).order("rating", ascending: false).limit(8)`.
- destinations overlap: `.overlaps("interest_tags", value: matchingTags).order("rating", ascending: false).limit(8)` (fallback to `.filter("interest_tags", operator: "ov", value: "{a,b}")` if `.overlaps` isn't available in 2.54).
- trending: `.eq("is_trending", value: true).order("rating", ascending: false).limit(10)`.

### 4. `interleaveForYou` (free function, Models/Content/)
`func interleaveForYou(destinations: [DestinationDTO], experiences: [ExperienceDTO], cap: Int) -> [ForYouItem]` — alternates d, e, d, e…, appends leftovers, caps at `cap`.

### 5. `ContentStore.loadForYou(interests:force:)`
Guarded (skip when `.loaded`/`.loading` unless `force`). If interests non-empty: fetch experiences(categoryTags: interests) + (destTags empty ? [] : destinations(matchingTags: destTags)) concurrently, then `interleaveForYou(cap: 10)`. If the result is empty (or interests empty): `fetchTrendingExperiences().map(ForYouItem.experience)`. On throw → `.failed("Couldn't load recommendations.")`.

### 6. Wiring (Views/Tabs/HomeTab.swift)
- Add `@Environment(SessionStore.self) private var session: SessionStore?`.
- `loadContent()` also calls `await content?.loadForYou(interests: session?.currentProfile?.interests ?? [])`.
- `forYouSection` → `loadableSection(content?.forYou, empty: "Nothing here yet.", retry: …) { items in carousel(items) { item in PlaceCard(image: item.imageURL, title: item.title, subtitle: item.subtitle, width: 300, imageHeight: 210) tap→route(item) } }`.
- `route(_:)`: destination → `pushDestination(dto)`; experience → `router.showScreen(.push){ _ in ExperienceDetailView(experience: Experience(dto:)) }`.
- **Delete** `forYouItems`.

## Loading / empty / error
Skeleton while loading; `ContentEmptyState` only if even the trending fallback is empty; inline Retry on failure (re-runs with the current interests).

## Testing (Swift Testing)
- `ForYouMapping.destinationTags`: union + dedupe; food/nightlife → contribute nothing; unknown tag ignored.
- `ForYouItem` projection: id prefixes, imageURL/title/subtitle for each case.
- `interleaveForYou`: alternates, respects cap, handles empty sides.
- `ContentStore.loadForYou` via fake: interests → mixed (dest+exp) result; empty interests → trending; empty matches → trending; guarded refetch; failure → `.failed`.

## Scope
**In:** `ForYouItem`, `ForYouMapping`, `interleaveForYou`, 3 repo fetches (+ fake), `loadForYou`, wire the For You row, delete `forYouItems`, tests.
**Out:** My Trips / Recommendations / Curated / Upcoming (their own step); profile photo; itinerary grounding.
