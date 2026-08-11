# Auth + Profile Phase Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add real Sign in with Apple → Supabase Auth, a persisted session, a backend-backed `Profile`, and onboarding-interest persistence — gating the app behind sign-in.

**Architecture:** A single `@Observable @MainActor SessionStore` is the source of truth for auth phase + current profile, injected via `.environment`. It depends on two protocol seams — `AuthProviding` (Apple id-token exchange, session restore, sign-out) and `ProfileProviding` (PostgREST profile CRUD) — whose production impls wrap one shared `supabase-swift` client, and whose fakes make `SessionStore` fully unit-testable. The root view switches on `SessionStore.phase`.

**Tech Stack:** `supabase-swift` (Auth + PostgREST + Storage), `AuthenticationServices` (`SignInWithAppleButton`), `CryptoKit` (nonce SHA-256), Swift Testing (`import Testing`), SwiftfulRouting (existing).

## Global Constraints
- iOS 26.5, Swift 6, `-default-isolation=MainActor`. Use the `@Observable` macro, NOT `ObservableObject`.
- Anon key is client-public (in `SupabaseConfig`). NEVER put the service-role key in the app.
- Bundle id `com.sylusabel.Places`. Supabase project `bwafaffjhaxclcmrjhdg`, URL `https://bwafaffjhaxclcmrjhdg.supabase.co`.
- Sign-in is REQUIRED (hard gate) for v1. Profile photo is out of scope (fast-follow).
- Follow existing layout: clients in `Places/Services/`, VMs in `Places/View Models/`, models in `Places/Models/`.
- Simulator for all manual verification: **iPhone 17 Pro** (project preference). Test/verify command base:
  `xcodebuild test -scheme Places -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`

## File Structure
**Create:**
- `Places/Services/SupabaseService.swift` — shared `SupabaseClient`.
- `Places/Utilities/AppleSignIn.swift` — nonce + SHA-256 helpers.
- `Places/Models/Profile/Profile.swift` — Codable profile model.
- `Places/Services/AuthProviding.swift` — `AuthProviding` protocol + `SupabaseAuthProvider`.
- `Places/Services/ProfileRepository.swift` — `ProfileProviding` protocol + `ProfileRepository`.
- `Places/View Models/SessionStore.swift` — `@Observable` session state machine.
- `Places/Views/Onboarding/SplashView.swift` — booting placeholder.
- `PlacesTests/AppleSignInTests.swift`, `InterestMappingTests.swift`, `ProfileDecodingTests.swift`, `SessionStoreTests.swift`, plus `Fakes/FakeAuthProviding.swift`, `Fakes/FakeProfileProviding.swift`.

**Modify:**
- `Places/Services/SupabaseConfig.swift` — add `projectURL`.
- `Places/Models/Onboarding/TravelInterest.swift` — realign `category` → the 8 tags, add chips, add mapping helper.
- `Places/App/PlacesApp.swift` + its `ContentView` — inject `SessionStore`, root-gate on `phase`.
- `Places/Views/Onboarding/Auth.swift` — real `SignInWithAppleButton`.
- `Places/Views/Onboarding/SecondOnboarding.swift` — persist interests.
- `Places/Views/Onboarding/FourthOnboarding.swift` — `completeOnboarding()`.
- `Places/Components/ProfileHeader.swift` + `Places/Components/ProfileSettingsList.swift` — real profile + logout.
- Supabase: `profiles` migration; Apple provider enabled (dashboard).

---

### Task 1: Project & backend setup (manual Xcode + Supabase)

These are environment actions (no unit test); the deliverable is "project builds with the new dependency, test target, and capability; backend ready."

**Files:** `Places.xcodeproj` (via Xcode UI), `Places/Places.entitlements` (created by capability).

