# App Store Submission Prep — "Places in East Africa" v1.0

**Goal:** Ship v1.0 to the App Store today. This is the ship-side checklist (site, screenshots, metadata, IAP review, privacy, submit). The app itself is build-clean on `polish/pre-launch-qa`.

**App identity**
- Name: **Places in East Africa** · Bundle: `com.sylusabel.Places` · Version **1.0** (build 1) · iOS 26.5+
- Backend: Supabase · Purchases: RevenueCat (entitlement `pro`) · AI: OpenAI (cloud) + on-device
- Privacy usage strings: **none required** (PhotosPicker out-of-process; Sign in with Apple; no camera/mic/location)

---

## 1. Marketing site — Issues / Privacy / Terms  (task #66)

The profile **More** menu + the paywall link to these. Currently stubbed at `https://places.app/{support,contact,privacy,terms}`.

- [ ] Confirm the **real domain** for the cloned site (e.g. `placesineastafrica.com`). → tell me and I swap the 4 stub URLs in `ProfileHeader.swift` + the 2 in `PaywallView.swift` (Terms/Privacy) in one commit.
- [ ] Publish 3 pages (drafts provided in `docs/site/`): **Privacy Policy**, **Terms of Service**, **Support/Contact** (doubles as the "Report an issue" page).
- [ ] App Store requires a **Support URL** and a **Privacy Policy URL** — both come from this site.

**Blocking need from you:** the domain + a contact email for support.

---

## 2. App Store screenshots  (task #67)

Pipeline = **Argent (raw sim captures) → ASO skill (`compose.py` text scaffold) → Nano Banana Pro via Gemini MCP (frames + polish) → `final/` 1290×2796**.

