# Phase 2 — App Data Layer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fetch Supabase content and wire five Home/Explore sections to live data with skeleton/empty/retry states, deleting the wired sections' hardcoded sample data.

**Architecture:** An `@Observable @MainActor ContentStore` holds each section's `Loadable<T>` state and calls a `ContentProviding` seam (prod: `SupabaseContentRepository` over `SupabaseService.client`). Codable DTOs match the DB and map to the existing UI structs at render; images render through one auto-detecting `RemoteImage`. No hardcoded content fallback — zero rows renders an empty state.

**Tech Stack:** supabase-swift 2.54.1 (PostgREST), SDWebImageSwiftUI (`WebImage`), Swift Testing.

## Global Constraints
- iOS 26.5, Swift 6, `-default-isolation=MainActor`. Use `@Observable`, not `ObservableObject`. DTOs/data types are `nonisolated`.
- Content tables are public-read (anon key) — no auth needed for these fetches.
- **No hardcoded content fallback.** Wired sections = loading / loaded / empty / failed only.
- In-memory cache only. Follow layout: DTOs in `Places/Models/Content/`, repo in `Places/Services/`, store in `Places/View Models/`, shared views in `Places/Components/`.
- Verify commands: `xcodebuild test -scheme Places -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:PlacesTests` (tests) and `xcodebuild build -scheme Places -destination 'platform=iOS Simulator,name=iPhone 17 Pro'` (build). Interactive checks on the booted iPhone 17 Pro via Argent.

## File Structure
**Create:**
- `Places/Models/Content/Loadable.swift` — `Loadable<T>` enum.
- `Places/Models/Content/ContentDTOs.swift` — `DestinationDTO`, `ExperienceDTO`, `ExperienceCategoryDTO`, `SponsoredDTO`.
- `Places/Models/Content/ContentMapping.swift` — `Sponsored(dto:)`, `Experience(dto:)`, `ExperienceCategory(dto:)`.
- `Places/Utilities/Color+Hex.swift` — `Color(hex:)`.
- `Places/Services/ContentRepository.swift` — `ContentProviding` + `SupabaseContentRepository`.
- `Places/View Models/ContentStore.swift` — the store.
- `Places/Components/RemoteImage.swift`, `Places/Components/ContentEmptyState.swift`.
- `PlacesTests/ColorHexTests.swift`, `ContentDTOTests.swift`, `ContentMappingTests.swift`, `ContentStoreTests.swift`, `Fakes/FakeContentProviding.swift`.

**Modify:**
- `Places/App/PlacesApp.swift` — inject `ContentStore`.
- `Places/Views/Tabs/HomeTab.swift` — wire Popular Destinations, Categories, Popular-experiences sections; delete `popularItems`.
- `Places/View Models/HomeViewModels/SponsoredViewModel.swift` — `@Observable` + fetch; delete static cards.
- `Places/Components/Home/SponsoredCardView.swift`, `Places/Components/Explore/ExperienceCategoryCard.swift`, `Places/Components/Explore/ExperienceCard.swift` — `DownsampledAssetImage`→`RemoteImage`.
- `Places/Models/Explore/Experience.swift` — delete `samples*`. `Places/Models/Explore/ExperienceCategory.swift` — delete `all`.
- `Places/Views/Explore/ExperienceCategoryListView.swift` — fetch by category.
- `Places/Views/Explore/ExploreDetailView.swift` — accept `DestinationDTO`.

---

### Task 1: `Loadable` + `Color(hex:)`

**Files:** Create `Places/Models/Content/Loadable.swift`, `Places/Utilities/Color+Hex.swift`; Test `PlacesTests/ColorHexTests.swift`.

**Interfaces:**
- Produces: `enum Loadable<T> { case idle, loading, loaded(T), failed(String) }`; `Color.init?(hex: String?)`.

