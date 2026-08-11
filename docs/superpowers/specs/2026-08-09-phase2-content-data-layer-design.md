# Phase 2 — App Data Layer (Home + Explore content) — Design Spec

**Date:** 2026-08-09
**App:** Places (iOS 26.5, SwiftUI, Swift 6, `-default-isolation=MainActor`)
**Supabase project:** `bwafaffjhaxclcmrjhdg` (content tables are public-read; `supabase-swift` 2.54.1 already installed)

## Goal
Fetch Supabase content and wire five Home/Explore sections to render **live data**, with skeleton loading, empty, and error/retry states. **No hardcoded content anywhere** — sample datasets for the wired sections are deleted; if the DB returns zero rows the section shows an empty state.

## Architecture
A single `@Observable @MainActor ContentStore` (mirrors `SessionStore`) holds each section's state as `Loadable<T>` and is injected via `.environment`. It depends on a `ContentProviding` protocol seam (prod: `SupabaseContentRepository`; fake for tests). Views trigger section loads in `.task`, guarded so already-loaded in-memory data isn't refetched. Transport DTOs (Codable, match the DB) map to the existing UI structs; images render through one auto-detecting `RemoteImage`.

## Tech stack
`supabase-swift` (PostgREST via `SupabaseService.client.from`), SDWebImageSwiftUI (`WebImage`, already a dependency), Swift Testing.

## Global constraints
- iOS 26.5, Swift 6, `@Observable` (not `ObservableObject`). Data/DTO types are `nonisolated`.
- Content tables are public-read (anon key) — no auth required for these fetches.
- **No hardcoded content fallback.** Wired sections are loading / loaded / empty / failed only.
- In-memory cache only (no disk/offline this phase); SDWebImage still disk-caches images.
- Follow existing layout: DTOs in `Places/Models/Content/`, repo in `Places/Services/`, store in `Places/View Models/`.

## Locked decisions
1. **Loading UX:** redacted skeleton placeholder cards per section.
2. **Cache:** in-memory only (fetch on `.task`, keep for session).
3. **Scope:** only the cleanly-mapped sections (below).
4. **No hardcoded data:** empty state on zero rows; delete wired-section sample datasets.

## Components

### 1. `Loadable<T>` (Models/Content/Loadable.swift)
```
enum Loadable<T> { case idle, loading, loaded(T), failed(String) }
```
Views: `.idle`/`.loading` → skeleton; `.loaded(x)` where x is empty → empty state, else content; `.failed` → inline retry.

### 2. DTOs (Codable, snake_case CodingKeys) — Models/Content/
- **`DestinationDTO`**: id, name, category, countryCode, latitude, longitude, description, bannerUrl, images:[String], nonResidentFeeUsd:Double?, feeLabel:String?, vehicleFeeGuidelines:String?, paymentInfrastructure:String?, interestTags:[String], bestSeason:String?, closestHub:String?, rating:Double?, bestTimeToVisit:String?, priceRange:String?, isPopular:Bool. `Identifiable` (id).
- **`ExperienceDTO`**: id:UUID, title, images:[String], categoryTag, categoryLabel, cityId, pricePerGuest:Int, currency, rating:Double, reviewsCount:Int, isTrending:Bool, hostName, hostTagline, hostImageUrl:String?, locationName, locationArea, durationLabel, language, description, latitude:Double?, longitude:Double?.
- **`ExperienceCategoryDTO`**: tag, label, imageUrl:String?, sortOrder:Int.
- **`SponsoredDTO`**: id:UUID, imageUrl:String, accentHex:String?, category, title, subtitle, location, ctaLabel, cityId:String?, sortOrder:Int.

Nullable DB columns → optionals. All `nonisolated`.

### 3. DTO → UI mapping (Models/Content/…+Mapping.swift)
- `SponsoredDTO → Sponsored`: image=imageUrl, accentColor=`Color(hex: accentHex) ?? .accentColor`, offset=0, rest 1:1.
- `ExperienceDTO → Experience`: imageNames=images, hostImageName=(hostImageUrl ?? ""), city=`EACity(rawValue: cityId) ?? .nairobi`, rest 1:1.
- `ExperienceCategoryDTO → ExperienceCategory`: imageName=(imageUrl ?? ""), rest 1:1.
- `DestinationDTO`: consumed directly by the Popular Destinations card (name, "category · ★rating", bannerUrl) and by `ExploreDetailView` (full).
- Add `Color(hex:)` init (Utilities/Color+Hex.swift) if not already present.

### 4. `ContentProviding` + `SupabaseContentRepository` (Services/)
```
protocol ContentProviding {
    func fetchPopularDestinations() async throws -> [DestinationDTO]
    func fetchSponsored() async throws -> [SponsoredDTO]
    func fetchCategories() async throws -> [ExperienceCategoryDTO]
    func fetchExperiences(cityId: String?, categoryTag: String?) async throws -> [ExperienceDTO]
}
```
Prod impl uses `SupabaseService.client.from("…").select()…execute().value`:
- popular: `destinations` where `is_popular = true`, order `rating` desc.
- sponsored: `sponsored`, order `sort_order`.
- categories: `experience_categories`, order `sort_order`.
- experiences: `experiences`, optional `.eq("city_id", …)` and/or `.eq("category_tag", …)`, order `is_trending` desc then `rating` desc.

