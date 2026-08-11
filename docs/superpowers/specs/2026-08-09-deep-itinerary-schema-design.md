# Deep Itinerary Schema — Design (design-only)

**Status:** Design-only. No implementation planned in this document. This captures the target
shape so the current "shallow" generator can evolve into a richer, bookable day plan without a
schema rewrite later. Build lands in a future plan (likely gated behind the paid/offline tier —
see `docs/ideas/monetization-and-offline.md`).

**Date:** 2026-08-09
**Author:** Places
**Relates to:** the itinerary grounding work committed 2026-08-09 (`GroundingCatalog` +
`GroundingPlace`), which repointed generation at live Supabase content.

---

## 1. Context & problem

Today `GeneratedItinerary` (in `Places/Models/Itinerary/GeneratedItinerary.swift`) produces a
title, summary, rationale, and `days: [ItineraryDay]`, where each `ItineraryActivity` carries only
`kind`, `title`, `description`, `placeName`. It's a good *outline* but a shallow *plan*: no times,
no durations, no cost, no per-day budget, no practical notes. The on-device (~3B) model also tends
to produce thin prose, which is fine for an outline but weak for a plan a traveler would actually
follow and pay against.

The "deep" version targets **3–4 activities per day, each with a time slot, an estimated duration,
a short practical note, and a price estimate — plus a per-day cost total and a trip total.** Prices
must be *grounded*, not hallucinated: they come from the Supabase content the itinerary is already
grounded on (destination fees, experience `price_per_guest`), surfaced through the same tool/prompt
seam that names places.

## 2. Design principles

1. **Additive, not a rewrite.** New fields are optional/defaulted so the shallow renderer, the
   `ItineraryDisplay` mirror, and the cloud edge function schema all keep working during rollout.
   A missing price or time renders as absent, never as a fabricated zero.
2. **Prices are grounded, never invented.** The model must not free-form a number. It selects a
   `placeName` from the grounded catalog; the *price basis* for that place travels with the tool
   result (and the cloud prompt), and cost totals are computed in Swift, not by the model.
3. **Structured cost, displayable string.** Money is a small struct (amount + currency + a
   confidence/basis flag), not a `String`, so per-day and trip totals are summable and formattable
   for the user's locale. The model still gets a human hint; the app owns the arithmetic.
4. **Respect the streaming recipe.** A deeper `@Generable` graph = more tokens per snapshot. Keep
   the on-device generation working under the proven recipe (greedy sampling,
   `includeSchemaInPrompt: false`, a concrete `example`, tool-free refine session). Depth is opt-in
   per tier so the on-device path can generate a *reduced* deep plan if latency demands it.

## 3. Target schema (evolution of `GeneratedItinerary`)

Shown as the intended Swift shape. Every new field is optional or defaulted so partial/streamed and
legacy values decode cleanly.

```swift
@Generable
struct ItineraryActivity: Equatable, Codable {
    var kind: ActivityKind
    var title: String
    var description: String

    @Guide(description: "The real place name for this activity. Prefer a name returned by findPlaces.")
    var placeName: String

    // --- deep fields (all optional / additive) ---

    @Guide(description: "Approximate local start time, 24h 'HH:mm' (e.g. '09:30'). Omit if flexible.")
    var startTime: String?

    @Guide(description: "Rough duration in minutes for pacing the day (e.g. 120). Omit if open-ended.")
    var durationMinutes: Int?

    @Guide(description: "One short, practical tip: booking, what to bring, best timing. One sentence.")
    var note: String?

    /// Grounded cost estimate for this activity. NOT free-formed by the model — see §4.
    var priceEstimate: MoneyEstimate?
}

@Generable
struct MoneyEstimate: Equatable, Codable {
    @Guide(description: "Estimated amount for this activity, per the trip's party size.")
    var amount: Double
    @Guide(description: "ISO-ish currency code, e.g. 'USD' or 'KES'.")
    var currency: String
    /// How the number was derived — drives UI treatment ("est." vs "from").
    var basis: CostBasis   // .grounded (from DB), .rangeMidpoint, .modelGuess (last resort, flagged)
}

@Generable
enum CostBasis: String, Codable, CaseIterable { case grounded, rangeMidpoint, modelGuess }

@Generable
struct ItineraryDay: Equatable, Codable {
    var title: String
    var subtitle: String
    @Guide(description: "Three to four activities for the day, time-ordered.")
    var activities: [ItineraryActivity]

    @Guide(description: "One line on the day's travel logistics (drive time, transfers). Optional.")
    var travelNote: String?
}
```