- [ ] **Step 1: Add the supabase-swift package.** In Xcode: File → Add Package Dependencies → `https://github.com/supabase/supabase-swift` → Up to Next Major → add the **`Supabase`** product to the `Places` target.
- [ ] **Step 2: Add a unit test target.** File → New → Target → **Unit Testing Bundle** → name `PlacesTests`, Testing System = **Swift Testing**, Target to be Tested = `Places`. This creates the `PlacesTests` group and adds a test action to the `Places` scheme.
- [ ] **Step 3: Add the Sign in with Apple capability.** Select the `Places` target → Signing & Capabilities → + Capability → **Sign in with Apple**. Confirm `Places/Places.entitlements` now contains `com.apple.developer.applesignin = ["Default"]` and `CODE_SIGN_ENTITLEMENTS` points at it. (Requires the App ID to have the capability enabled in the Apple Developer portal.)
- [ ] **Step 4: Enable Apple provider in Supabase.** Dashboard → Authentication → Providers → Apple → Enable. Under **Client IDs**, add `com.sylusabel.Places`. Save. (No secret needed for native id-token sign-in when the bundle id is in the allowlist.)
- [ ] **Step 5: Run the profiles migration.** Apply:
```sql
alter table public.profiles
  add column if not exists onboarding_complete boolean not null default false;
```
- [ ] **Step 6: Verify the empty test target runs.** Add a temporary `PlacesTests/SmokeTest.swift`:
```swift
import Testing
@testable import Places

@Test func smoke() { #expect(true) }
```
Run: `xcodebuild test -scheme Places -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:PlacesTests/smoke`
Expected: PASS. Then delete `SmokeTest.swift`.
- [ ] **Step 7: Commit.** `git add -A && git commit -m "chore: add supabase-swift, unit test target, Sign in with Apple capability"`

---

### Task 2: Shared Supabase client

**Files:**
- Modify: `Places/Services/SupabaseConfig.swift`
- Create: `Places/Services/SupabaseService.swift`

**Interfaces:**
- Produces: `SupabaseConfig.projectURL: URL`; `SupabaseService.client: SupabaseClient`.

- [ ] **Step 1: Add the project URL.** In `SupabaseConfig.swift`, add:
```swift
static let projectURL = URL(string: "https://bwafaffjhaxclcmrjhdg.supabase.co")!
```
- [ ] **Step 2: Create the client.**
```swift
import Foundation
import Supabase

/// The single app-wide Supabase client. Auth persists the session in the
/// Keychain and auto-refreshes tokens. Reused by auth, profile, and Phase 2.
enum SupabaseService {
    static let client = SupabaseClient(
        supabaseURL: SupabaseConfig.projectURL,
        supabaseKey: SupabaseConfig.anonKey
    )
}
```
- [ ] **Step 3: Verify it builds.** Run: `xcodebuild build -scheme Places -destination 'platform=iOS Simulator,name=iPhone 17 Pro'` → Expected: BUILD SUCCEEDED.
- [ ] **Step 4: Commit.** `git commit -am "feat: add shared SupabaseService client"`

---

### Task 3: Apple nonce helpers (TDD)

**Files:**
- Create: `Places/Utilities/AppleSignIn.swift`
- Test: `PlacesTests/AppleSignInTests.swift`

**Interfaces:**
- Produces: `AppleSignIn.randomNonceString(length:) -> String`, `AppleSignIn.sha256(_:) -> String`.

- [ ] **Step 1: Write the failing tests.**
```swift
import Testing
@testable import Places

struct AppleSignInTests {
    @Test func nonceHasRequestedLength() {
        #expect(AppleSignIn.randomNonceString(length: 32).count == 32)
    }
    @Test func noncesAreUnique() {
        #expect(AppleSignIn.randomNonceString() != AppleSignIn.randomNonceString())
    }
    @Test func sha256MatchesKnownVector() {
        // SHA-256("abc") canonical test vector.
        #expect(AppleSignIn.sha256("abc") ==
          "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    }
}
```
- [ ] **Step 2: Run — expect fail** (`AppleSignIn` undefined).
  `xcodebuild test -scheme Places -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:PlacesTests/AppleSignInTests`
- [ ] **Step 3: Implement.**
```swift
import CryptoKit
import Foundation

/// Nonce utilities for Sign in with Apple. The SHA-256 hash goes to Apple's
/// authorization request; the RAW nonce goes to Supabase, which cross-checks them.
enum AppleSignIn {
    static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        while remaining > 0 {
            var randoms = [UInt8](repeating: 0, count: 16)
            let status = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
            precondition(status == errSecSuccess, "SecRandomCopyBytes failed: \(status)")
            for random in randoms where remaining > 0 && random < charset.count {
                result.append(charset[Int(random)])
                remaining -= 1
            }
        }
        return result
    }

    static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }
}
```
- [ ] **Step 4: Run — expect pass.**
- [ ] **Step 5: Commit.** `git commit -am "feat: Apple sign-in nonce + SHA-256 helpers"`

