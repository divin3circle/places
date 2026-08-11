# RevenueCat ↔ App Store Connect — IAP Setup & Submission Guide

A runbook for wiring the Places token economy through Apple In-App Purchase and RevenueCat, and getting the IAPs approved **with your app submission**. Follow top to bottom.

**Design reference:** `docs/superpowers/specs/2026-08-11-monetization-economy-design.md`

## What's already done (via the RevenueCat API)

The RevenueCat side is **provisioned**. You do NOT need to recreate any of this — you just mirror the product IDs in App Store Connect and connect the two.

| RevenueCat object | Value / id |
|---|---|
| Project | `Places` — `projfd74cb43` |
| App | `Places iOS` — `app9bae2fa48a` (bundle `com.sylusabel.Places`) |
| Entitlement | `pro` — `entl99dc06fb33` (unlocks on any subscription or lifetime) |
| Virtual currency | `TOK` — "Places Tokens", with per-product grant rules |
| Offering | `default` — `ofrng8ea8b8249e` (current), 8 packages |

**Product identifiers (must match EXACTLY in App Store Connect):**

| Product ID | Apple product type | Price (USD tier) | RC package |
|---|---|---|---|
| `pro_weekly` | Auto-renewable subscription | $1.49 | `$rc_weekly` |
| `pro_monthly` | Auto-renewable subscription | $4.49 | `$rc_monthly` |
| `pro_annual` | Auto-renewable subscription | $39.99 | `$rc_annual` |
| `pro_lifetime` | Non-consumable | $89.99 | `$rc_lifetime` |
| `tokens_25` | Consumable | $0.99 | `$rc_custom_tokens_25` |
| `tokens_75` | Consumable | $1.99 | `$rc_custom_tokens_75` |
| `tokens_200` | Consumable | $4.49 | `$rc_custom_tokens_200` |
| `tokens_500` | Consumable | $9.99 | `$rc_custom_tokens_500` |

> Product IDs are **permanent** in App Store Connect — you can't rename or reuse them. Type them carefully.

---

## Step 0 — Prerequisites (App Store Connect)

1. Paid **Apple Developer Program** membership, active.
2. In **App Store Connect → Business**: sign the **Paid Applications Agreement** and complete **banking + tax** info. **IAPs won't work — not even in sandbox review — until this agreement is Active.**
3. An **app record** exists for `com.sylusabel.Places` (App Store Connect → Apps → +). It can be in "Prepare for Submission"; it doesn't need to be live.

## Step 1 — Enroll in the Small Business Program (15% instead of 30%)

App Store Connect → **Business → App Store Small Business Program → Enroll.** Approval takes a day or two and cuts Apple's commission to 15% for you (<$1M/yr). Do this early; it's the difference the economy assumes.

## Step 2 — Create the subscription group + 3 subscriptions

App Store Connect → your app → **Monetization → Subscriptions**.

1. **Create a Subscription Group** named `places_pro` (users can only hold one subscription from a group at a time — correct here, since Weekly/Monthly/Annual are mutually exclusive).
2. Inside the group, **create three auto-renewable subscriptions** with these exact **Product IDs** and durations:
   - `pro_weekly` — duration **1 Week** — Reference Name "Pro Weekly"
   - `pro_monthly` — duration **1 Month** — "Pro Monthly"
   - `pro_annual` — duration **1 Year** — "Pro Annual"
3. For each: set **price** (choose the USD tier from the table; Apple auto-generates KES and every other storefront), add a **localized display name + description** (English at minimum), and a **subscription-group display name**.
4. Each subscription needs a **review screenshot** of the paywall (add once the app UI exists — see Step 8) and passes review the first time **alongside the app version**.

## Step 3 — Create the non-consumable (Lifetime)

Monetization → **In-App Purchases → +** → **Non-Consumable**:
- Product ID `pro_lifetime`, Reference Name "Pro Lifetime", price tier **$89.99**, localized name/description, review screenshot.

## Step 4 — Create the 4 consumables (token packs)

Monetization → **In-App Purchases → +** → **Consumable** (×4):
- `tokens_25` ($0.99), `tokens_75` ($1.99), `tokens_200` ($4.49), `tokens_500` ($9.99), each with reference name, price tier, localized name/description, review screenshot.

## Step 5 — Generate the credentials RevenueCat needs

RevenueCat currently reports `app_store_connect_api_key_configured: false`. Fix that:

