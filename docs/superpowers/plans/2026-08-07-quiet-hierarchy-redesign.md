# Quiet Hierarchy Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reduce visual noise on the Home, Explore, and Profile screens by restricting the coral accent to CTA/active states, cutting decorative entrance motion, and simplifying the Popular Destinations carousel — so content and photography lead.

**Architecture:** A tiny shared motion primitive (`.pressable()`) is added first, then each screen's components are swept to the accent rule and the entrance stagger is removed. Changes are per-file and additive; no data or navigation changes. Verification is *build succeeds* + *Argent screenshot on the iPhone 17 Pro simulator*, since this is visual work with no unit-testable logic.

**Tech Stack:** SwiftUI, Xcode 16 (file-system synchronized groups — new files in the folder tree are picked up without editing `project.pbxproj`), Argent MCP for on-simulator screenshot verification.

## Global Constraints

- **Accent (`#FD5E53`) is permitted ONLY on:** the primary CTA fill, the active tab icon, and the selected/active state. Every other accent/tint usage on the three screens resolves to a neutral (`Color.primary` / `Color.secondary` / `Color(.systemGray5/6)`).
- **Do not desaturate or scrim photos** beyond what already exists — neutral chrome does the work.
- **Motion budget per screen:** keep navigating transitions (`DestinationTransition` hero, Sponsored `matchedGeometryEffect`), remove entrance stagger (`microAnimations`), add only `.pressable()` micro-feedback.
- **Out of scope:** `GravityContainer`/onboarding, `RecommendationCard`'s fanned stack, backend, and deleting `MicroAnimations.swift` (leave the unused file in place).
- **Simulator:** iPhone 17 Pro. Onboarding resets every launch — walk auth → interest chips → home before reaching the screens under test.
- **Build command:** `xcodebuild -scheme Places -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`
- **Already compliant (do not touch):** `CustomTabBar` (active icon accent + create CTA only) and `FilterPill` (neutral `systemGray6` unselected, accent only when selected).

---

### Task 1: `.pressable()` micro-feedback modifier

**Files:**
- Create: `Places/Components/Pressable.swift`

**Interfaces:**
- Produces: `extension View { func pressable() -> some View }` — a scale-down-on-press modifier applied to tappable cards/buttons in later tasks.

- [ ] **Step 1: Create the modifier**

```swift
//
//  Pressable.swift
//  Places
//
//  Shared tap micro-feedback: a subtle scale-down while pressed. The single
//  sanctioned "micro" interaction under the Quiet Hierarchy motion budget.
//

import SwiftUI

private struct PressableModifier: ViewModifier {
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: isPressed)
            .onLongPressGesture(
                minimumDuration: 0,
                maximumDistance: .infinity,
                pressing: { isPressed = $0 },
                perform: {}
            )
    }
}

extension View {
    /// Subtle scale-down while pressed (~0.97, 0.12s). Use on tappable cards.
    func pressable() -> some View {
        modifier(PressableModifier())
    }
}
```

- [ ] **Step 2: Build to verify it compiles and is picked up by the synchronized group**

Run: `xcodebuild -scheme Places -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`
Expected: BUILD SUCCEEDED. (If it fails with "cannot find 'pressable'", the file was not added to the target — add it to `project.pbxproj` under the Places group.)

- [ ] **Step 3: Commit**

```bash
git add Places/Components/Pressable.swift
git commit -m "feat: add .pressable() micro-feedback modifier"
```

---

### Task 2: Remove entrance stagger on Explore

**Files:**
- Modify: `Places/Views/Explore/ExploreTab.swift:29,33,35,39`

- [ ] **Step 1: Delete the four `.microAnimations(...)` modifiers**

Remove these lines so the sections appear immediately (no slide/offset/stagger):
- `.microAnimations(delay: 0.05, slideDirection: .Top, offsetAmount: 20)` (after `ExploreHero(...)`, line 29)
- `.microAnimations(delay: 0.15, slideDirection: .Bottom, offsetAmount: 20)` (after `upcomingSection`, line 33)
- `.microAnimations(delay: 0.25, slideDirection: .Bottom, offsetAmount: 20)` (after `recommendationsSection`, line 36)
- `.microAnimations(delay: 0.35, slideDirection: .Bottom, offsetAmount: 20)` (after `curatedSection`, line 39)