- [ ] **Step 1: Write `Loadable`.**
```swift
nonisolated enum Loadable<T> {
    case idle, loading, loaded(T), failed(String)
}
```
- [ ] **Step 2: Write the failing Color test.**
```swift
import Testing
import SwiftUI
@testable import Places

struct ColorHexTests {
    @Test func validHexProducesColor() { #expect(Color(hex: "#1E88E5") != nil) }
    @Test func noHashStillParses()     { #expect(Color(hex: "1E88E5") != nil) }
    @Test func nilReturnsNil()         { #expect(Color(hex: nil) == nil) }
    @Test func garbageReturnsNil()     { #expect(Color(hex: "nope") == nil) }
}
```
- [ ] **Step 3: Run — expect fail** (`Color(hex:)` undefined). Command: the `-only-testing:PlacesTests/ColorHexTests` variant of the test command.
- [ ] **Step 4: Implement `Color(hex:)`.**
```swift
import SwiftUI

extension Color {
    /// Parses "#RRGGBB" / "RRGGBB". Returns nil for nil or malformed input.
    init?(hex: String?) {
        guard var hex else { return nil }
        hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hex.hasPrefix("#") { hex.removeFirst() }
        guard hex.count == 6, let value = UInt64(hex, radix: 16) else { return nil }
        self = Color(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}
```
- [ ] **Step 5: Run — expect pass.**
- [ ] **Step 6: Commit.** `git commit -am "feat: Loadable + Color(hex:)"`

---

### Task 2: Content DTOs (TDD decode)

**Files:** Create `Places/Models/Content/ContentDTOs.swift`; Test `PlacesTests/ContentDTOTests.swift`.

**Interfaces:**
- Produces: `DestinationDTO` (Identifiable, id:String), `ExperienceDTO` (id:UUID), `ExperienceCategoryDTO` (Identifiable via tag), `SponsoredDTO` (id:UUID) — all Codable, nonisolated.

- [ ] **Step 1: Write the failing tests** (snake_case rows decode; optionals tolerate null):
```swift
import Testing
import Foundation
@testable import Places

struct ContentDTOTests {
    private func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        try JSONDecoder().decode(T.self, from: Data(json.utf8))
    }

    @Test func experienceDecodes() throws {
        let e = try decode(ExperienceDTO.self, """
        {"id":"\(UUID().uuidString)","title":"Game Drive","images":["https://x/1.jpg"],
         "category_tag":"wildlife_safaris","category_label":"Wildlife safaris","city_id":"nairobi",
         "price_per_guest":6500,"currency":"KSh","rating":4.9,"reviews_count":820,"is_trending":true,
         "host_name":"Samuel","host_tagline":"Guide","host_image_url":null,"location_name":"NNP",
         "location_area":"Nairobi","duration_label":"4 hr","language":"English","description":"...",
         "latitude":-1.37,"longitude":36.85}
        """)
        #expect(e.cityId == "nairobi"); #expect(e.hostImageUrl == nil); #expect(e.images.count == 1)
    }
    @Test func sponsoredDecodes() throws {
        let s = try decode(SponsoredDTO.self, """
        {"id":"\(UUID().uuidString)","image_url":"https://x/s.jpg","accent_hex":null,"category":"Food",
         "title":"Mama Oliech","subtitle":"Fish","location":"Nairobi","cta_label":"Directions",
         "city_id":"nairobi","sort_order":1}
        """)
        #expect(s.accentHex == nil); #expect(s.ctaLabel == "Directions")
    }
    @Test func categoryDecodesAndIdIsTag() throws {
        let c = try decode(ExperienceCategoryDTO.self,
            #"{"tag":"wildlife_safaris","label":"Wildlife safaris","image_url":null,"sort_order":1}"#)
        #expect(c.id == "wildlife_safaris")
    }
    @Test func destinationDecodes() throws {
        let d = try decode(DestinationDTO.self, """
        {"id":"ke_maasai_mara","name":"Maasai Mara","category":"Reserve","country_code":"KE",
         "latitude":-1.5,"longitude":35.1,"description":"...","banner_url":"https://x/b.jpg","images":[],
         "non_resident_fee_usd":100,"fee_label":"$100–$200","vehicle_fee_guidelines":null,
         "payment_infrastructure":null,"interest_tags":["wildlife"],"best_season":"Jul","closest_hub":"Narok",
         "rating":4.9,"best_time_to_visit":"Jul–Oct","price_range":"$$$","is_popular":true}
        """)
        #expect(d.isPopular); #expect(d.feeLabel == "$100–$200")
    }
}
```
- [ ] **Step 2: Run — expect fail.**
- [ ] **Step 3: Implement the DTOs.**
```swift
import Foundation

nonisolated struct DestinationDTO: Codable, Identifiable {
    let id: String
    let name: String
    let category: String
    let countryCode: String
    let latitude: Double
    let longitude: Double
    let description: String
    let bannerUrl: String
    let images: [String]
    let nonResidentFeeUsd: Double?
    let feeLabel: String?
    let vehicleFeeGuidelines: String?
    let paymentInfrastructure: String?
    let interestTags: [String]
    let bestSeason: String?
    let closestHub: String?
    let rating: Double?
    let bestTimeToVisit: String?
    let priceRange: String?
    let isPopular: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, category, latitude, longitude, description, images, rating
        case countryCode = "country_code"
        case bannerUrl = "banner_url"
        case nonResidentFeeUsd = "non_resident_fee_usd"
        case feeLabel = "fee_label"
        case vehicleFeeGuidelines = "vehicle_fee_guidelines"
        case paymentInfrastructure = "payment_infrastructure"
        case interestTags = "interest_tags"
        case bestSeason = "best_season"
        case closestHub = "closest_hub"
        case bestTimeToVisit = "best_time_to_visit"
        case priceRange = "price_range"
        case isPopular = "is_popular"
    }
}

nonisolated struct ExperienceDTO: Codable, Identifiable {
    let id: UUID
    let title: String
    let images: [String]
    let categoryTag: String
    let categoryLabel: String
    let cityId: String
    let pricePerGuest: Int
    let currency: String
    let rating: Double
    let reviewsCount: Int
    let isTrending: Bool
    let hostName: String
    let hostTagline: String
    let hostImageUrl: String?
    let locationName: String
    let locationArea: String
    let durationLabel: String
    let language: String
    let description: String
    let latitude: Double?
    let longitude: Double?

    enum CodingKeys: String, CodingKey {
        case id, title, images, currency, rating, language, description, latitude, longitude
        case categoryTag = "category_tag"
        case categoryLabel = "category_label"
        case cityId = "city_id"
        case pricePerGuest = "price_per_guest"
        case reviewsCount = "reviews_count"
        case isTrending = "is_trending"
        case hostName = "host_name"
        case hostTagline = "host_tagline"
        case hostImageUrl = "host_image_url"
        case locationName = "location_name"
        case locationArea = "location_area"
        case durationLabel = "duration_label"
    }
}

nonisolated struct ExperienceCategoryDTO: Codable, Identifiable {
    let tag: String
    let label: String
    let imageUrl: String?
    let sortOrder: Int
    var id: String { tag }
    enum CodingKeys: String, CodingKey {
        case tag, label
        case imageUrl = "image_url"
        case sortOrder = "sort_order"
    }
}

nonisolated struct SponsoredDTO: Codable, Identifiable {
    let id: UUID
    let imageUrl: String
    let accentHex: String?
    let category: String
    let title: String
    let subtitle: String
    let location: String
    let ctaLabel: String
    let cityId: String?
    let sortOrder: Int
    enum CodingKeys: String, CodingKey {
        case id, category, title, subtitle, location
        case imageUrl = "image_url"
        case accentHex = "accent_hex"
        case ctaLabel = "cta_label"
        case cityId = "city_id"
        case sortOrder = "sort_order"
    }
}
```
- [ ] **Step 4: Run — expect pass.**
- [ ] **Step 5: Commit.** `git commit -am "feat: content DTOs"`

