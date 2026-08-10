---
name: places-itinerary-architecture
description: Architecture snapshot of the AI itinerary generation → trips feature (August 2026). Covers state management choices, MainActor isolation pattern, service/VM/View boundaries, known issues, and file map.
metadata:
  type: project
---

## State management
- iOS 26 / Swift 6 with `-default-isolation=MainActor`. Two global stores are `@Observable @MainActor`: `SessionStore` (auth phase + profile) and `ContentStore` (Home/Explore content). Exception: `SponsoredViewModel` and `TripConfigViewModel` still use `ObservableObject / @Published` — mixed pattern, planned migration in CP2.
- `@State` used correctly in views to own VMs (e.g. `@State private var vm: ItineraryChatViewModel` in GenerateItineraryView).
- `PlaceRegistry` is `@MainActor @Observable`.
- Both root stores injected via `.environment()` at `PlacesApp`; read in views as `@Environment(Store.self) var store: Store?` (optional for preview safety).

## Service layer
- Protocol: `ItineraryEngine` (`@MainActor` protocol with `AsyncThrowingStream` return types).
- Concrete impls: `OnDeviceItineraryEngine` (FoundationModels), `CloudItineraryEngine` (stub).
- Factory: `ItineraryEngineFactory.make(kind:systemPrompt:registry:apiKey:resumeTranscript:)`.
- Tool: `FindPlacesTool` — hardcoded 16-place East Africa catalog, `@Generable enum PlaceKind`, registers into `PlaceRegistry` via `MainActor.run`.
- **Auth/Session seam:** `AuthProviding` protocol + `SupabaseAuthProvider` struct; `ProfileProviding` + `ProfileRepository` struct. Both concrete types call `SupabaseService.client` (global singleton) — testable via protocol, but singleton is still a hidden dep inside impls.
- **Content seam:** `ContentProviding` + `SupabaseContentRepository` struct. DEFECT: `ContentStore.init` defaults to `SupabaseContentRepository()` rather than requiring injection (`init(content: ContentProviding = SupabaseContentRepository())`). This wires the concrete type into the store at call-site; previews and tests silently go live.
- `SupabaseService.client` is a global singleton (enum case, lazy-initialized). All repositories reference it directly — not injectable without protocol wrapping the client.

## ViewModel
- `ItineraryChatViewModel` — generation + versioning + persistence + system-prompt building + cover image derivation. Monolithic but intentional for current scope.
- `saveAsTrip(context: ModelContext)` — ModelContext injected from View. Acceptable for now; refactor target when a TripRepository is introduced.
- All JSON encode/decode (transcript, itinerary) happens synchronously on MainActor in `saveAsTrip`. Measured hazard only at save time (not streaming).

