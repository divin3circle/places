# Itinerary v0 Polish — target + triage

**Date:** 2026-08-10
**Goal:** Move the itinerary from a "toy" to a usable app for the Aug-20 launch by making our
**generated plan** the richest, most beautiful AI itinerary — borrowing *presentation* patterns from
TripIt / Wanderlog, and deferring their *plumbing* (imports, real-time, collaboration, offline) to
post-launch.

## The framing
Our edge is **AI generation + grounding** (`GeneratedItinerary` → days → activities + grounded
coordinates/images + MapKit + the cloud/on-device engines). TripIt/Wanderlog win on logistics that
need integrations we don't have (email/OAuth, flight APIs, multi-user sync, payments). So v0 makes
the *plan* premium; the integrations wait.

## Triage

### Bucket 1 — Ship in v0 (architecture already supports it)

**1a. Cheap UI wins — no schema change, data we already have (THIS pass):**
- **Day tabs** — a horizontal day selector; show one day's timeline at a time (Wanderlog/TripIt).
- **Timeline layout** — vertical connector + kind-icon nodes for a day's activities (TripIt).
- **Numbered map pins** — the itinerary map shows route order (1..N) instead of plain markers.
- **Time/distance between stops** — "~2 km · ~15 min drive/walk" between consecutive resolved
  places, computed from grounded coordinates (straight-line estimate; offline, no routing API).

**1b. The deep-itinerary build — spec written, additive schema (next):**
- Per-activity **time + duration + note**, trip **notes/tips**, **per-day + trip budget totals**
  from grounded prices (destination fees, experience prices).
- Section-level **AI magic-wand** reuses the existing refine engine.
- Full design: `docs/superpowers/specs/2026-08-09-deep-itinerary-schema-design.md`. The 1a UI
  (timeline rows, day tabs) is built so these fields slot in without a rewrite.

### Bucket 2 — Needs more added (v0 only if time; else early v1)
- Explore-within-a-trip (reuse ContentStore; limited to our curated content).
- Route optimization (MKDirections + reorder; our plans are already AI-ordered).
- Attach documents (trip-attachments Storage bucket + picker/viewer).
- Bucket lists / saved places (saved-items table; the DestinationDetailView bookmark is a stub).

### Bucket 3 — After the 20th (v1 — big infra / monetization)
- Collaborate + split costs (move trips to Supabase + sharing/realtime).
- Import reservations (email forward / Gmail sync — parsing + OAuth).
- Real-time flight alerts/status (flight-data API + push; we're activity-first, not flight-first).
- Offline access + offline maps (the parked premium/offline phase).
- Booking / reservations (payments + partners — monetization).

## v0 sequence
1. **Wave 1 (1a):** day tabs + timeline + numbered pins + distance chips in TripView. Pure UI over
   existing data; zero new backend.
2. **Wave 2 (1b):** the deep-itinerary schema build (times/durations/notes/budget) + section AI.
