# Places Monetization Economy — Design Spec

**Date:** 2026-08-11 (revised: switched from Stripe web funnel → Apple IAP)
**Status:** Approved for planning. RevenueCat scaffolding provisioned (see §6 / the setup guide).
**Branch:** `feature/stripe-card-issuing`
**Companion doc:** `docs/superpowers/guides/2026-08-11-revenuecat-appstoreconnect-iap-setup.md`

## 1. Goal & context

Introduce a paid economy for Places (native SwiftUI iOS travel app; market Kenya/East Africa) delivered through **Apple In-App Purchase (StoreKit) via the RevenueCat SDK**.

> **Note on the bounty:** an earlier draft targeted the RevenueCat *Funnel Vision* bounty, which requires **web** Stripe payment volume. We deliberately **dropped that path** — Stripe in Kenya was too uncertain — in favor of Apple IAP. IAP does **not** qualify for Funnel Vision; that award is out of scope.

Fixed decisions:

- Monetization is **Apple IAP** surfaced in-app via RevenueCat. No web funnel, no Stripe.
- Apple **auto-localizes** every price per storefront (KES in the Kenya store) from the base USD tier — no FX math on our side.
- We enroll in the **Apple Small Business Program** → **15%** commission (<$1M/yr), so margins stay ~85–95% given near-zero COGS.
- One access entitlement: **`pro`** (free = absence of `pro`).
- Two purchase types: **subscriptions** (grant `pro` + a token allotment) and **consumable "app tokens"** (a spendable balance).

Grounding facts (read from the repo):

- `supabase/functions/generate-itinerary/index.ts` — the only real LLM cost. Model **`gpt-4o-mini`**, one non-streaming call per action, strict-JSON output. `generate` and `refine` hit the same endpoint; refine echoes the full prior itinerary as input, so it costs slightly more.
- `supabase/functions/trip-intel/index.ts` — static lookup, **zero** marginal cost; never billed.
- On-device backend (Apple Foundation Models) — marginal cost ≈ $0; gated to supported hardware.
- `profiles.plan text default 'free'` already exists.
- App bundle id: **`com.sylusabel.Places`**.

## 2. Delivery: Apple IAP + RevenueCat

- Products are created in **App Store Connect** (subscriptions, consumables, non-consumable) and **imported/linked in RevenueCat** by matching product identifiers.
- The app uses the **RevenueCat SDK** (`Purchases`) to fetch the `default` offering, present the paywall, run purchases, and read the `pro` entitlement + `TOK` balance.
- Server truth is synced via **App Store Server Notifications → RevenueCat → a Supabase webhook** that maintains `profiles.plan` and the token ledger (§7).
- **No KES pricing table** in this spec — Apple derives local prices from the USD tier per storefront.

## 3. Token unit economics

### 3.1 Real cost per cloud action (`gpt-4o-mini`)

Assumption: **$0.15 / 1M input**, **$0.60 / 1M output** (OpenAI list, no caching). "Medium" trip = 5 days × 3 activities.

| Call | Input tok | Output tok | Real cost |
|---|---|---|---|
| Generation (5-day) | ~450 | ~2,200 | $0.00139 |
| Iteration/refine (5-day) | ~2,600 | ~2,200 | $0.00171 |

Loaded ceilings for margin math: **$0.004/cloud generation**, **$0.005/cloud iteration**. Re-run if the model changes.

### 3.2 Value anchor

**1 token ≈ $0.02 of value** (internal peg for action costs; not shown to users).

### 3.3 Action pricing (tokens) — unchanged by the pivot

| Action | Tokens | Real COGS | Gross margin |
|---|---|---|---|
| Cloud generation | **8** | $0.004 | ~97% |
| Cloud iteration | **5** | $0.005 | ~95% |
| Local generation | **2** | ~$0 | ~100% |
| Local iteration | **1** | ~$0 | ~100% |
| Border Pass (one multi-country plan) | **15** | $0.004 | ~99% |
| Offline maps (per region) | **25** | ~$0 | ~99% |
| Profile customization (future) | **10** each | ~$0 | ~100% |

50 tokens (a weekly grant) buys ~6 cloud generations or one heavily-refined trip — right-sized for a week.

### 3.4 Token packs (consumable IAP top-ups)

USD tiers (Apple localizes). Margin shown after Apple's 15% SBP cut, worst case = all tokens spent on cloud generation:

| Pack | Product id | Tokens | USD | Net after Apple 15% | Max COGS | Net margin |
|---|---|---|---|---|---|---|
| Starter | `tokens_25` | 25 | $0.99 | $0.84 | $0.013 | ~98% |
| Explorer | `tokens_75` | 75 | $1.99 | $1.69 | $0.038 | ~98% |
| Voyager | `tokens_200` | 200 | $4.49 | $3.82 | $0.100 | ~97% |
| Expedition | `tokens_500` | 500 | $9.99 | $8.49 | $0.250 | ~97% |

Purchased-pack tokens **never expire** (§9). $0.99 stays the floor — Apple's smallest standard tier.

## 4. Subscription tiers

Weekly / Monthly / Annual share one **subscription group** (`places_pro`); Lifetime is a **non-consumable**.

| Plan | Product id | Type | USD | Token grant |
|---|---|---|---|---|
| Weekly | `pro_weekly` | Auto-renewable (group `places_pro`) | **$1.49** | 50 / week |
| Monthly | `pro_monthly` | Auto-renewable | **$4.49** | 500 / month |
| Annual | `pro_annual` | Auto-renewable | **$39.99** | 500 / month (see §6 grant mechanics) |
| Lifetime | `pro_lifetime` | Non-consumable (one-time) | **$89.99** | 1000 / month (via scheduled job) |

Apple shows KES equivalents automatically in the Kenya storefront.