Prereqs (one-time):
- [ ] `claude install-skill github.com/adamlyttleapps/claude-skill-aso-appstore-screenshots`
- [ ] `pip install Pillow`
- [ ] Install font `SF-Pro-Display-Black.otf` to `/Library/Fonts/` (Apple's SF Pro download)
- [ ] Gemini MCP already installed ✓

**Sizes Apple needs:** 6.7" (1290×2796) mandatory; 6.5" auto-scales from 6.7" in most cases. iPad only if we mark iPad support (we're iPhone-first → skip).

**Benefit → screen → headline map (5 screenshots):**
| # | Benefit | Screen to capture | Headline (compose.py) |
|---|---------|-------------------|-----------------------|
| 1 | AI plans your whole trip | Generated itinerary (populated) | "Your East Africa trip, planned in seconds" |
| 2 | Grounded in real places | Destination detail (stretchy hero) | "Real places, real prices — not generic AI" |
| 3 | Go further with Pro | Paywall | "Unlimited trips. Multi-country. Monthly tokens." |
| 4 | Discover & explore | Explore tab (map card + collections) | "Discover Kenya, Tanzania, Uganda & more" |
| 5 | Optimize + export | Trip view w/ Optimize / PDF share | "Optimize your day. Export as PDF." |

- [ ] Capture raw screens on the sim (I can drive Argent) — need a signed-in state with content loaded; screenshot #3/#5 show Pro UI (either force a Pro state on sim or reuse a device capture).
- [ ] Run the skill → review `showcase.png` → export `final/`.

---

## 3. App Store Connect metadata  (task #68)

**Name:** Places in East Africa
**Subtitle (30 char):** `AI trips across East Africa`
**Promotional text (170):** `Plan grounded, multi-country East Africa itineraries with AI — real places, real prices. Go Pro for unlimited trips, PDF export, and monthly tokens.`
**Keywords (100):** `kenya,tanzania,uganda,safari,travel,itinerary,trip planner,east africa,AI,tour,vacation,maasai mara`
**Description:** draft in `docs/site/appstore-description.md`.
**Support URL / Marketing URL / Privacy URL:** from §1.
**Category:** Primary **Travel**, Secondary **Lifestyle**.
**Age rating:** 4+ (verify questionnaire — no objectionable content).
**Sign-in required for review:** YES → provide a demo Apple ID + note SIWA (see §5).

---

## 4. Privacy nutrition labels (App Privacy)  (task #68)

Data collected (map in ASC → App Privacy):
- **Contact Info → Email Address**: Sign in with Apple. Linked to identity. Not used for tracking.
- **Identifiers → User ID**: Supabase/RevenueCat user id. Linked. Not tracking.
- **Purchases → Purchase History**: IAP via RevenueCat/Apple. Linked. Not tracking.
- **User Content → Photos**: optional avatar → Supabase Storage. Linked. Not tracking.
- **User Content → Other**: trip prompts/preferences sent to the AI (OpenAI) to generate itineraries. Linked. Not tracking.
- **Diagnostics / Usage Data**: none (no analytics/crash SDK) — confirm.
- **Tracking:** NO (no ATT, no ad networks). → App Tracking Transparency not required.

Third parties to disclose in the policy: Supabase, RevenueCat, OpenAI, Apple.

---

## 5. In-App Purchases + review  (task #68)

Entitlement `pro`. Products (RevenueCat ↔ ASC):
- Subs (group `places_pro`): `piea_149_1w` (weekly, +50 tok), `piea_249_1m` (monthly, +500), `piea_999_1y` (annual $14.99, +6000)
- Non-consumable: `piea_pro_lifetime` ($49.99, +1000/mo via cron)
- Consumables (token packs): `tokens_99_25`, `token_199_75`, `token_449_200`, `token_999_500`

- [ ] Every product in ASC: **Ready to Submit**, price tier set, localized name/desc, **screenshot uploaded per IAP** (Apple requires one image per IAP — can be the paywall/coin-shop capture).
- [ ] First submission: attach IAPs to the app version so they review together.
- [ ] **Reviewer notes** (draft below) — explain tokens + how to test, and give the sandbox/demo account.

**Reviewer notes draft:**
> Places in East Africa is an AI travel-itinerary planner. Sign in with Apple is required. A demo account is provided below.
> Free users get a starter token balance and can generate itineraries (tokens are spent server-side per generation). "Places Pro" (auto-renewable weekly/monthly/annual, or a one-time Lifetime) unlocks unlimited multi-country planning, PDF export, day optimization, and a monthly token grant. Token packs are consumables that add to the balance.
> Login: **Sign in with Apple is required. Please use your own Apple ID — no demo account is needed.**
> To test purchases, the sandbox environment is used automatically. Purchases credit tokens / unlock Pro via a RevenueCat webhook to our backend.
> The weekly subscription includes a 3-day free trial for new subscribers.

- [ ] No demo account required — reviewers use their own Apple ID via SIWA (leave demo-account fields blank; keep the note above).
- [ ] Support email: **sylusabel1@gmail.com** (Marketing/support URL from the site).

## 7. Free trial — 3-day on weekly (`piea_149_1w`)  (task: new)
- [ ] ASC → Subscriptions → `places_pro` → weekly → **Introductory Offer → Free, 3 days, All territories, new subscribers**.
- [ ] RevenueCat: no change (reads the intro offer from StoreKit automatically).
- [ ] App copy: paywall CTA → "Start 3-day free trial" when weekly (trial-eligible) is selected; fix the stale pitch line "14 days free, then $0.99/month".

---

## 6. Final submit  (task #68)

- [ ] Device QA green (task #65) — Pro badge/frame, PDF, Optimize, offline banner, all 10 UI fixes.
- [ ] Swap stub URLs (from §1) → commit → merge `polish/pre-launch-qa` → main → push.
- [ ] Archive (Any iOS Device) → validate → upload to ASC (or Xcode Cloud).
- [ ] Fill metadata (§3), privacy (§4), screenshots (§2), IAP review (§5).
- [ ] Attach build, answer export-compliance (uses standard HTTPS only → usually "No" to custom crypto), submit for review.

---

## Blocking inputs I need from you
1. **Site domain** + **support email** (to finalize URLs + legal pages).
2. Whether to **force a Pro state on the sim** for screenshots #3/#5, or you'll hand me a couple of device captures.
3. **Demo Apple ID** for reviewer notes (or we rely on "reviewer uses own Apple ID via SIWA").