## Known architectural issues (ranked)
1. CRITICAL — `background` in GenerateItineraryView creates `RiveViewModel(fileName:"shapes")` on every body render (line 250). Needs `@State`.
2. CRITICAL — `mapPlaces` computed var in ItineraryMessageView does registry lookups + dedup on every body render during streaming (line 92). Should be a `let` or cached.
3. CRITICAL (NEW — auth/session) — `SessionStore.saveInterests` / `completeOnboarding` / `resetOnboarding` optimistically mutate `currentProfile` in-place before the network call succeeds. If the await throws (silently via `try?`), local and remote state diverge with no recovery path.
4. CRITICAL (NEW — content layer) — `ContentStore.init(content: ContentProviding = SupabaseContentRepository())` uses a default concrete type. `PlacesApp` calls `ContentStore()` with no argument, so the production type is hardwired. Previews and unit tests silently use the live Supabase client.
5. CRITICAL (NEW — duplicate in-flight loads) — `ContentStore` load functions have no in-flight guard; calling `loadPopularDestinations()` twice concurrently (e.g. two `.task` re-triggers) transitions to `.loading` and issues two parallel network requests, with the second overwriting the first's result.
6. IMPORTANT — Force-unwrap `itineraryVersions.last!` (ItineraryChatViewModel line 156). Guard protects it but is fragile.
7. IMPORTANT — `savedTripID` reset on every `recordVersion` call enables duplicate trips if user edits → saves → edits → saves (line 143).
8. IMPORTANT — `ForEach(Array(days.enumerated()), id: \.offset)` (ItineraryMessageView line 53, 119) — offset IDs cause full re-render diffs during streaming. Use `id: \.element.title` or stable UUID.
9. IMPORTANT — `TripConfigViewModel` uses `ObservableObject` / Combine; `SponsoredViewModel` too. Two stores are `@Observable`, two VMs are not — mixed pattern.
10. IMPORTANT (NEW — identity) — `Experience.id = UUID()` and `ExperienceCategory.id = UUID()` are `let` but assigned at init time without a stable seed. Every mapping call from DTO produces a different identity — ForEach diffs collapse on CP2 wiring.
11. IMPORTANT (NEW — mapping boundary) — `Sponsored` carries `offset: CGFloat` (drag state) and `id: UUID = .init()` — both are regenerated on every `Sponsored(dto:)` call. The drag offset will reset to 0 on any ContentStore reload.
12. MODERATE (NEW) — `Auth.swift:41-46` uses `DispatchQueue.main.asyncAfter` inside `onAppear` for animation delays. Prefer `Task { try? await Task.sleep(for:) }` or `.task` + sleep to stay in the Swift concurrency model.
13. MODERATE — `describe` and `transcriptData` (JSON encode of session.transcript) synchronous on MainActor — acceptable today, flag if transcript grows large.
14. MODERATE — `refine()` replaces `session` (OnDeviceItineraryEngine line 115) — side-effectful, not raceable because of `@MainActor`, but mutates engine state during streaming.
15. MINOR — `configCard`/`configRow` dead code in GenerateItineraryView (lines 260–289) — never rendered.
16. MINOR — `print` debug logging throughout engine (dozens of calls).
17. MINOR (NEW) — `SupabaseConfig.anonKey` is hardcoded in source. Acceptable for an anon key but flagged — move to .xcconfig for cleaner secret hygiene.

## Coupling notes
- `FindPlacesTool.allPlaces` static — engine reaches into tool's catalog directly (refine path). Acceptable workaround for FoundationModels tool-loop bug; needs comment.
- `SavedTrip.displayTrip` → `Trip` struct bridges to legacy display model. Thin shim, not a real problem.
- `PlaceRegistry` shared via init injection between tool (writes) and VM→View (reads). Clean unidirectional data flow.

## Navigation / presentation
- `fullScreenCover(item: $itineraryConfig)` in AppTab. Two-step dismiss via `pendingConfig` → `itineraryConfig` (AppTab lines 96–109) avoids sheet-over-sheet race.

## Testability
- `ItineraryEngine` protocol is injectable; VM takes it at factory level. Not directly injectable into VM init today.
- `ModelContext` injected from view via `saveAsTrip(context:)` — not unit-testable without SwiftData.
- `@AppStorage("aiModelKind")` in View — hidden global state that VM behavior depends on.
- `PlaceRegistry` is `@MainActor` — needs test harness with `MainActor.run`.

## File map
- Models: Places/Models/Itinerary/{GeneratedItinerary,PlaceRegistry,SavedTrip}.swift, Places/Models/AI/{AIModelKind,AIAvailability}.swift
- Services: Places/Services/Itinerary/{ItineraryEngine,OnDeviceItineraryEngine,CloudItineraryEngine}.swift, Places/Services/Itinerary/Tools/FindPlacesTool.swift
- ViewModels: Places/View Models/CreateViewModels/{ItineraryChatViewModel,TripConfigViewModel}.swift
- Views: Places/Views/Create/{GenerateItineraryView,ItineraryMessageView,ModelPickerSheet}.swift, Places/Views/Tabs/AppTab.swift, Places/Views/Profile/MyTripsView.swift
- App: Places/App/PlacesApp.swift

**Why:** Single-commit initial build; active feature development expected. This snapshot is for tracking known issues across conversations.
**How to apply:** Use this to orient quickly without re-reading all files. Verify file paths before recommending — this is a snapshot.