1. **In-App Purchase key (App Store Connect API key, IAP-scoped):**
   App Store Connect → **Users and Access → Integrations → In-App Purchase** → **Generate In-App Purchase Key**. Download the `.p8` **once** (it's not re-downloadable), and note the **Key ID** and your **Issuer ID**.
2. **App-Specific Shared Secret:**
   Your app → **App Information → App-Specific Shared Secret** → generate/copy. (Used to validate StoreKit receipts.)
3. Note your **Vendor Number** (App Store Connect → Payments and Financial Reports) — RevenueCat uses it for financial reconciliation.

## Step 6 — Connect the credentials to RevenueCat

RevenueCat dashboard → **Project "Places" → Apps → "Places iOS" → App Store configuration**:
- Upload the **In-App Purchase `.p8` key** (+ Key ID, Issuer ID).
- Paste the **App-Specific Shared Secret**.
- Enter the **Vendor Number**.

Once saved, RevenueCat can read your App Store Connect products and validate receipts. `app_store_connect_api_key_configured` flips to `true`.

## Step 7 — Verify product linking

In RevenueCat the 8 products already exist with the matching store identifiers, so once Step 6 is done RevenueCat will **auto-associate** them with the App Store Connect products by identifier. Verify in **Product catalog** that each of the 8 shows the App Store price and "Ready"/linked status. If any shows "not found," the App Store Connect Product ID doesn't match exactly — fix the typo in App Store Connect (RC IDs are correct).

Nothing to rebuild in RevenueCat: the entitlement `pro`, the `TOK` grants, the `default` offering, and its packages are already configured.

## Step 8 — App-side integration (summary; see spec §11 plan 3)

1. Add the **RevenueCat SDK** (`RevenueCat` via SPM). Initialize with the app's **public SDK key** (RevenueCat → API keys) at launch.
2. **Identify the user**: call `Purchases.shared.logIn(<your Supabase user id>)` so web/app/webhook all share one RevenueCat customer — critical for the token balance and entitlement to follow the user.
3. Fetch `Offerings.current` (= `default`) and render the paywall (RevenueCat Paywalls, or your own SwiftUI over the packages).
4. Gate features on `customerInfo.entitlements["pro"].isActive`; read the token balance via the **virtual currency** API (or your Supabase mirror).
5. Add a **Restore Purchases** button (Apple requires it for non-consumables/subscriptions).
6. Take **paywall screenshots** from the running app → upload as the IAP review screenshots in Steps 2–4.

## Step 9 — App Store Server Notifications → RevenueCat webhook

App Store Connect → your app → **App Information → App Store Server Notifications**:
- Set the **Production** and **Sandbox** URLs to the RevenueCat notification URL shown in **RevenueCat → App Store configuration** (RevenueCat gives you the exact URL). Use **Version 2** notifications.

This lets renewals/refunds reach RevenueCat server-to-server, which then fires the RevenueCat **webhook** to your Supabase handler (spec §6/§7) to keep `profiles.plan` and the token ledger correct.

## Step 10 — Submit the IAPs WITH the app (the actual "connect at submission" step)

This is the part people miss: **first-time IAPs are reviewed together with an app version.**

1. In App Store Connect → your app → the **version** you're submitting → scroll to **In-App Purchases and Subscriptions** → **add all 8** products to the version. (A version with new IAPs that aren't attached will get them reviewed separately/late.)
2. In **App Review Information** for the version, add **notes** explaining the token economy and how the reviewer reaches the paywall (e.g. "Tap Profile → Go Pro, or tap Generate when out of tokens"). Provide a **demo account** if sign-in is required.
3. Ensure each IAP's **review screenshot** shows the paywall/where it's purchased.
4. Make sure the **Paid Applications Agreement is Active** (Step 0.2) — otherwise IAPs are silently unavailable and review bounces.
5. Submit. Apple reviews the binary + the 8 IAPs together. On approval they go live with the version.

## Step 11 — Sandbox testing before submission

1. App Store Connect → **Users and Access → Sandbox → Test Accounts** → create a sandbox Apple ID (use a non-real email).
2. On a device/simulator, sign into the **sandbox** account (Settings → Developer, or you'll be prompted at purchase).
3. Run the app, buy each product, confirm: `pro` entitlement activates, the correct **TOK** grant lands, packs stack, restore works, and a sandbox renewal (subscriptions renew fast in sandbox) grants tokens again.
4. Optionally add a **StoreKit configuration file** in Xcode for offline local testing before sandbox.

## Quick reference — grant rules already configured in RevenueCat

| On purchase/renewal of | TOK granted | Expires at cycle end? |
|---|---|---|
| `pro_weekly` | 50 | yes |
| `pro_monthly` | 500 | yes |
| `pro_annual` | 6,000 (a year of 500/mo, up front) | yes |
| `pro_lifetime` | — (granted 1,000/mo by a Supabase cron; see spec §6) | n/a |
| `tokens_25/75/200/500` | 25/75/200/500 | **never** |

## Outstanding (not automatable via API — you must do in the dashboards)

- [ ] Paid Applications Agreement active + banking/tax (Step 0)
- [ ] Small Business Program enrollment (Step 1)
- [ ] Create the 8 IAP products in App Store Connect with the exact IDs + prices (Steps 2–4)
- [ ] Generate + upload the IAP key, shared secret, vendor number to RevenueCat (Steps 5–6)
- [ ] Verify linking (Step 7)
- [ ] Set App Store Server Notification URLs (Step 9)
- [ ] Add IAPs to the app version + review notes + submit (Step 10)