---

### Task 4: Interests taxonomy realign (TDD)

**Files:**
- Modify: `Places/Models/Onboarding/TravelInterest.swift`
- Test: `PlacesTests/InterestMappingTests.swift`

**Interfaces:**
- Produces: `TravelInterest.categoryTag: String`; dataset `EastAfricaInterestsDataset: [TravelInterest]`; free function `categoryTags(for selected: Set<TravelInterest>) -> [String]` (sorted, deduped).
- Consumes: the 8 tags `wildlife_safaris, nature_hiking, cultural_heritage, food_coffee_tours, arts_crafts, adventure_sports, wellness_relaxation, nightlife_music`.

- [ ] **Step 1: Write the failing tests.**
```swift
import Testing
@testable import Places

struct InterestMappingTests {
    let all = ["wildlife_safaris","nature_hiking","cultural_heritage","food_coffee_tours",
               "arts_crafts","adventure_sports","wellness_relaxation","nightlife_music"]

    @Test func everyChipTagIsAValidCategory() {
        for interest in EastAfricaInterestsDataset {
            #expect(all.contains(interest.categoryTag))
        }
    }
    @Test func datasetCoversAllEightCategories() {
        let covered = Set(EastAfricaInterestsDataset.map(\.categoryTag))
        #expect(covered == Set(all))
    }
    @Test func selectionDedupesToTags() {
        let safari = EastAfricaInterestsDataset.first { $0.categoryTag == "wildlife_safaris" }!
        let wildlife = EastAfricaInterestsDataset.last { $0.categoryTag == "wildlife_safaris" }!
        let tags = categoryTags(for: [safari, wildlife])
        #expect(tags == ["wildlife_safaris"])
    }
}
```
- [ ] **Step 2: Run — expect fail.**
- [ ] **Step 3: Implement.** Rename the struct field `category` → `categoryTag`; set each dataset entry's tag per the mapping (Safari/Wildlife/Camera→`wildlife_safaris`; Hiking/Nature/Trekking→`nature_hiking`; History/Wander→`cultural_heritage`; Cuisine/Coffee→`food_coffee_tours`; Culture→`arts_crafts`; Camping/Adventure→`adventure_sports`; Beaches/Sunset/Lodges→`wellness_relaxation`; Nightlife→`nightlife_music`). Add the new chips (Coffee `cup.and.saucer`, Adventure `figure.climbing`, Nightlife `music.note`). Add:
```swift
/// Deduped, sorted category tags for a set of selected interest chips.
func categoryTags(for selected: Set<TravelInterest>) -> [String] {
    Array(Set(selected.map(\.categoryTag))).sorted()
}
```
- [ ] **Step 4: Run — expect pass.**
- [ ] **Step 5: Commit.** `git commit -am "feat: realign onboarding interests to the 8 experience categories"`

---

### Task 5: Profile model (TDD)

**Files:**
- Create: `Places/Models/Profile/Profile.swift`
- Test: `PlacesTests/ProfileDecodingTests.swift`

**Interfaces:**
- Produces: `struct Profile: Codable, Identifiable` with `id: UUID, name: String?, email: String?, avatarURL: String?, interests: [String], plan: String, onboardingComplete: Bool`.

- [ ] **Step 1: Write the failing test** (snake_case JSON from PostgREST decodes):
```swift
import Testing
import Foundation
@testable import Places

struct ProfileDecodingTests {
    @Test func decodesSnakeCaseRow() throws {
        let json = """
        {"id":"3f1c...-uuid","name":"Ada","email":"a@b.com","avatar_url":null,
         "interests":["wildlife_safaris"],"plan":"free","onboarding_complete":true}
        """.replacingOccurrences(of: "3f1c...-uuid", with: UUID().uuidString)
        let p = try JSONDecoder().decode(Profile.self, from: Data(json.utf8))
        #expect(p.plan == "free")
        #expect(p.onboardingComplete == true)
        #expect(p.interests == ["wildlife_safaris"])
        #expect(p.avatarURL == nil)
    }
}
```
- [ ] **Step 2: Run — expect fail.**
- [ ] **Step 3: Implement.**
```swift
import Foundation

struct Profile: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String?
    var email: String?
    var avatarURL: String?
    var interests: [String]
    var plan: String
    var onboardingComplete: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, email, interests, plan
        case avatarURL = "avatar_url"
        case onboardingComplete = "onboarding_complete"
    }
}
```
- [ ] **Step 4: Run — expect pass.**
- [ ] **Step 5: Commit.** `git commit -am "feat: add Codable Profile model"`