---

### Task 3: DTO → UI mappers (TDD)

**Files:** Create `Places/Models/Content/ContentMapping.swift`; Test `PlacesTests/ContentMappingTests.swift`.

**Interfaces:**
- Consumes: `SponsoredDTO`, `ExperienceDTO`, `ExperienceCategoryDTO`, `Sponsored`, `Experience`, `ExperienceCategory`, `EACity`, `Color(hex:)`.
- Produces: `Sponsored.init(dto:)`, `Experience.init(dto:)`, `ExperienceCategory.init(dto:)`.

- [ ] **Step 1: Write the failing tests.**
```swift
import Testing
import Foundation
@testable import Places

struct ContentMappingTests {
    @Test func experienceMapsCityAndImages() {
        let dto = ExperienceDTO(id: UUID(), title: "T", images: ["u1","u2"], categoryTag: "wildlife_safaris",
            categoryLabel: "Wildlife safaris", cityId: "kampala", pricePerGuest: 100, currency: "KSh",
            rating: 4.5, reviewsCount: 10, isTrending: true, hostName: "H", hostTagline: "tag",
            hostImageUrl: "https://h.jpg", locationName: "L", locationArea: "A", durationLabel: "2 hr",
            language: "English", description: "d", latitude: nil, longitude: nil)
        let e = Experience(dto: dto)
        #expect(e.city == .kampala); #expect(e.imageNames == ["u1","u2"]); #expect(e.hostImageName == "https://h.jpg")
    }
    @Test func experienceUnknownCityDefaultsNairobi() {
        let dto = ExperienceDTO(id: UUID(), title: "T", images: [], categoryTag: "x", categoryLabel: "X",
            cityId: "atlantis", pricePerGuest: 1, currency: "KSh", rating: 1, reviewsCount: 0, isTrending: false,
            hostName: "", hostTagline: "", hostImageUrl: nil, locationName: "", locationArea: "",
            durationLabel: "", language: "", description: "", latitude: nil, longitude: nil)
        #expect(Experience(dto: dto).city == .nairobi)
        #expect(Experience(dto: dto).hostImageName == "")
    }
    @Test func categoryMapsImageUrl() {
        let c = ExperienceCategory(dto: ExperienceCategoryDTO(tag: "t", label: "L", imageUrl: "https://c.jpg", sortOrder: 1))
        #expect(c.imageName == "https://c.jpg"); #expect(c.tag == "t")
    }
}
```
- [ ] **Step 2: Run — expect fail.**
- [ ] **Step 3: Implement mappers.**
```swift
import SwiftUI

extension Sponsored {
    init(dto: SponsoredDTO) {
        self.init(
            id: dto.id,
            image: dto.imageUrl,
            accentColor: Color(hex: dto.accentHex) ?? .accent,
            offset: 0,
            category: dto.category,
            title: dto.title,
            subtitle: dto.subtitle,
            location: dto.location,
            ctaLabel: dto.ctaLabel
        )
    }
}

extension Experience {
    init(dto: ExperienceDTO) {
        self.init(
            title: dto.title,
            imageNames: dto.images,
            categoryTag: dto.categoryTag,
            categoryLabel: dto.categoryLabel,
            city: EACity(rawValue: dto.cityId) ?? .nairobi,
            pricePerGuest: dto.pricePerGuest,
            currency: dto.currency,
            rating: dto.rating,
            reviewsCount: dto.reviewsCount,
            isTrending: dto.isTrending,
            hostName: dto.hostName,
            hostTagline: dto.hostTagline,
            hostImageName: dto.hostImageUrl ?? "",
            locationName: dto.locationName,
            locationArea: dto.locationArea,
            durationLabel: dto.durationLabel,
            language: dto.language,
            description: dto.description
        )
    }
}

extension ExperienceCategory {
    init(dto: ExperienceCategoryDTO) {
        self.init(label: dto.label, imageName: dto.imageUrl ?? "", tag: dto.tag)
    }
}
```
(`Color.accent` is the asset the app already uses, e.g. in `Auth.glowBorder`. If `EACity`'s raw values differ from the DB ids, add a `EACity(cityId:)` shim — verify `EACity.nairobi.rawValue == "nairobi"` etc. while implementing.)
- [ ] **Step 4: Run — expect pass.**
- [ ] **Step 5: Commit.** `git commit -am "feat: DTO→UI mappers"`

---

### Task 4: `ContentProviding` + `SupabaseContentRepository`

**Files:** Create `Places/Services/ContentRepository.swift`. Build-verify (fake drives Task 5 tests).

**Interfaces:**
- Produces: `protocol ContentProviding { func fetchPopularDestinations() async throws -> [DestinationDTO]; func fetchSponsored() async throws -> [SponsoredDTO]; func fetchCategories() async throws -> [ExperienceCategoryDTO]; func fetchExperiences(cityId: String?, categoryTag: String?) async throws -> [ExperienceDTO] }`, `struct SupabaseContentRepository: ContentProviding`.

- [ ] **Step 1: Implement.**
```swift
import Foundation
import Supabase

protocol ContentProviding {
    func fetchPopularDestinations() async throws -> [DestinationDTO]
    func fetchSponsored() async throws -> [SponsoredDTO]
    func fetchCategories() async throws -> [ExperienceCategoryDTO]
    func fetchExperiences(cityId: String?, categoryTag: String?) async throws -> [ExperienceDTO]
}

struct SupabaseContentRepository: ContentProviding {
    private var db: SupabaseClient { SupabaseService.client }

    func fetchPopularDestinations() async throws -> [DestinationDTO] {
        try await db.from("destinations").select().eq("is_popular", value: true)
            .order("rating", ascending: false).execute().value
    }
    func fetchSponsored() async throws -> [SponsoredDTO] {
        try await db.from("sponsored").select().order("sort_order").execute().value
    }
    func fetchCategories() async throws -> [ExperienceCategoryDTO] {
        try await db.from("experience_categories").select().order("sort_order").execute().value
    }
    func fetchExperiences(cityId: String?, categoryTag: String?) async throws -> [ExperienceDTO] {
        var query = db.from("experiences").select()
        if let cityId { query = query.eq("city_id", value: cityId) }
        if let categoryTag { query = query.eq("category_tag", value: categoryTag) }
        return try await query.order("is_trending", ascending: false)
            .order("rating", ascending: false).execute().value
    }
}
```
(If chaining `.eq` after `.select()` reassignment fights the builder's types, capture the filtered builder before `.order`; adjust to the compiler-reported `PostgrestFilterBuilder`/`PostgrestTransformBuilder` types — the calls are stable.)
- [ ] **Step 2: Verify build.** `xcodebuild build …` → BUILD SUCCEEDED.
- [ ] **Step 3: Commit.** `git commit -am "feat: SupabaseContentRepository"`

---

### Task 5: `ContentStore` (TDD)

**Files:** Create `Places/View Models/ContentStore.swift`; Test `PlacesTests/ContentStoreTests.swift`, `PlacesTests/Fakes/FakeContentProviding.swift`.

**Interfaces:**
- Consumes: `ContentProviding`, DTOs, `Loadable`.
- Produces: `@Observable @MainActor final class ContentStore` with `popularDestinations`, `sponsored`, `categories`, `experiencesByCity`, `experiencesByCategory` and `load…`/`force` methods below.

- [ ] **Step 1: Write the fake.**
```swift
import Foundation
@testable import Places

final class FakeContentProviding: ContentProviding, @unchecked Sendable {
    var destinations: [DestinationDTO] = []
    var experiences: [ExperienceDTO] = []
    var shouldThrow = false
    private(set) var fetchCount = 0

    func fetchPopularDestinations() async throws -> [DestinationDTO] { try emit(destinations) }
    func fetchSponsored() async throws -> [SponsoredDTO] { try emit([]) }
    func fetchCategories() async throws -> [ExperienceCategoryDTO] { try emit([]) }
    func fetchExperiences(cityId: String?, categoryTag: String?) async throws -> [ExperienceDTO] { try emit(experiences) }

    private func emit<T>(_ v: [T]) throws -> [T] {
        fetchCount += 1
        if shouldThrow { throw URLError(.badServerResponse) }
        return v
    }
}
```
- [ ] **Step 2: Write the failing tests.**
```swift
import Testing
import Foundation
@testable import Places

@MainActor
struct ContentStoreTests {
    private func loadedCount<T>(_ l: Loadable<[T]>) -> Int? {
        if case .loaded(let v) = l { return v.count }; return nil
    }
    private func isFailed<T>(_ l: Loadable<[T]>) -> Bool {
        if case .failed = l { return true }; return false
    }

    @Test func loadsDestinations() async {
        let fake = FakeContentProviding()
        fake.destinations = [Self.destFixture()]
        let store = ContentStore(content: fake)
        await store.loadPopularDestinations()
        #expect(loadedCount(store.popularDestinations) == 1)
    }
    @Test func emptyStaysLoadedEmpty() async {
        let store = ContentStore(content: FakeContentProviding())
        await store.loadPopularDestinations()
        #expect(loadedCount(store.popularDestinations) == 0)
    }
    @Test func failureIsFailed() async {
        let fake = FakeContentProviding(); fake.shouldThrow = true
        let store = ContentStore(content: fake)
        await store.loadPopularDestinations()
        #expect(isFailed(store.popularDestinations))
    }
    @Test func guardSkipsRefetch() async {
        let fake = FakeContentProviding()
        let store = ContentStore(content: fake)
        await store.loadPopularDestinations()
        await store.loadPopularDestinations()
        #expect(fake.fetchCount == 1)
    }
    @Test func forceRefetches() async {
        let fake = FakeContentProviding()
        let store = ContentStore(content: fake)
        await store.loadPopularDestinations()
        await store.loadPopularDestinations(force: true)
        #expect(fake.fetchCount == 2)
    }

    static func destFixture() -> DestinationDTO {
        DestinationDTO(id: "x", name: "N", category: "C", countryCode: "KE", latitude: 0, longitude: 0,
            description: "", bannerUrl: "https://b.jpg", images: [], nonResidentFeeUsd: nil, feeLabel: nil,
            vehicleFeeGuidelines: nil, paymentInfrastructure: nil, interestTags: [], bestSeason: nil,
            closestHub: nil, rating: 4.5, bestTimeToVisit: nil, priceRange: nil, isPopular: true)
    }
}
```
- [ ] **Step 3: Run — expect fail.**
- [ ] **Step 4: Implement `ContentStore`.**
```swift
import Foundation
import Observation

@Observable @MainActor
final class ContentStore {
    private(set) var popularDestinations: Loadable<[DestinationDTO]> = .idle
    private(set) var sponsored: Loadable<[SponsoredDTO]> = .idle
    private(set) var categories: Loadable<[ExperienceCategoryDTO]> = .idle
    private(set) var experiencesByCity: [String: Loadable<[ExperienceDTO]>] = [:]
    private(set) var experiencesByCategory: [String: Loadable<[ExperienceDTO]>] = [:]

    private let content: ContentProviding
    init(content: ContentProviding = SupabaseContentRepository()) { self.content = content }

    func loadPopularDestinations(force: Bool = false) async {
        if case .loaded = popularDestinations, !force { return }
        popularDestinations = .loading
        do { popularDestinations = .loaded(try await content.fetchPopularDestinations()) }
        catch { popularDestinations = .failed("Couldn't load destinations.") }
    }
    func loadSponsored(force: Bool = false) async {
        if case .loaded = sponsored, !force { return }
        sponsored = .loading
        do { sponsored = .loaded(try await content.fetchSponsored()) }
        catch { sponsored = .failed("Couldn't load sponsors.") }
    }
    func loadCategories(force: Bool = false) async {
        if case .loaded = categories, !force { return }
        categories = .loading
        do { categories = .loaded(try await content.fetchCategories()) }
        catch { categories = .failed("Couldn't load categories.") }
    }
    func loadExperiences(cityId: String, force: Bool = false) async {
        if case .loaded = (experiencesByCity[cityId] ?? .idle), !force { return }
        experiencesByCity[cityId] = .loading
        do { experiencesByCity[cityId] = .loaded(try await content.fetchExperiences(cityId: cityId, categoryTag: nil)) }
        catch { experiencesByCity[cityId] = .failed("Couldn't load experiences.") }
    }
    func loadExperiences(cityId: String, categoryTag: String, force: Bool = false) async {
        let key = "\(cityId)|\(categoryTag)"
        if case .loaded = (experiencesByCategory[key] ?? .idle), !force { return }
        experiencesByCategory[key] = .loading
        do { experiencesByCategory[key] = .loaded(try await content.fetchExperiences(cityId: cityId, categoryTag: categoryTag)) }
        catch { experiencesByCategory[key] = .failed("Couldn't load experiences.") }
    }
}
```
- [ ] **Step 5: Run — expect pass.**
- [ ] **Step 6: Commit.** `git commit -am "feat: ContentStore"`

---

### Task 6: `RemoteImage` + `ContentEmptyState`

**Files:** Create `Places/Components/RemoteImage.swift`, `Places/Components/ContentEmptyState.swift`. Build-verify.

**Interfaces:**
- Produces: `RemoteImage(_ source: String, width: CGFloat, height: CGFloat)`, `ContentEmptyState(icon: String, message: String)`.

- [ ] **Step 1: Implement `RemoteImage`.**
```swift
import SwiftUI
import SDWebImageSwiftUI

/// Auto-detects source: an http(s) URL renders remotely (disk-cached by SDWebImage);
/// anything else is treated as a local asset name. Content always passes URLs.
struct RemoteImage: View {
    let source: String
    var width: CGFloat
    var height: CGFloat

    init(_ source: String, width: CGFloat, height: CGFloat) {
        self.source = source; self.width = width; self.height = height
    }

    var body: some View {
        if source.hasPrefix("http"), let url = URL(string: source) {
            WebImage(url: url)
                .resizable()
                .indicator(.activity)
                .transition(.fade(duration: 0.25))
                .scaledToFill()
                .frame(width: width, height: height)
                .clipped()
        } else {
            DownsampledAssetImage(name: source, width: width, height: height)
        }
    }
}
```
(Confirm `DownsampledAssetImage`'s initializer label set — from the map it takes `name:width:height:`. Match it.)
- [ ] **Step 2: Implement `ContentEmptyState`.**
```swift
import SwiftUI

struct ContentEmptyState: View {
    var icon: String = "tray"
    var message: String
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.title2).foregroundStyle(.secondary)
            Text(message).font(.system(.subheadline, design: .rounded)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}
```
- [ ] **Step 3: Verify build.** `xcodebuild build …` → BUILD SUCCEEDED. (If `import SDWebImageSwiftUI` isn't resolvable in the target, confirm the product is linked; it's already a dependency.)
- [ ] **Step 4: Commit.** `git commit -am "feat: RemoteImage + ContentEmptyState"`

---

### Task 7: Inject `ContentStore` at app root

**Files:** Modify `Places/App/PlacesApp.swift`. Build-verify.

- [ ] **Step 1: Add the store + inject.** Add `@State private var content = ContentStore()` and `.environment(content)` on the `RouterView` (next to `.environment(session)`).
- [ ] **Step 2: Verify build.** `xcodebuild build …` → BUILD SUCCEEDED.
- [ ] **Step 3: Commit.** `git commit -am "feat: inject ContentStore"`

---

### Tasks 8–12: Wire the five sections (pattern)

Each wiring task follows the same shape. Read the current section body first. Apply:

**A. Read the store from the environment** in the view/component: `@Environment(ContentStore.self) private var content: ContentStore?`.
**B. Trigger the load** on the tab/section with `.task { await content?.load…() }` (idempotent — the store guards).
**C. Replace the sample source with a `Loadable` switch** rendering:
```swift
switch content?.<section> ?? .idle {
case .idle, .loading:
    // N placeholder cards, real layout, then:
    // <PlaceholderCards>.redacted(reason: .placeholder)
case .loaded(let items) where items.isEmpty:
    ContentEmptyState(message: "<Nothing here yet>")
case .loaded(let dtos):
    // ForEach(dtos) { dto in <Card>(… map dto → UI struct where needed …) }
case .failed(let message):
    VStack(spacing: 8) {
        Text(message).font(.footnote).foregroundStyle(.secondary)
        Button("Retry") { Task { await content?.load…(force: true) } }
            .font(.footnote.weight(.semibold))
    }
    .frame(maxWidth: .infinity).padding(.vertical, 24)
}
```
**D. Swap images:** `DownsampledAssetImage(name: X)` → `RemoteImage(X, …)` in that section's card component.
**E. Delete the section's sample data** (see each task).

---

### Task 8: Home · Popular Destinations

**Files:** Modify `Places/Views/Tabs/HomeTab.swift`. Interactive verify on sim.

- [ ] **Step 1:** Add `@Environment(ContentStore.self) private var content: ContentStore?`; on the Home root add `.task { await content?.loadPopularDestinations() }`.
- [ ] **Step 2:** Replace the Popular Destinations section's use of `HomeTab.popularItems` with the Loadable switch (pattern above) over `content?.popularDestinations`. In `.loaded`, `ForEach(dtos) { dto in PlaceCard(...) }` using `RemoteImage(dto.bannerUrl, …)`, title `dto.name`, subtitle `"\(dto.category) · ★ \(dto.rating.map { String(format: "%.1f", $0) } ?? "–")"`; tap → `router.showScreen(.push) { _ in ExploreDetailView(destination: dto) }` (Task 13 adds that init — until then keep the existing `ExploreDetailView(title:imageName:)` call and switch it in Task 13).
- [ ] **Step 3:** Delete the `popularItems` static array.
- [ ] **Step 4: Interactive verify.** Rebuild/run on iPhone 17 Pro (via Argent): Home shows real destination photos + names; kill network → Retry state; (temporarily) point the fetch at an empty filter to confirm the empty state — then revert.
- [ ] **Step 5: Commit.** `git commit -am "feat: wire Popular Destinations to Supabase"`

---

### Task 9: Home · Sponsored

**Files:** Modify `Places/View Models/HomeViewModels/SponsoredViewModel.swift`, `Places/Components/Home/SponsoredCardView.swift` (+ its carousel host). Interactive verify.

- [ ] **Step 1:** Convert `SponsoredViewModel` from `ObservableObject`/`@Published` to `@Observable`. Delete the static `cards` array. Give it `content: ContentProviding` and a `load()` that sets a `Loadable<[Sponsored]>` (map `SponsoredDTO → Sponsored`). Keep the existing `selectedCard`/drag UI state.
- [ ] **Step 2:** Update `HomeTab`'s Sponsored section to `.task { await vm.load() }` and render the `Loadable` switch; keep the morph/`selectedCard` interaction.
- [ ] **Step 3:** In `SponsoredCardView`, swap the background `DownsampledAssetImage(name: card.image)` → `RemoteImage(card.image, …)`.
- [ ] **Step 4: Interactive verify** on sim: real sponsor images/titles; morph-to-detail still works; empty/retry states behave.
- [ ] **Step 5: Commit.** `git commit -am "feat: wire Sponsored to Supabase"`

---

### Task 10: Home · Experience categories

**Files:** Modify `Places/Views/Tabs/HomeTab.swift`, `Places/Components/Explore/ExperienceCategoryCard.swift`; delete `ExperienceCategory.all`. Interactive verify.

- [ ] **Step 1:** `.task { await content?.loadCategories() }`; render the Loadable switch over `content?.categories`; `.loaded` → `ForEach(dtos) { dto in ExperienceCategoryCard(category: ExperienceCategory(dto: dto)) }`.
- [ ] **Step 2:** In `ExperienceCategoryCard`, swap `DownsampledAssetImage(name: category.imageName)` → `RemoteImage(category.imageName, …)`.
- [ ] **Step 3:** Delete `ExperienceCategory.all`.
- [ ] **Step 4: Interactive verify** on sim: 8 category tiles with real images; tapping opens the category list (Task 12).
- [ ] **Step 5: Commit.** `git commit -am "feat: wire experience categories to Supabase"`

---

### Task 11: Home · Popular experiences in [city]

**Files:** Modify `Places/Views/Tabs/HomeTab.swift`, `Places/Components/Explore/ExperienceCard.swift`; delete `Experience.samples*`. Interactive verify.

- [ ] **Step 1:** For the current city (default `EACity.nairobi`), `.task { await content?.loadExperiences(cityId: city.rawValue) }`; render the Loadable switch over `content?.experiencesByCity[city.rawValue]`; `.loaded` → `ForEach(dtos) { dto in <hero>(experience: Experience(dto: dto)) }`.
- [ ] **Step 2:** In `ExperienceCard`/`ExperienceHero`, swap `DownsampledAssetImage(name: experience.coverImage)` → `RemoteImage(experience.coverImage, …)`.
- [ ] **Step 3:** Delete `Experience.samples`, `samples(in:)`, `samples(tag:city:)`. Fix any preview that referenced them with a tiny inline `Experience` fixture.
- [ ] **Step 4: Interactive verify** on sim: real experiences for Nairobi; hero morph → detail shows real host/price; empty state for a city with none.
- [ ] **Step 5: Commit.** `git commit -am "feat: wire popular experiences to Supabase"`

---

### Task 12: Explore · category list

**Files:** Modify `Places/Views/Explore/ExperienceCategoryListView.swift`. Interactive verify.

- [ ] **Step 1:** Read `@Environment(ContentStore.self)`. On appear, `.task { await content?.loadExperiences(cityId: city.rawValue, categoryTag: category.tag) }` (the view already receives `category` + `city`). Render the Loadable switch over `content?.experiencesByCategory["\(city.rawValue)|\(category.tag)"]`; map DTO→`Experience` per row; images via `RemoteImage`.
- [ ] **Step 2:** Remove any remaining `Experience.samples(tag:city:)` usage here.
- [ ] **Step 3: Interactive verify** on sim: open a category from Home → real filtered experiences; empty category → empty state.
- [ ] **Step 4: Commit.** `git commit -am "feat: wire category list to Supabase"`

---

### Task 13: Upgrade `ExploreDetailView` to real destinations

**Files:** Modify `Places/Views/Explore/ExploreDetailView.swift`, and the Popular Destinations tap in `HomeTab.swift`. Interactive verify.

- [ ] **Step 1:** Add `init(destination: DestinationDTO)` storing the DTO; render `bannerUrl` via `RemoteImage`, `name`, `description`, `feeLabel`, and `interestTags` as the tag cloud. Remove the `Destination.samples.first` fallback used by the description/tags. Keep the existing `init(title:imageName:)` only if not-yet-wired sections still call it (For You / Recommendations / Curated / Upcoming) — leave those pushing the old init.
- [ ] **Step 2:** Update Task 8's Popular Destinations tap to `ExploreDetailView(destination: dto)`.
- [ ] **Step 3: Interactive verify** on sim: tap a Popular Destination → detail shows the real description/fee/tags, not the Mara sample.
- [ ] **Step 4: Commit.** `git commit -am "feat: ExploreDetailView renders real destination"`

---

## Deferred (out of scope)
For You, profile photo picker, Recommendations/Curated/Upcoming backing, itinerary grounding, disk/offline cache, city picker.