Leave the views themselves and all layout intact.

- [ ] **Step 2: Build**

Run: `xcodebuild -scheme Places -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`
Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
git add Places/Views/Explore/ExploreTab.swift
git commit -m "refactor: remove entrance stagger from Explore sections"
```

---

### Task 3: Neutralize Explore info badges

**Files:**
- Modify: `Places/Components/Explore/CountdownBadge.swift:25,33`
- Modify: `Places/Components/Explore/UpcomingTripCard.swift:52,55`

**Rationale:** These accent-tinted pills are chrome, not CTAs or active states. `CountdownBadge`'s day count is informational; `UpcomingTripCard`'s "Trip detail" is a secondary action (the card itself is the primary tap).

- [ ] **Step 1: Neutralize `CountdownBadge`**

`CountdownBadge.swift:25` — change the day count foreground from accent to primary:
```swift
Text("\(days)")
    .foregroundStyle(.primary)
```
`CountdownBadge.swift:33` — change the pill background from accent tint to neutral:
```swift
.background(Color(.systemGray6), in: .capsule)
```

- [ ] **Step 2: Neutralize `UpcomingTripCard` "Trip detail" button**

`UpcomingTripCard.swift:52` — foreground accent → primary:
```swift
.foregroundStyle(.primary)
```
`UpcomingTripCard.swift:55` — background accent tint → neutral (this sits on a `secondarySystemBackground` card, so use a slightly stronger neutral for contrast):
```swift
.background(Color(.systemGray5), in: .capsule)
```

- [ ] **Step 3: Build**

Run: `xcodebuild -scheme Places -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`
Expected: BUILD SUCCEEDED.

- [ ] **Step 4: Commit**

```bash
git add Places/Components/Explore/CountdownBadge.swift Places/Components/Explore/UpcomingTripCard.swift
git commit -m "style: neutralize Explore info badges to match accent rule"
```

---

### Task 4: Popular Destinations — three peeks → one peek

**Files:**
- Modify: `Places/Components/Home/PopularCarousel.swift:14-15,54-58`

**Rationale:** The focused card is only 180pt wide, leaving room for ~3 collapsed 50pt capsules in the visible container — the three peeks the reviewer flagged. Widening the focused card so only one 50pt capsule peeks (with the rest reachable by scroll) is the fix. The collapse constants are coupled: `cardWidth`, the grow/shrink amount (`130` today, = `cardWidth − collapsedWidth`), and the per-card stride (`190` today, = `cardWidth + spacing 10`). They must move together to keep the collapsed capsule ~50pt.

**This is the one task whose exact pixel values are tuned against a screenshot.** Target relationships (collapsed capsule stays 50pt, spacing stays 10pt):
- `cardWidth` → the visible container width minus one peek and a gutter. On iPhone 17 Pro with 15pt horizontal padding the container is ~345pt; `cardWidth ≈ 345 − 50 (peek) − 10 (spacing) − 20 (right gutter) ≈ 265`. Start at **265**.
- shrink amount `= cardWidth − 50 = 215` (replaces the literal `130` at lines 55, 62, and the `-130`/`130` cap logic).
- stride `= cardWidth + 10 = 275` (replaces the literal `190` at lines 55 and 80, and the trailing padding base `180` at line 35 → use `cardWidth`).

- [ ] **Step 1: Update the card size constants**

`PopularCarousel.swift:14-15`:
```swift
  private let cardWidth: CGFloat = 265
  private let cardHeight: CGFloat = 200