---

### Task 6: Auth + profile provider seams

Integration wrappers over `supabase-swift`; verified by build (fakes drive the unit tests in Task 7).

**Files:**
- Create: `Places/Services/AuthProviding.swift`, `Places/Services/ProfileRepository.swift`

**Interfaces:**
- Produces:
  `protocol AuthProviding { var currentUserID: UUID? { get }; func restoreSession() async throws -> Bool; func signInWithApple(idToken: String, rawNonce: String) async throws -> UUID; func signOut() async throws }`
  `protocol ProfileProviding { func fetch(id: UUID) async throws -> Profile; func updateName(_ name: String, id: UUID) async throws; func updateInterests(_ tags: [String], id: UUID) async throws; func markOnboardingComplete(id: UUID) async throws }`
  `struct SupabaseAuthProvider: AuthProviding`, `struct ProfileRepository: ProfileProviding`.

- [ ] **Step 1: AuthProviding + SupabaseAuthProvider.**
```swift
import Foundation
import Supabase

protocol AuthProviding: Sendable {
    var currentUserID: UUID? { get }
    func restoreSession() async throws -> Bool
    func signInWithApple(idToken: String, rawNonce: String) async throws -> UUID
    func signOut() async throws
}

struct SupabaseAuthProvider: AuthProviding {
    private var auth: AuthClient { SupabaseService.client.auth }

    var currentUserID: UUID? { auth.currentUser?.id }

    func restoreSession() async throws -> Bool {
        // Loads a persisted session from the Keychain (offline-capable).
        (try? await auth.session) != nil
    }

    func signInWithApple(idToken: String, rawNonce: String) async throws -> UUID {
        let session = try await auth.signInWithIdToken(
            credentials: OpenIDConnectCredentials(provider: .apple, idToken: idToken, nonce: rawNonce)
        )
        return session.user.id
    }

    func signOut() async throws { try await auth.signOut() }
}
```
- [ ] **Step 2: ProfileProviding + ProfileRepository.**
```swift
import Foundation
import Supabase

protocol ProfileProviding: Sendable {
    func fetch(id: UUID) async throws -> Profile
    func updateName(_ name: String, id: UUID) async throws
    func updateInterests(_ tags: [String], id: UUID) async throws
    func markOnboardingComplete(id: UUID) async throws
}

struct ProfileRepository: ProfileProviding {
    private var table: PostgrestQueryBuilder { SupabaseService.client.from("profiles") }

    func fetch(id: UUID) async throws -> Profile {
        try await table.select().eq("id", value: id).single().execute().value
    }
    func updateName(_ name: String, id: UUID) async throws {
        try await table.update(["name": name]).eq("id", value: id).execute()
    }
    func updateInterests(_ tags: [String], id: UUID) async throws {
        try await table.update(["interests": tags]).eq("id", value: id).execute()
    }
    func markOnboardingComplete(id: UUID) async throws {
        try await table.update(["onboarding_complete": true]).eq("id", value: id).execute()
    }
}
```
- [ ] **Step 3: Verify build.** `xcodebuild build -scheme Places -destination 'platform=iOS Simulator,name=iPhone 17 Pro'` → BUILD SUCCEEDED. (If `PostgrestQueryBuilder`/`AuthClient` type names differ in the installed SDK version, fix to the compiler-reported types — the method calls are stable.)
- [ ] **Step 4: Commit.** `git commit -am "feat: AuthProviding + ProfileProviding Supabase seams"`

---

### Task 7: SessionStore state machine (TDD)

**Files:**
- Create: `Places/View Models/SessionStore.swift`
- Test: `PlacesTests/SessionStoreTests.swift`, `PlacesTests/Fakes/FakeAuthProviding.swift`, `PlacesTests/Fakes/FakeProfileProviding.swift`

