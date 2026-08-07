# Quiet Hierarchy — Home / Explore / Profile Restyle

**Date:** 2026-08-07
**Status:** Approved design, pending implementation plan
**Screens in scope:** Home (`HomeTab`), Explore (`ExploreTab`), Profile (`ProfileTab`)

## Problem

User testing of the Home, Explore, and Profile screens surfaced five complaints
that all share one root cause — **everything competes for attention at once, so
nothing leads**:

1. Per-screen animations are excessive and distract from content.
2. The coral accent is overused across pages and the tab bar; reads unprofessional.
3. Images grab too much attention; colorful buttons compound it.
4. Reviewer suggested **1–2 major animations per screen, everything else micro**,
   taking inspiration from Airbnb / Stippl / Wanderlog.
5. On **Popular Destinations**, the focused card shows **three thin capsule
   previews** peeking beside it — collapse to **one**.

The underlying note — "sell emotions, keep minds in the app" — is the *why*:
restraint is what makes a travel app feel aspirational instead of busy.

## Principle (north star)

**Quiet hierarchy.** Neutral chrome, coral used only to point, motion that
navigates rather than decorates, and photos as the sole source of color. Modeled
directly on current Airbnb iOS: near-monochrome UI where the accent appears only
on the active tab, notification dots, and a single primary tag — photos carry all
the color, so no image desaturation is needed because the surrounding UI is quiet
enough to let them lead.

## Confirmed decisions

- **Approach:** design-system first (define cross-cutting rules once, then apply
  to all three screens). Every complaint is cross-cutting, so per-screen restyling
  would re-litigate the same choices three times.
- **Motion budget:** keep purposeful *transitions*, cut decorative *entrance*
  motion, add subtle micro-feedback. Net: 1 signature transition per screen +
  quiet micro-interactions.
- **Accent rule (Airbnb-strict):** coral (`#FD5E53`, unchanged) allowed on exactly
  three things — the primary CTA fill, the active tab icon, and the selected/active
  state. Everything else is neutral. Note the hue is already almost identical to
  Airbnb's `#FF5A5F`; the problem was overuse, not the color.
- **Images:** no desaturation. Neutral chrome does the work of letting photos lead.

## Design

### 1. Design-system layer (built first)

New `DesignSystem/` group holding the rules so no screen re-invents them.

- **Accent role.** A single source of truth for where coral is permitted: primary
  CTA fill, active tab icon, selected/active state. All other former accent usages
  resolve to a neutral ramp (`.primary` / `.secondary` / `.tertiary` labels,
  neutral icons, neutral outlines). This one rule resolves complaint #2.
- **Motion budget.**
  - Remove the `microAnimations` entrance stagger from the three screens. Leave
    `MicroAnimations.swift` in place (unused, harmless) — removing the file is out
    of scope.
  - Keep `DestinationTransition` (Home hero morph) and the Sponsored
    matched-geometry transition — these aid spatial continuity and read as premium.
  - Add one shared `.pressable()` micro-feedback modifier (~0.97 scale, ~0.12s)
    for tap feedback on cards/buttons.
- **Button styles.** `PrimaryButton` stays a solid coral capsule — it is *the* one
  CTA, which the accent rule permits. Add a **secondary/neutral** button style
  (outline or `.quaternary` fill) for every non-primary action so buttons stop
  competing.
- **`FilterPill`.** Flip the default from accent-filled to **white + thin gray
  outline**; only the *selected* pill gets coral. Matches the Airbnb reference.

### 2. Home (`HomeTab`)

- Keep the `DestinationTransition` hero — it is the screen's signature moment.
- **`PopularCarousel`: three peeks → one peek.** Constrain the windowing carousel
  so the focused card shows the full card plus **exactly one** collapsed capsule of
  the next destination; remaining destinations stay reachable by horizontal scroll
  but are not shown at rest. This is complaint #5. Note the effect is scroll-driven
  (`minX`-based width windowing in `cardView`), so the change is to the visible
  trailing width / clipping, not the data — implement carefully to preserve the
  collapse animation for the single remaining peek.
- Neutralize any accent on chrome (section headers, "View all" affordances, badges).
  The 415pt full-bleed hero image stays (photo carries the color); its
  `DestinationInfoBar` already uses `.ultraThinMaterial`, which is the correct quiet
  treatment — keep it.
- Sponsored / Popular overlays: verify no accent leakage on labels or badges (the
  category/rating capsules already use `.ultraThinMaterial` — correct, keep).

### 3. Explore (`ExploreTab`)

- Remove the four staggered `.microAnimations(...)` calls
  (`ExploreTab.swift:29–39`).
- `FilterPill` adopts the neutral rule (from the design-system layer).
- Section titles already neutral — leave as-is.

### 4. Profile (`ProfileTab`)

- Largely neutral already. Sweep `ProfileHeader` and `ProfileSettingsList` for
  accent usage and reduce to the rule — settings rows neutral, not colorful.

### 5. Tab bar (`CustomTabBar`)

- Active icon coral; inactive icons neutral gray. Confirm it is not tinting the
  whole bar or multiple items at once.

## Out of scope

- `GravityContainer` / onboarding screens — not used on the three screens under
  review (`GravityContainer` appears only in `SecondOnboarding`).
- `RecommendationCard`'s fanned 3-photo stack — a candidate for the same
  simplification, but **not** what the reviewer flagged (that was Popular
  Destinations). Left unchanged to stay focused; can be revisited separately.
- Backend, data, and the unused `MicroAnimations.swift` file itself.

## Verification

After implementation, build and boot the iPhone 17 Pro simulator via Argent and
screenshot Home, Explore, and Profile to confirm the "quiet" result. Note the known
constraint that onboarding resets every launch, so each rebuild requires walking
auth → interest chips → home before reaching the screens under test.

Success criteria:
- Coral appears only on: primary CTA, active tab icon, selected/active state.
- No entrance stagger on any of the three screens; hero/Sponsored transitions intact.
- Popular Destinations shows one peek beside the focused card, not three.
- Filter pills default to neutral, selected pill coral.