Trip-level and day-level **totals are computed in Swift, not generated.** `GeneratedItinerary` gains
nothing new; instead a derived layer sums the grounded `priceEstimate`s:

```swift
extension ItineraryDay {
    /// Sum of grounded/range activity costs; nil if the day has no priced activities.
    var estimatedCost: MoneyEstimate? { /* fold activities, drop .modelGuess from the headline */ }
}
extension GeneratedItinerary {
    var estimatedCost: MoneyEstimate? { /* sum of day costs in a single display currency */ }
}
```

Rationale for computing totals in Swift: the model is unreliable at arithmetic and at holding a
running sum across a streamed structure; and totals must stay consistent as partial snapshots arrive.

## 4. Grounding the prices (the crux)

The model chooses *places*; the app owns *prices*. Concretely:

- The grounding catalog already carries a `GroundingPlace` per destination/experience. Extend that
  value (design-only) with a **price basis**: for a destination, its `non_resident_fee_usd` /
  `price_range`; for an experience, `price_per_guest` + `currency`. This is data the DTOs already
  expose — no new Supabase columns required for v1.
- **On-device path:** `FindPlacesTool` already returns the exact names to use. Its result string
  gains a per-place price hint (e.g. `"- Amboseli National Park: Wildlife park (fee ~ $60 pp)"`),
  and after generation the app *recomputes* each activity's `priceEstimate` from the catalog by
  `placeName`, overriding whatever the model emitted. The model's number is only a fallback
  (`.modelGuess`, visibly flagged) when a place isn't in the catalog.
- **Cloud path:** the edge function already receives `placeNames`. It also receives the price basis
  per name and instructs the model (structured-output schema) to attach the grounded amount; the
  app still re-grounds on return for consistency. **The edge function's JSON schema changes are
  part of the future build, not this design doc** — noted here only so the two schemas evolve
  together.
- Party size: `TripConfig` already knows the traveler count; per-guest experience prices are
  multiplied in Swift, not by the model.

Net: a price shown to the user is either **grounded** (from DB) or an explicit **estimate**, never a
silent hallucination — consistent with the "purge hardcoded/fake data" principle guiding the app.

## 5. Rendering & back-compat

- `ItineraryDisplay` (the streamed mirror) gains the same optional fields; existing views ignore
  what they don't read, so the shallow card keeps working until the deep card ships.
- `ItineraryMessageView` grows a compact activity row: time chip · title · duration · price chip,
  with the day footer showing `estimatedCost` and the trip header showing the trip total. Absent
  fields collapse (no empty chips).
- `SavedTrip` persistence: the deep fields serialize with the itinerary; older saved trips decode
  with the new optionals `nil`, so no migration is needed.

## 6. On-device vs cloud depth (tiering)

- **Cloud (default for deep):** full 3–4 activities/day with times, notes, grounded prices, totals.
- **On-device (premium offline):** same schema, but generation may target a *reduced* deep plan
  (e.g. skip `travelNote`, allow fewer notes) if latency/quality on the 3B model demands it — the
  schema is identical, only the prompt's ambition changes. This keeps one model type across both
  engines and one renderer.
- Which tier a user gets is a monetization decision parked in `docs/ideas/monetization-and-offline.md`,
  not resolved here.

## 7. Non-goals / explicitly deferred

- Real-time pricing, availability, or booking. Prices are planning estimates from static content.
- New Supabase columns. v1 deep pricing reuses existing destination/experience fields.
- Building any of this. This document is the *target shape*; the implementation plan (schema change,
  tool/edge-function price plumbing, Swift totals, deep card UI, tests) is a future writing-plans pass.
- Multi-currency FX. v1 picks one display currency for totals; mixed-currency handling is later.

## 8. Open questions (to resolve at build time)

1. Display currency for totals when a trip mixes USD destination fees and KES experience prices —
   pick the user's locale currency and convert with a static table, or show a dominant currency?
2. How aggressively to constrain the on-device model's activity count without triggering the
   tool-loop stalls the shallow version already had to work around.
3. Whether `MoneyEstimate.basis == .modelGuess` should be shown at all, or suppressed from totals
   and rendered as "price varies" instead of a flagged number.
