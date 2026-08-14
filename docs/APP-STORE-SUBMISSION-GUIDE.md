# App Store Submission Guide — "Places in East Africa" v1.0

A field-by-field checklist for App Store Connect (ASC), tailored to this app, ordered to minimize rejections. Copy-paste values are in code blocks. Do the sections in this order.

**App facts:** Name `Places in East Africa` · Bundle `com.sylusabel.Places` · Version `1.0` (build 1) · iPhone-only · iOS 26.0+ · Free with In-App Purchases · Login = Sign in with Apple.

---

## 0. Before you touch ASC
- [ ] Archive the app from Xcode (**Any iOS Device**, ensure it includes latest `main`), upload to ASC → wait for the build to finish "Processing" (10–30 min). You need the build to attach later + for TestFlight.
- [ ] Site is live: `https://places-web.vercel.app` with `/privacy`, `/terms`, `/support` (verified 200). Update the live `/support` page: change "unlimited itineraries" → "unlimited saved trips & bookmarks" so it matches the app.

---

## 1. General → App Information  (set once, applies to all versions)
- **Name:** `Places in East Africa`
- **Subtitle (max 30):**
  ```
  AI trips across East Africa
  ```
- **Category:** Primary **Travel**, Secondary **Lifestyle**
- **Content Rights:** Choose "Contains, shows, or accesses third-party content" only if applicable. ⚠️ **Confirm you own or are licensed for every destination/experience image** in the app (Supabase content). If any are stock (Unsplash/etc.), make sure the license allows commercial app use. Using images without rights is a real rejection reason.
- **Age Rating:** open the questionnaire, answer **None/No** to all (no violence, sexual content, gambling, drugs, unrestricted web). Opening specific external links in Safari is **not** "unrestricted web access" → leave that No. Result: **4+**.
- **Privacy Policy URL:**
  ```
  https://places-web.vercel.app/privacy
  ```

---

## 2. Version page (1.0 "Prepare for Submission")

### Promotional Text (max 170)
```
Plan grounded, multi-country East Africa itineraries with AI — real places, real prices. Go Pro for PDF export, day optimization, and monthly tokens.
```

### Description
Paste from `docs/site/appstore-description.md` (already accuracy-checked — no offline-maps or collaboration claims). Do NOT add features the app lacks.

### Keywords (max 100 chars, comma-separated, no spaces to save room)
```
kenya,tanzania,uganda,safari,itinerary,trip planner,east africa,travel,tour,maasai mara,vacation,ai
```

### URLs
- **Support URL:** `https://places-web.vercel.app/support`
- **Marketing URL** (optional): `https://places-web.vercel.app`

### Version / Copyright
- **Version:** `1.0`
- **Copyright:**
  ```
  2026 Sylus Abel
  ```

### Routing App Coverage File
- **Leave empty.** (Only for Navigation apps that ship a geographic-coverage file for turn-by-turn directions — not us.)

### App Clip / iMessage App
- **Leave collapsed / empty.** Not applicable.

### Previews and Screenshots  (the red "dimensions are wrong" error)
Your files were 1290×2796 (old size). Use the correctly-sized sets I generated:
- **6.9″ Display slot** → upload `appstore/screenshots/upload-6.9/` (1320×2868). *This is Apple's baseline; filling it auto-covers smaller iPhones.*
- **6.5″ Display slot** (the one showing the error) → upload `appstore/screenshots/upload-6.5/` (1284×2778).
- **iPad tab:** ignore/leave empty — the app is iPhone-only.
- Upload order (first 3 matter most): `06-itinerary` → `01-plan` → `03-explore` → `02` → `07` → `05` → `04`.
- No app preview video needed.

---

## 3. Build
- [ ] Scroll to **Build** on the version page → **+** → select the processed build (v1.0 (1)) → Done.

---

## 4. App Privacy (Trust & Safety → App Privacy)
Set **Data Collection = Yes**, then add these types. For every one: **Linked to the user = Yes**, **Used for tracking = No**, Purpose = **App Functionality** (Email may also add **Account Management**).

| Data type | Category |
|---|---|
| Email Address | Contact Info |
| Name (optional, from Sign in with Apple) | Contact Info |
| User ID | Identifiers |
| Purchase History | Purchases |
| Photos or Videos (profile avatar) | User Content |
| Other User Content (trip prompts sent to AI) | User Content |

- **Tracking:** No (no ATT prompt, no ad SDKs).
- Third parties that process data (disclosed in your Privacy Policy): Supabase, RevenueCat, OpenAI, Apple.

---