```

- [ ] **Step 2: Replace the coupled magic numbers with derived values**

Introduce derived constants near the top of the view and use them in `cardView` and the trailing padding, replacing literals `130`, `190`, `180`:
- `.padding(.trailing, size.width - cardWidth)` (was `size.width - 180`, line 35)
- `let reducingWidth = (minX / stride) * shrink` where `stride = cardWidth + 10` and `shrink = cardWidth - 50` (was `(minX / 190) * 130`, line 55)
- `let cappedWidth = min(reducingWidth, shrink)` (was `min(reducingWidth, 130)`, line 56)
- In the `.offset { offset in ... }` block: `let reducingWidth = (offset / stride) * shrink` (was `(offset / 190) * 130`, line 80)

Keep `expandProgress`'s `/ 45` divisor as-is (controls the text fade, independent of width).

- [ ] **Step 3: Build**

Run: `xcodebuild -scheme Places -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`
Expected: BUILD SUCCEEDED.

- [ ] **Step 4: Visually tune and verify (Argent)**

Boot iPhone 17 Pro, launch Places, walk to Home, screenshot the Popular Destinations row. Confirm: exactly ONE collapsed capsule peeks beside the focused Maasai Mara card; scrolling still collapses/expands smoothly. If two peek, increase `cardWidth` by ~30 and rebuild; if the card is clipped, decrease by ~20.

- [ ] **Step 5: Commit**

```bash
git add Places/Components/Home/PopularCarousel.swift
git commit -m "style: Popular Destinations shows one peek instead of three"
```

---

### Task 5: Neutralize Home chrome accent (Sponsored rainbow + My Trips)

**Files:**
- Modify: `Places/View Models/HomeViewModels/SponsoredViewModel.swift:14,20,26,32,38`
- Modify: `Places/Components/Home/SponsoredCardView.swift:64`
- Modify: `Places/Components/Home/SponsoredDetails.swift:133`
- Modify: `Places/Components/Home/MyTripsStack.swift:87`

**Rationale:** The five sponsored cards use arbitrary rainbow system colors (`.orange/.blue/.green/.pink/.purple`) as a full-bleed background behind the photo and on the "Sponsored" pill — a real source of the "too colorful" feedback. The photo already covers the card, so the color block only shows through transparent placeholder edges. Collapse all five to a single neutral so the sponsor's *photo* carries identity. Keep the `accentColor` property (used by the hero morph) but set it neutral.

- [ ] **Step 1: Neutralize the sponsored sample colors**

In `SponsoredViewModel.swift`, change each `accentColor: Color.orange/.blue/.green/.pink/.purple` (lines 14, 20, 26, 32, 38) to `accentColor: Color(.systemGray4)`. Leave all other fields unchanged.

- [ ] **Step 2: Neutralize the "Sponsored" pill**

`SponsoredCardView.swift:64` — the pill currently uses `card.accentColor.opacity(0.85)`; with a neutral accent it now reads gray, which is correct. No change needed beyond Step 1, but verify the pill is legible against the photo; if not, switch it to `.ultraThinMaterial` to match the category pill on line 55:
```swift
.background(.ultraThinMaterial, in: .capsule)
```

- [ ] **Step 3: Neutralize the SponsoredDetails CTA pill**

`SponsoredDetails.swift:133` — this `card.accentColor` capsule now renders neutral via Step 1. Open the file, confirm it is a background pill (not text) and that neutral is legible; if it is the primary "book/see" CTA of the detail view, it MAY keep accent (allowed as a CTA). Decide by reading the surrounding label. Default: leave as the now-neutral `card.accentColor`.

- [ ] **Step 4: Neutralize My Trips accent capsule**

`MyTripsStack.swift:87` — read the surrounding context; if `.background(.accent, in: .capsule)` is a decorative badge, change to `Color(.systemGray5)`. If it is the card's primary action button, leave as accent. Default for a badge: neutral.

- [ ] **Step 5: Build**

Run: `xcodebuild -scheme Places -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`
Expected: BUILD SUCCEEDED.

- [ ] **Step 6: Commit**

```bash
git add "Places/View Models/HomeViewModels/SponsoredViewModel.swift" Places/Components/Home/SponsoredCardView.swift Places/Components/Home/SponsoredDetails.swift Places/Components/Home/MyTripsStack.swift
git commit -m "style: neutralize Home sponsored rainbow and My Trips accent"
```

---

### Task 6: Neutralize Profile chrome accent

**Files:**
- Modify: `Places/Views/Profile/ProfileSettingsList.swift:55,78,96`
- Modify: `Places/Components/ProfileHeader.swift:31`

**Rationale:** Settings row icons in accent/yellow and the accent header glyph are chrome. `SettingsRow`'s default `iconColor` is `.primary`, so removing the overrides makes all rows share one neutral icon color.

- [ ] **Step 1: Drop the colored icon overrides**

`ProfileSettingsList.swift:55` — remove the `iconColor: .accent,` line from the "Current plan" row.
`ProfileSettingsList.swift:78` — remove the `iconColor: .accent,` line from the "My Trips" row.
`ProfileSettingsList.swift:96` — remove the `iconColor: .yellow,` line from the "Rate Places" row.
Leave the `.badge(text:tint:)` plan accessory on line 57 as-is (it is a genuine status badge / active state).

- [ ] **Step 2: Neutralize the ProfileHeader glyph**

`ProfileHeader.swift:31` — currently `.foregroundStyle(isLargerHeader ? .white : .accent)`. Read the surrounding view to confirm what the glyph is. If it is a decorative icon, change the non-large branch to `.primary`:
```swift
.foregroundStyle(isLargerHeader ? .white : .primary)
```
If it is a primary action (e.g., edit/CTA), leave accent.

- [ ] **Step 3: Build**

Run: `xcodebuild -scheme Places -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`
Expected: BUILD SUCCEEDED.

- [ ] **Step 4: Commit**

```bash
git add Places/Views/Profile/ProfileSettingsList.swift Places/Components/ProfileHeader.swift
git commit -m "style: neutralize Profile settings icons and header glyph"
```

---

### Task 7: Apply `.pressable()` to primary tappable cards

**Files:**
- Modify: `Places/Views/Explore/ExploreTab.swift` (RecommendationCard button, CuratedTripCard button)
- Modify: `Places/Components/Home/SponsoredCardView.swift` (the tap target)

**Rationale:** Replace the removed entrance motion with quiet tap feedback on the main tappable surfaces. Keep it to the primary cards — do not blanket-apply.

- [ ] **Step 1: Add `.pressable()` to Explore card buttons**

In `ExploreTab.swift`, on the `RecommendationCard` button label (around line 73) and the `CuratedTripCard` button label (around line 113), append `.pressable()` after `.buttonStyle(.plain)` is not valid — instead apply to the card view inside the label, e.g.:
```swift
} label: {
    RecommendationCard(destination: destination)
        .pressable()
}
```
and
```swift
} label: {
    CuratedTripCard(trip: trip)
        .pressable()
}
```

- [ ] **Step 2: Add `.pressable()` to the Sponsored card**

In `SponsoredCardView.swift`, apply `.pressable()` to the root `content`-backed view (after `.contentShape(...)`, before/after `.onTapGesture`). Verify it does not interfere with the `matchedGeometryEffect` hero morph — if the scale conflicts visually with the morph, revert this one file.

- [ ] **Step 3: Build**

Run: `xcodebuild -scheme Places -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`
Expected: BUILD SUCCEEDED.

- [ ] **Step 4: Commit**

```bash
git add Places/Views/Explore/ExploreTab.swift Places/Components/Home/SponsoredCardView.swift
git commit -m "feat: add pressable tap feedback to primary cards"
```

---

### Task 8: Full visual verification sweep (Argent)

**Files:** none (verification only)

- [ ] **Step 1: Boot and reach the app**

Boot iPhone 17 Pro via Argent, launch Places, walk onboarding (auth → interest chips → home).

- [ ] **Step 2: Screenshot and check each screen against the accent rule**

- Home: screenshot. Confirm — coral appears only on the tab bar active icon / create CTA; Popular Destinations shows one peek; sponsored cards are neutral with photos leading; no entrance stagger.
- Explore: screenshot. Confirm — no stagger on load; Countdown and Trip-detail badges neutral; selected filter pill coral, others neutral.
- Profile: screenshot. Confirm — settings icons neutral; header glyph neutral; plan badge is the only colored element.

- [ ] **Step 3: Record results**

If any screen still shows stray accent, note the file:line and fix in a follow-up commit referencing this task. Otherwise the redesign is complete.

## Self-Review Notes

- **Spec coverage:** design-system layer → Task 1 (motion) + accent rule enforced across Tasks 3/5/6; motion budget → Tasks 2 + 7; accent rule → Tasks 3/5/6; images → unchanged by design; Popular three→one → Task 4; FilterPill/tab bar → already compliant (noted, no task); Profile/tab-bar sweep → Task 6; verification → Task 8. All spec sections mapped.
- **No unit tests** by design — this is visual work; the test cycle is build + Argent screenshot, stated per task.
- **Judgment calls** (SponsoredDetails CTA, MyTripsStack badge, ProfileHeader glyph) are flagged inline with a stated default and a "read surrounding context first" instruction, since each could be either chrome or a genuine CTA.