**Interfaces:**
- Consumes: `AuthProviding`, `ProfileProviding`, `Profile`.
- Produces: `@Observable @MainActor final class SessionStore` with `phase: Phase`, `currentProfile: Profile?`, and methods `bootstrap()`, `signIn(idToken:rawNonce:appleFullName:)`, `saveInterests(_:)`, `completeOnboarding()`, `signOut()`.

- [ ] **Step 1: Write the fakes.**
```swift
import Foundation
@testable import Places

final class FakeAuthProviding: AuthProviding, @unchecked Sendable {
    var userID: UUID?
    var restore = false
    var signInResultID = UUID()
    var currentUserID: UUID? { userID }
    func restoreSession() async throws -> Bool { if restore { userID = signInResultID }; return restore }
    func signInWithApple(idToken: String, rawNonce: String) async throws -> UUID { userID = signInResultID; return signInResultID }
    func signOut() async throws { userID = nil }
}

final class FakeProfileProviding: ProfileProviding, @unchecked Sendable {
    var stored: Profile
    var shouldThrowOnFetch = false
    init(stored: Profile) { self.stored = stored }
    func fetch(id: UUID) async throws -> Profile {
        if shouldThrowOnFetch { throw URLError(.notConnectedToInternet) }
        return stored
    }
    func updateName(_ name: String, id: UUID) async throws { stored.name = name }
    func updateInterests(_ tags: [String], id: UUID) async throws { stored.interests = tags }
    func markOnboardingComplete(id: UUID) async throws { stored.onboardingComplete = true }
}

extension Profile {
    static func fixture(onboardingComplete: Bool) -> Profile {
        Profile(id: UUID(), name: nil, email: "a@b.com", avatarURL: nil,
                interests: [], plan: "free", onboardingComplete: onboardingComplete)
    }
}
```
- [ ] **Step 2: Write the failing tests.**
```swift
import Testing
import Foundation
@testable import Places

@MainActor
struct SessionStoreTests {
    func makeStore(auth: FakeAuthProviding, profile: Profile, throwFetch: Bool = false) -> (SessionStore, FakeProfileProviding) {
        let repo = FakeProfileProviding(stored: profile); repo.shouldThrowOnFetch = throwFetch
        let defaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        return (SessionStore(auth: auth, profiles: repo, defaults: defaults), repo)
    }

    @Test func bootstrapNoSessionIsSignedOut() async {
        let (store, _) = makeStore(auth: FakeAuthProviding(), profile: .fixture(onboardingComplete: true))
        await store.bootstrap()
        #expect(store.phase == .signedOut)
    }
    @Test func bootstrapRestoredCompleteIsReady() async {
        let auth = FakeAuthProviding(); auth.restore = true
        let (store, _) = makeStore(auth: auth, profile: .fixture(onboardingComplete: true))
        await store.bootstrap()
        #expect(store.phase == .ready)
    }
    @Test func bootstrapRestoredIncompleteIsOnboarding() async {
        let auth = FakeAuthProviding(); auth.restore = true
        let (store, _) = makeStore(auth: auth, profile: .fixture(onboardingComplete: false))
        await store.bootstrap()
        #expect(store.phase == .onboarding)
    }
    @Test func completeOnboardingBecomesReadyAndPersists() async {
        let auth = FakeAuthProviding(); auth.restore = true
        let (store, repo) = makeStore(auth: auth, profile: .fixture(onboardingComplete: false))
        await store.bootstrap()
        await store.completeOnboarding()
        #expect(store.phase == .ready)
        #expect(repo.stored.onboardingComplete == true)
    }
    @Test func signOutReturnsToSignedOut() async {
        let auth = FakeAuthProviding(); auth.restore = true
        let (store, _) = makeStore(auth: auth, profile: .fixture(onboardingComplete: true))
        await store.bootstrap()
        await store.signOut()
        #expect(store.phase == .signedOut)
    }
    @Test func offlineFetchFailFallsBackToMirror() async {
        let auth = FakeAuthProviding(); auth.restore = true
        let (store, _) = makeStore(auth: auth, profile: .fixture(onboardingComplete: true), throwFetch: true)
        await store.bootstrap()  // no mirror set yet → onboarding
        #expect(store.phase == .onboarding)
    }
}
```
- [ ] **Step 3: Run — expect fail.**
- [ ] **Step 4: Implement.**
```swift
import Foundation
import SwiftUI

@Observable @MainActor
final class SessionStore {
    enum Phase: Equatable { case booting, signedOut, onboarding, ready }

    private(set) var phase: Phase = .booting
    private(set) var currentProfile: Profile?

    private let auth: AuthProviding
    private let profiles: ProfileProviding
    private let defaults: UserDefaults
    private let mirrorKey = "onboarding_complete_mirror"

    init(auth: AuthProviding, profiles: ProfileProviding, defaults: UserDefaults = .standard) {
        self.auth = auth; self.profiles = profiles; self.defaults = defaults
    }

    func bootstrap() async {
        do {
            guard try await auth.restoreSession(), let id = auth.currentUserID else {
                phase = .signedOut; return
            }
            await loadProfileAndSetPhase(id: id)
        } catch { phase = .signedOut }
    }

    func signIn(idToken: String, rawNonce: String, appleFullName: PersonNameComponents?) async throws {
        let id = try await auth.signInWithApple(idToken: idToken, rawNonce: rawNonce)
        if let name = appleFullName?.formatted(), !name.isEmpty {
            try? await profiles.updateName(name, id: id)
        }
        await loadProfileAndSetPhase(id: id)
    }

    func saveInterests(_ tags: [String]) async {
        guard let id = auth.currentUserID else { return }
        try? await profiles.updateInterests(tags, id: id)
        currentProfile?.interests = tags
    }

    func completeOnboarding() async {
        guard let id = auth.currentUserID else { return }
        try? await profiles.markOnboardingComplete(id: id)
        defaults.set(true, forKey: mirrorKey)
        currentProfile?.onboardingComplete = true
        phase = .ready
    }

    func signOut() async {
        try? await auth.signOut()
        defaults.set(false, forKey: mirrorKey)
        currentProfile = nil
        phase = .signedOut
    }

    private func loadProfileAndSetPhase(id: UUID) async {
        do {
            let p = try await profiles.fetch(id: id)
            currentProfile = p
            defaults.set(p.onboardingComplete, forKey: mirrorKey)
            phase = p.onboardingComplete ? .ready : .onboarding
        } catch {
            // Offline / fetch failure with a valid session: fall back to the local mirror.
            phase = defaults.bool(forKey: mirrorKey) ? .ready : .onboarding
        }
    }
}
```
- [ ] **Step 5: Run — expect pass.**
- [ ] **Step 6: Commit.** `git commit -am "feat: SessionStore auth/profile state machine"`