## 5. App Review Information (General → App Review)
- **Sign-in required:** Yes.
- **Demo account:** The app uses **Sign in with Apple only** — you don't have a username/password to give. In the **Notes**, tell the reviewer to use their own Apple ID. If ASC forces demo credentials, create a throwaway Apple ID (never your personal one) and put it here.
- **Contact info:** your first/last name, phone, email (`sylusabel1@gmail.com`).
- **Notes (paste):**
  ```
  Places in East Africa is an AI travel-itinerary planner for Kenya, Tanzania, Uganda and the region.

  SIGN IN: Sign in with Apple is required. Please use your own Apple ID — no demo account is needed.

  PURCHASES: The sandbox environment is used automatically in review. Free users get a starter token
  balance and can generate itineraries (tokens are spent server-side per generation). "Places Pro"
  (auto-renewable weekly/monthly/annual, or a one-time Lifetime) unlocks unlimited saved trips &
  bookmarks, multi-country planning, PDF export, day optimization, priority AI, and a monthly token
  grant. Token packs are consumables that add to the balance. Purchases credit the account via a
  RevenueCat webhook to our backend. The weekly plan includes a 3-day free trial for new subscribers.

  REQUIRES iOS 26 (uses Apple Intelligence / on-device Foundation Models for offline itinerary generation).
  ```

---

## 6. Pricing and Availability (Monetization)
- **Price:** Free (the app is free; revenue is via IAP).
- **Availability:** All countries/regions (or select your launch markets).
- **Release:** "Automatically release after approval" (or manual if you want to control the exact 20th).

---

## 7. In-App Purchases & Subscriptions (Monetization)
All products must be **Ready to Submit** and attached to the 1.0 version (first submission reviews app + IAPs together).

**Subscriptions** (group `places_pro`): `piea_149_1w` (Weekly), `piea_249_1m` (Monthly), `piea_999_1y` (Annual, $14.99), + **non-consumable** `piea_pro_lifetime` ($49.99).
**Consumables** (token packs): `tokens_99_25`, `token_199_75`, `token_449_200`, `token_999_500`.

For **each** product:
- [ ] Localized **display name** + **description**.
- [ ] **Price** tier set.
- [ ] **Review screenshot** uploaded (Apple requires one image per IAP — use a paywall or coin-shop screenshot; any `appstore/screenshots` shot works).
- [ ] Status = **Ready to Submit**.
- [ ] On the version page, under **In-App Purchases**, select all products to **submit with this version**.

**3-day free trial (weekly):**
- [ ] Subscriptions → `places_pro` → `piea_149_1w` → **Introductory Offer → Create** → Type **Free**, Duration **3 days**, territories **All**, eligibility **new subscribers**.
- RevenueCat needs no change (reads the offer automatically); the paywall already shows "3-day free trial" when it's live.

---

## 8. Export Compliance
Already declared in the build (`ITSAppUsesNonExemptEncryption = NO`, standard HTTPS only), so ASC won't prompt you each upload. If asked: "Does your app use encryption?" → **No** (beyond standard/exempt).

---

## 9. TestFlight (do this FIRST, before App Store review, for your friends)
- [ ] Once the build finishes processing, go to **TestFlight**.
- **Internal testing:** add yourself/team (up to 100) → instant, no review. Good for immediate self-test.
- **External testing (friends):** create a group → add their emails or enable a **public link** → provide a short **beta description** + feedback email → submit for **Beta App Review** (lighter, usually <24h).
- Purchases work in TestFlight via **sandbox** (free); the webhook still credits tokens/Pro — so friends can validate the full flow.

---

## 10. Submit
- [ ] Back on the version page → **Add for Review** → **Submit for Review**.
- [ ] Answer the export-compliance / content-rights / advertising-identifier prompts (IDFA: **No**).

---

## Rejection-risk checklist (already handled in the build ✅)
- ✅ No misleading feature claims (onboarding + paywall audited; "Collaborative Lounge", "unlimited itineraries", social push copy all fixed).
- ✅ Privacy manifest present (`PrivacyInfo.xcprivacy`).
- ✅ iPhone-only (no broken iPad layout, no iPad screenshots needed).
- ✅ Restore Purchases present (required for subs/non-consumables).
- ✅ Debug-only tools gated (`#if DEBUG`).
- ✅ Privacy Policy + Support pages live and reachable.

**Still on you to verify:**
- ⚠️ Image rights for destination/experience photos (§1 Content Rights).
- ⚠️ Every IAP has a review screenshot + is attached to the version (§7).
- ⚠️ Live `/support` page copy matches the app (no "unlimited itineraries").
