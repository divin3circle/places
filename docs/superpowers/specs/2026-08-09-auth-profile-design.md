# Auth + Profile Phase — Design Spec

**Date:** 2026-08-09
**App:** Places (iOS 26.5, SwiftUI, Swift 6, `-default-isolation=MainActor`), bundle `com.sylusabel.Places`
**Supabase project:** `bwafaffjhaxclcmrjhdg`

## Goal
Add real Sign in with Apple → Supabase Auth, a persisted session, a backend-backed user `Profile`, and persistence of onboarding interests — gating the app behind sign-in. Runs **before** the Phase 2 content-fetch wiring, and installs the `supabase-swift` client both phases share.

## Architecture (2–3 sentences)
A single `@Observable @MainActor SessionStore` is the source of truth for auth state + current profile, injected via `.environment`. It wraps a thin `AuthProviding` protocol over `supabase-swift` (so state transitions are unit-testable with a fake). The root view switches on `SessionStore.phase`; onboarding writes interests + completion back to the `profiles` row.

## Tech stack
`supabase-swift` (Auth + PostgREST + Storage), `AuthenticationServices` (`SignInWithAppleButton`), `CryptoKit` (nonce SHA-256), SwiftfulRouting (existing), SwiftData (existing, unrelated).

## Global constraints
- iOS 26.5, Swift 6, `@MainActor` default isolation. Views/VMs use the `@Observable` macro (not `ObservableObject`).
- The anon key is client-public (already in `SupabaseConfig`); **no service-role key in the app, ever**.
- Match existing patterns: `Services/` for clients, `View Models/` for `@Observable` VMs, `Models/` for Codable models.
- Sign-in is **required** (hard gate) for v1.

## Locked decisions
1. **Auth stack:** official `supabase-swift` SDK (handles Apple id-token exchange, Keychain session persistence, auto-refresh; reused by Phase 2 + avatar upload).
2. **Gating:** require sign-in. Launch → Sign in with Apple → onboarding (interests) → app.
3. **Profile photo:** fast-follow (not this phase). Profile row created with null `avatar_url`; UI shows initials.
4. **Interests:** realign the onboarding taxonomy onto the 8 `experience_categories` tags now.

## Components

### 1. `SupabaseService` (Services/SupabaseService.swift)
Single configured client: `SupabaseClient(supabaseURL: SupabaseConfig.projectURL, supabaseKey: SupabaseConfig.anonKey)`. Add `projectURL = https://bwafaffjhaxclcmrjhdg.supabase.co` to `SupabaseConfig`. Exposes `.auth`, `.from(_:)`, `.storage`. The existing raw-URLSession itinerary client is left untouched.

### 2. `Profile` model (Models/Profile/Profile.swift)
`Codable`, snake_case-mapped to `profiles`:
`id: UUID, name: String?, email: String?, avatarURL: String?, interests: [String], plan: String, onboardingComplete: Bool`.
Replaces the hardcoded `UserProfile.current`. (`UserPlan` enum retained for UI tint, derived from `plan` string.)

### 3. `AuthProviding` protocol + `SupabaseAuthProvider`
Thin seam over `supabase-swift` auth for testability:
```
protocol AuthProviding {
    var currentUserID: UUID? { get }
    func restoreSession() async throws -> Bool          // Keychain, offline-capable
    func signInWithApple(idToken: String, rawNonce: String) async throws -> UUID
    func signOut() async throws
}
```
Production impl calls `auth.signInWithIdToken(credentials: OpenIDConnectCredentials(provider: .apple, idToken:, nonce: rawNonce))`.

### 4. `ProfileRepository` (Services/ProfileRepository.swift)
`fetch(id:) -> Profile`, `updateName(_:)`, `updateInterests([String])`, `markOnboardingComplete()` via PostgREST (`client.from("profiles")`). Owner-gated by RLS (`auth.uid() = id`).

### 5. `SessionStore` (View Models/SessionStore.swift)
`@Observable @MainActor`. Holds `phase` + `currentProfile`.
```
enum Phase { case booting, signedOut, onboarding, ready }
```
- `bootstrap()` — restore session; if signed in, fetch profile; set phase from `onboardingComplete` (with `@AppStorage` mirror fallback offline).
- `signIn(idToken:rawNonce:appleFullName:)` — exchange, fetch profile, patch name from Apple credential on first sign-in, set phase.
- `saveInterests(_:)`, `completeOnboarding()`, `signOut()`.
Injected once at the app root via `.environment`.

