# Deep Itinerary — build spec (1b)

Finalizes `2026-08-09-deep-itinerary-schema-design.md` with the agreed decisions and adds dates,
currency, an edge-function tool, and bookmark-aware generation. Built in additive waves so nothing
breaks between them. Priority: **get the structure right**; static/approximate data now, dynamic later.

## Decisions
1. **Times** — the AI assigns local clock times per activity.
2. **Real dates** — `TripConfig` gains a start date; day tabs show real dates.
3. **Prices** — grounded from our DB where the place matches (destination fee / experience price);
   the model approximates otherwise (flagged). Default currency **USD**, alternative **KES**.
4. **Notes/tips** — AI-generated trip tips + per-day travel notes.
5. **Tool** — a Supabase edge function the generation can plug into; may return **static** data now,
   real later. Structure is what matters.
6. **Bookmarks** — stored **locally on-device** (no upstream sync yet); a create-wizard question asks
   whether to seed the itinerary from saved places or plan something new.

## Schema (additive; all new fields optional → safe for both engines' Codable + streaming)
```swift
@Generable struct MoneyEstimate: Codable { var amount: Double; var currency: String }  // "USD" | "KES"

// GeneratedItinerary += var tips: [String]?          // trip tips (weather, getting around, money)
// ItineraryDay        += var travelNote: String?      // one-line day logistics
// ItineraryActivity   += var startTime: String?       // "09:30" (24h)
//                     += var durationMinutes: Int?
//                     += var note: String?            // one practical tip
//                     += var price: MoneyEstimate?
```
Budget totals are **computed in Swift**, never by the model: `ItineraryDay.estimatedTotal` and
`GeneratedItinerary.estimatedTotal`, summed in the display currency via a static FX table
(`Currency.convert`). The model's per-activity price is a fallback; a post-generation pass overrides
it with the **grounded** DB price when the `placeName` matches a catalog place (adds `priceUSD` to
`GroundingPlace`). `MoneyEstimate` shows an "est." affordance when not grounded (tracked in the
display layer, not the model).

## Currency
`TripConfig.currency: Currency = .usd` (`.usd` / `.kes`). Passed to generation; totals display in it.
Static FX (`Currency`): 1 USD ≈ 130 KES (one constant, swap for a rate API later).

## Edge-function tool — `trip-intel`
`supabase/functions/trip-intel/index.ts`. Input `{ destination, month? }` → static structured JSON:
`{ weatherSummary, gettingAround, currencyTips, priceLevel, bestTime }`. Wave 5 wires it as context
the app fetches per-trip and injects into the prompt (both engines), and as a callable tool shape for
the cloud function. Static now; get the request/response contract right.

## Bookmarks (local)
- `@Model SavedPlace` (SwiftData): `id`, `kind` (destination|experience), `refId`, `name`,
  `imageURL`, `subtitle`, `latitude`, `longitude`, `createdAt`.
- `DestinationDetailView` bookmark toggle + an experience bookmark toggle persist to it.
- `TripConfig.useSavedPlaces: Bool`; when true, `start()` fetches saved places and injects their
  names as preferred grounding (seeds the itinerary from them).

## Create-wizard additions
Steps/fields: **start date** (date picker), **currency** (USD/KES segmented), **"Base this on your
saved places?"** (only shown if the user has any bookmarks). All flow into `TripConfig`.

## UI (timeline already has the slots from 1a)
- Time chip (`startTime` · `durationMinutes`) on each timeline row.
- Price chip per activity (grounded vs "est.").
- Per-day total + trip **budget summary** card.
- **Tips** section (trip `tips`) + per-day `travelNote`.
- Day tabs show real dates when `startDate` is set.

## Waves (each builds + stays green)
1. **Schema** — the structs above + example/partial/display plumbing + budget computation + `Currency`.
2. **Generation** — system prompt + `@Guide`s + cloud request/edge-function JSON schema fill the fields;
   grounded-price override pass (`GroundingPlace.priceUSD`).
3. **Bookmarks** — `SavedPlace` model + wire the detail bookmark toggles + saved-places store.
4. **Config** — start date + currency + "use saved places" in the wizard → `TripConfig`.
5. **Tool** — `trip-intel` edge function (static) + fetch/inject as context.
6. **UI** — timeline time/price chips, budget summary, tips, dated day tabs.