**Grant validation / cost safety:** all grants are metered, never "unlimited." Worst-case monthly COGS: Monthly 500 × $0.001 = $0.50 vs $4.49 (~85% gross after Apple); Lifetime 1000 × $0.001 = $1.00/mo forever vs a one-time $89.99 (~20 months' payback, then ~$12/yr max COGS — trivially safe). **Rollover cap 1,000** on subscription-granted tokens.

## 5. Free vs Pro feature matrix

| Capability | Free | Pro (any tier) |
|---|---|---|
| New-user grant | **15 tokens once** | n/a |
| Cloud generation | 8 tok/gen | Included, metered vs grant |
| Cloud iteration | 5 tok/iter | Included, metered |
| Local generation | 2 tok/gen (hardware-gated) | Included, metered @2 |
| Multi-country planning | Locked → **Border Pass 15 tok** per trip | Included / unlimited |
| Offline maps | 25 tok/region | Included (fair-use for saved trips) |
| trip-intel context | Free (static) | Free |
| Profile customization (future) | 10 tok each | Included |
| Saved trips | Capped (e.g. 3 active) | Unlimited |
| Upsell nags | Standard | None |

Free is fully functional but à-la-carte — never hard-walled from the core magic. Pro converts pay-per-action into flat-fee + effectively-unlimited.

## 6. RevenueCat modeling (Apple IAP) — PROVISIONED

Live objects created via the RevenueCat API (project **`projfd74cb43`**, app **`app9bae2fa48a`**, bundle `com.sylusabel.Places`):

- **Entitlement** `pro` (`entl99dc06fb33`) ← attached: `pro_weekly`, `pro_monthly`, `pro_annual`, `pro_lifetime`. Token packs are **not** attached (no entitlement).
- **Virtual Currency** `TOK` ("Places Tokens") with product grants:
  - `pro_weekly` → 50 (expire at cycle end)
  - `pro_monthly` → 500 (expire at cycle end)
  - `pro_annual` → **6,000** (expire at cycle end) — a full year's 500/mo granted up front each renewal, so annual needs **no** monthly job
  - `tokens_25/75/200/500` → 25/75/200/500 (**never expire**)
  - `pro_lifetime` → **no RC grant**; handled by the scheduled job below
- **Offering** `default` (`ofrng8ea8b8249e`, current) → 8 packages: `$rc_weekly`, `$rc_monthly`, `$rc_annual`, `$rc_lifetime`, `$rc_custom_tokens_25/75/200/500`, each linked to its product.

**Token-grant mechanics:**
- **Weekly / Monthly / Annual** — granted automatically by RevenueCat's Virtual Currency **product grants** on each purchase/renewal (annual front-loads the year).
- **Lifetime** — non-consumables don't renew, so a **scheduled Supabase job** (monthly cron) grants **1,000 TOK** to every active `pro_lifetime` holder. This is the only grant path RevenueCat can't automate.
- **Spend** — deducted from the Supabase-authoritative balance on the generation hot path (§7); reconciled to RevenueCat's VC balance best-effort.

**Sync flow:** App Store Server Notifications → RevenueCat → RevenueCat **webhook** (`INITIAL_PURCHASE`, `RENEWAL`, `NON_RENEWING_PURCHASE`, `CANCELLATION`, `EXPIRATION`, `PRODUCT_CHANGE`) → Supabase edge webhook handler updates `profiles.plan`, `pro_expires_at`, and mirrors token grants/claws into the ledger.

**Still required (user, in App Store Connect / RevenueCat dashboard):** create the 8 matching IAP products in App Store Connect, set prices, enroll in the Small Business Program, and add the **App Store Connect In-App Purchase key** + **App-Specific Shared Secret** to RevenueCat (`app_store_connect_api_key_configured` is currently `false`). Covered step-by-step in the companion guide.

## 7. Supabase data model

Reuse `profiles.plan` (`'free' | 'pro'`). Add:

- `profiles.pro_expires_at timestamptz` — period/lifetime gating before a webhook lands.
- `profiles.rc_customer_id text` — join RevenueCat → Supabase in webhooks.
- `profiles.plan_product text` — which product is active (`pro_weekly`…`pro_lifetime`), so the lifetime job can target holders.
- `token_balances` — `user_id PK, balance int not null default 0 check (balance >= 0), updated_at`. Live spendable balance (source of truth).
- `token_ledger` — append-only: `id, user_id, delta int, reason text, ref text, created_at`. `reason ∈ {grant_weekly, grant_monthly, grant_annual, grant_lifetime, grant_topup, grant_signup, spend_gen, spend_iter, spend_border, spend_offline, refund_error, clawback_refund, expire_cycle}`. Balance = Σ delta; auditable.
- `offline_regions text[]` on profile (owned downloads).

**Source of truth:** Supabase authoritative for the *balance* (atomic Postgres debit on the hot path); RevenueCat VC is the grant/audit ledger, reconciled async.

**RLS:** users `select` own balance/ledger, never `insert/update` — all mutations via `security definer` edge functions (webhook handler, spend function, lifetime grant job).

## 8. Abuse & edge cases

- **Endless free local gen:** local still costs 2 tok; after the 15-tok signup grant, free users must buy.
- **Signup-grant farming:** 15 tok once per verified auth identity (email/Apple).
- **Refund/chargeback:** RevenueCat `CANCELLATION`/refund webhook → revoke `pro`, claw back **unspent** grant (`balance = max(0, balance − granted)`, log `clawback_refund`); never drive negative.
- **Token expiry:** subscription-granted tokens expire at period end (rollover cap 1,000); **purchased top-up tokens never expire**. Ledger `reason` distinguishes buckets.
- **Concurrent-spend race:** single atomic statement — `update token_balances set balance = balance − :cost where user_id = :u and balance >= :cost returning balance`; 0 rows → "insufficient tokens."
- **LLM failure after debit:** spend function debits, calls `generate-itinerary`, auto-refunds on non-2xx (`refund_error`).
- **Lifetime double-grant guard:** the monthly job must be idempotent per (user, month) — key on a `granted_period` marker in the ledger so a re-run doesn't double-credit.

## 9. Adopted policy defaults (confirmed)

- Pro is **metered**, not "unlimited."
- **15-token** one-time signup grant.
- Subscription tokens **expire at period end** (rollover cap 1,000); **purchased tokens never expire**.
- **Supabase-authoritative** balance; RevenueCat VC = grant ledger.
- **Border Pass = immediate 15-token spend** when a free user toggles multi-country.
- Pricing **as confirmed** (§3.4, §4): Weekly $1.49 / Monthly $4.49 / Annual $39.99 / Lifetime $89.99; packs $0.99–$9.99.

## 10. Remaining open decisions

- Confirm **Lifetime $89.99** and **annual token model** (6,000 up-front/yr vs a monthly job — spec uses up-front).
- Free trial / intro offer on Weekly or Monthly? (Not designed yet — a fast-follow.)

## 11. Scope & implementation decomposition

Economy design only. Implementation splits into independently shippable plans:

1. **App Store Connect + RevenueCat linking** — create the 8 IAP products, prices, subscription group, Small Business Program, ASC key + shared secret into RevenueCat, StoreKit config file for local testing. (See companion guide; largely a runbook, minimal code.)
2. **Backend token ledger** — Supabase migration (tables + RLS), RevenueCat webhook handler edge function (grants/claws), spend edge function (atomic debit + auto-refund) wrapping `generate-itinerary`, lifetime monthly grant cron. **No Apple dependency — can start now.**
3. **iOS RevenueCat integration** — SDK init + identity link to Supabase user, entitlement + balance gating, paywall (RevenueCat Paywalls or custom), token spend on generate/iterate, Border Pass toggle, offline-maps purchase, "buy tokens"/"go Pro" surfaces, restore purchases.

Recommend order **2 → 1 → 3**. `Wallets.swift` (card-wallet UI) remains **out of scope** — a separate future product bet.