---

### Task 8: Real Sign in with Apple in Auth.swift

**Files:** Modify `Places/Views/Onboarding/Auth.swift`

**Interfaces:** Consumes `SessionStore` (from `.environment`), `AppleSignIn`.

- [ ] **Step 1: Replace the mock button.** Read the environment store (`@Environment(SessionStore.self) private var session`) and a local `@State private var currentNonce: String?` + `@State private var errorMessage: String?`. Swap the mock `Button` for:
```swift
SignInWithAppleButton(.continue) { request in
    let nonce = AppleSignIn.randomNonceString()
    currentNonce = nonce
    request.requestedScopes = [.fullName, .email]
    request.nonce = AppleSignIn.sha256(nonce)   // hashed → Apple
} onCompletion: { result in
    switch result {
    case .success(let auth):
        guard
            let cred = auth.credential as? ASAuthorizationAppleIDCredential,
            let tokenData = cred.identityToken,
            let idToken = String(data: tokenData, encoding: .utf8),
            let rawNonce = currentNonce
        else { errorMessage = "Could not read Apple credentials."; return }
        Task {
            do { try await session.signIn(idToken: idToken, rawNonce: rawNonce, appleFullName: cred.fullName) }
            catch { errorMessage = "Sign in failed. Please try again." }
        }
    case .failure(let error):
        if (error as? ASAuthorizationError)?.code != .canceled {
            errorMessage = "Sign in failed. Please try again."
        }
    }
}
.signInWithAppleButtonStyle(.black)
.frame(height: 50)
```
Add `import AuthenticationServices`. Show `errorMessage` inline below the button when non-nil. Delete the old push-to-`FirstOnboarding` navigation (root gating now drives it).
- [ ] **Step 2: Manual verify on simulator.** Build & run via argent on iPhone 17 Pro (ensure a simulator Apple ID is signed in: Settings → Sign in). Tap "Continue with Apple", complete the sheet. Then check the DB: `select id, email, onboarding_complete from public.profiles;` → a row exists for the new user.
- [ ] **Step 3: Commit.** `git commit -am "feat: real Sign in with Apple wired to SessionStore"`