### 6. Apple sign-in (Views/Onboarding/Auth.swift + AppleSignIn helper)
Replace the mock button with `SignInWithAppleButton`:
- **onRequest:** generate random nonce (`SecRandomCopyBytes`), `request.requestedScopes = [.fullName, .email]`, `request.nonce = sha256(rawNonce)`.
- **onCompletion:** extract `ASAuthorizationAppleIDCredential.identityToken` → UTF-8 String; call `SessionStore.signIn(idToken:, rawNonce:, appleFullName: credential.fullName)`.
- Nonce helpers (`randomNonceString`, `sha256`) in an `AppleSignIn` utility; **raw** nonce → Supabase, **hashed** nonce → Apple. On cancel/failure show inline error and stay `signedOut`.

### 7. Root gating (App/PlacesApp.swift + ContentView)
`ContentView` switches on `SessionStore.phase`: `booting`→Splash, `signedOut`→`Auth`, `onboarding`→onboarding flow, `ready`→`AppTab`. Finishing `FourthOnboarding` calls `completeOnboarding()` (sets `profiles.onboarding_complete = true` + local mirror) before entering `AppTab`.

### 8. Interests realignment (Models/Onboarding/TravelInterest.swift + SecondOnboarding)
Re-tag chips so each maps to exactly one of the 8 category tags, all 8 represented (adds Coffee, Adventure, Nightlife chips):

| Category tag | Chips |
|---|---|
| wildlife_safaris | Safari, Wildlife, Camera |
| nature_hiking | Hiking, Nature, Trekking |
| cultural_heritage | History, Wander |
| food_coffee_tours | Cuisine, Coffee |
| arts_crafts | Culture (→Arts) |
| adventure_sports | Camping, Adventure |
| wellness_relaxation | Beaches, Sunset, Lodges |
| nightlife_music | Nightlife |

`SecondOnboarding` Continue → `saveInterests(Set<categoryTag>)` (deduped) → `profiles.interests`.

### 9. Profile screen + logout
Swap `UserProfile.current` for `SessionStore.currentProfile` in `ProfileHeader`/`ProfileSettingsList` (initials avatar for now). Wire the stubbed Logout closure → `SessionStore.signOut()` → returns to `Auth`.

## Data model / DB
- Migration: `alter table public.profiles add column if not exists onboarding_complete boolean not null default false;`
- `profiles.interests text[]` now stores category tags. `handle_new_user` trigger already inserts the row on first sign-in.

## Session lifecycle
supabase-swift persists the session in Keychain and auto-refreshes. `bootstrap()` restores at launch (works offline from Keychain). Optional (noted, not required): observe `auth.authStateChanges` to react to token refresh/expiry.

## Error handling
- Sign-in cancel/fail → inline error on `Auth`, remain `signedOut`.
- Offline launch with saved session → restore locally + use `@AppStorage` onboarding mirror + last-known profile; refresh in background.
- Online profile fetch failure with valid session → retry splash (don't drop the session).

## Testing
- Unit: `randomNonceString` length/charset, `sha256` correctness, chip→tag mapping (all 8 covered, dedupe), `SessionStore` phase transitions via fake `AuthProviding` + fake `ProfileRepository`.
- Manual (sim): sign in with simulator Apple ID → `profiles` row exists with name/email → pick interests → relaunch skips onboarding → logout returns to `Auth`.

## Prerequisites / risks (external, user-owned)
1. **Sign in with Apple capability** on `com.sylusabel.Places` (Xcode Signing & Capabilities + Apple Developer App ID). Without it, native sign-in fails. Fallback if unavailable: keep the exchange code but stub the button; wire the real capability when ready.
2. **Supabase dashboard:** enable the **Apple** auth provider and add bundle id `com.sylusabel.Places` to the allowed client IDs. Not doable via MCP — manual dashboard step (values provided).

## Scope
**In:** `supabase-swift` install + `SupabaseService`, `Profile` + `AuthProviding` + `ProfileRepository`, `SessionStore`, real Apple sign-in, root gating, interests persist + taxonomy realign, profile-screen wiring, logout, `onboarding_complete` migration.
**Out (fast-follow / later phases):** avatar photo picker + upload, For You personalization, passing the user JWT to the itinerary Edge Function, Phase 2 content fetch/wiring.