### 5. `ContentStore` (View Models/ContentStore.swift)
`@Observable @MainActor`, `init(content: ContentProviding = SupabaseContentRepository())`. State:
- `popularDestinations: Loadable<[DestinationDTO]>`
- `sponsored: Loadable<[Sponsored]>`
- `categories: Loadable<[ExperienceCategory]>`
- `experiencesByCity: [String: Loadable<[Experience]>]`
- `experiencesByCategory: [String: Loadable<[Experience]>]` (key `"cityId|categoryTag"`)

Methods (each guards: skip if already `.loaded`; set `.loading`; on success map DTO→UI + `.loaded`; on throw `.failed(message)`): `loadPopularDestinations()`, `loadSponsored()`, `loadCategories()`, `loadExperiences(cityId:)`, `loadExperiences(cityId:categoryTag:)`, and `retry…` variants that force a reload. Injected once at app root via `.environment`.

### 6. `RemoteImage` (Components/RemoteImage.swift)
`RemoteImage(_ source: String, width:, height:)`: if `source.hasPrefix("http")` → `WebImage(url:)` (resizable, fills, `.redacted`-friendly placeholder); else `DownsampledAssetImage(name: source)`. Content passes URLs; the local branch remains only for genuinely-local imagery (onboarding art), never as a content fallback. Replaces `DownsampledAssetImage(name:)` in the wired card views.

### 7. `ContentEmptyState` (Components/ContentEmptyState.swift)
Small reusable view (SF Symbol + short message) shown inside a section's frame when `.loaded([])`. e.g. "No destinations yet."

### 8. Section wiring (exactly these five; delete their sample data)
1. **Home · Popular Destinations** — delete `HomeTab.popularItems`; render `store.popularDestinations` (DestinationDTO) via the card with `RemoteImage(bannerUrl)`; tap → `ExploreDetailView(destination:)`.
2. **Home · Sponsored** — `SponsoredViewModel` → `@Observable`, drop its static cards, fetch via store/repo; `SponsoredCardView` image → `RemoteImage`.
3. **Home · Experience categories** — delete `ExperienceCategory.all`; render `store.categories`; `ExperienceCategoryCard` → `RemoteImage`.
4. **Home · Popular experiences in [city]** — delete `Experience.samples*`; render `store.experiencesByCity[city]`; `ExperienceHero`/caption → `RemoteImage`.
5. **Explore · category list** (`ExperienceCategoryListView`) — render `store.experiencesByCategory["city|tag"]`; same `RemoteImage` swap.

Each section: `.task { await store.load…() }`; body switches on the `Loadable` (skeleton / content / empty / retry).

### 9. `ExploreDetailView` upgrade
Accept the tapped `DestinationDTO` (new `init(destination:)`) and render real `description`, `feeLabel`, `interestTags`, `bannerUrl`. Remove the `Destination.samples.first` fallback. Keep the existing `init(title:imageName:)` path only if still used by not-yet-wired sections; otherwise remove.

## Loading / empty / error UX
- **Loading:** N placeholder cards with `.redacted(reason: .placeholder)` in each section's layout (no layout jump).
- **Empty:** `ContentEmptyState` inside the section frame.
- **Failed:** inline "Couldn't load · Retry" → calls the section's `retry…()`.

## Purge list (deleted this phase)
`HomeTab.popularItems`; `SponsoredViewModel` static card array; `ExperienceCategory.all`; `Experience.samples` + `samples(in:)` + `samples(tag:city:)`. Any preview relying on these gets a tiny inline fixture. (Not-yet-wired sample data — For You, Recommendations, Curated, Upcoming, My Trips — stays for later phases.)

## Testing (Swift Testing)
- DTO decode from representative snake_case JSON for each of the four tables.
- Mapping: `accent_hex`→`Color` (incl. nil default), `city_id`→`EACity` (incl. unknown→nairobi), field parity.
- `ContentStore` transitions via a fake `ContentProviding`: idle→loading→loaded; loaded-empty stays empty; throw→failed; retry re-fetches; guard skips refetch when already loaded.
- `Color(hex:)` parsing (valid, `#`-prefixed, invalid→nil).

## Scope
**In:** `Loadable`, 4 DTOs + mappers, `Color(hex:)`, `ContentProviding` + `SupabaseContentRepository`, `ContentStore`, `RemoteImage`, `ContentEmptyState`, wire the 5 sections + `ExploreDetailView`, delete the wired sample data, tests.
**Out:** For You, profile photo, Recommendations/Curated/Upcoming backing, itinerary grounding, disk/offline cache, city picker changes (default Nairobi).