---

### Task 9: Root gating on session phase

**Files:** Modify `Places/App/PlacesApp.swift` (and its `ContentView`); Create `Places/Views/Onboarding/SplashView.swift`

**Interfaces:** Consumes `SessionStore.phase`.

- [ ] **Step 1: Create SplashView** — the app's launch/booting screen (reuse existing brand mark or a simple `ProgressView()` centered).
- [ ] **Step 2: Inject the store + gate.** In `PlacesApp`, construct the store once and inject it; drive `bootstrap()` on appear:
```swift
@State private var session = SessionStore(auth: SupabaseAuthProvider(), profiles: ProfileRepository())
// ...
RouterView { _ in ContentView() }
    .environment(session)
    .task { await session.bootstrap() }
```
In `ContentView`:
```swift
@Environment(SessionStore.self) private var session
var body: some View {
    switch session.phase {
    case .booting:   SplashView()
    case .signedOut: Auth()
    case .onboarding: FirstOnboarding { /* existing onboarding chain */ }
    case .ready:     AppTab()
    }
}
```
(Keep the existing onboarding chain `FirstOnboarding → SecondOnboarding → ThirdOnboarding → FourthOnboarding`; the `.onboarding` phase enters it, and Task 10's `completeOnboarding()` flips to `.ready`.)
- [ ] **Step 3: Manual verify.** Fresh launch (signed out) shows `Auth`; after sign-in it advances into onboarding; force-quit + relaunch of a completed user lands directly on `AppTab`.
- [ ] **Step 4: Commit.** `git commit -am "feat: root gating on SessionStore phase"`

---

### Task 10: Persist interests + complete onboarding

**Files:** Modify `Places/Views/Onboarding/SecondOnboarding.swift`, `Places/Views/Onboarding/FourthOnboarding.swift`

**Interfaces:** Consumes `SessionStore`, `categoryTags(for:)`.

- [ ] **Step 1: Save interests.** In `SecondOnboarding`, read `@Environment(SessionStore.self) private var session`. On "Continue", before navigating:
```swift
Task { await session.saveInterests(categoryTags(for: selectedInterests)) }
```
- [ ] **Step 2: Complete onboarding.** In `FourthOnboarding`, on the terminal action ("Start Tour" / "Ask me Later"), replace the direct nav to `AppTab()` with:
```swift
Task { await session.completeOnboarding() }   // flips phase → .ready; root gating shows AppTab
```
- [ ] **Step 3: Manual verify.** Complete the full flow with 2–3 interests → `select interests, onboarding_complete from public.profiles where id = '<uid>';` shows the deduped tags + `true`. Relaunch → lands on `AppTab` (skips onboarding).
- [ ] **Step 4: Commit.** `git commit -am "feat: persist onboarding interests + completion to profile"`

---

### Task 11: Profile screen wiring + logout

**Files:** Modify `Places/Components/ProfileHeader.swift`, `Places/Components/ProfileSettingsList.swift`

**Interfaces:** Consumes `SessionStore.currentProfile`, `SessionStore.signOut()`.

- [ ] **Step 1: Use the real profile.** Replace `UserProfile.current` reads with `session.currentProfile` (`@Environment(SessionStore.self) private var session`). Map: `name` → `profile.name ?? "Traveler"`, `email` → `profile.email ?? ""`, plan tint from `profile.plan`. Avatar: initials from name (photo is the fast-follow).
- [ ] **Step 2: Wire logout.** Replace the stubbed `onTap: {}` on the Logout button with `onTap: { Task { await session.signOut() } }`.
- [ ] **Step 3: Manual verify.** Profile tab shows the signed-in user's name/email; tapping Logout returns to `Auth`; signing back in restores the profile.
- [ ] **Step 4: Commit.** `git commit -am "feat: wire real profile into Profile screen + logout"`

---

## Deferred (explicitly out of scope)
Avatar photo picker + `avatars` bucket upload; For You personalization from `profiles.interests`; passing the user JWT to the `generate-itinerary` Edge Function; Phase 2 content fetch/wiring.
