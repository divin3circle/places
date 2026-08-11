# Places Monetization Economy — Design Spec

**Date:** 2026-08-11
**Status:** Approved for planning (one open blocker: Stripe availability — see §2)
**Branch:** `feature/stripe-card-issuing`

## 1. Goal & context

Introduce a paid economy for Places (native SwiftUI iOS travel app; market Kenya/East Africa) built around a **web funnel** so it qualifies for the RevenueCat **Funnel Vision** bounty (judged on web payment volume through RevenueCat Funnels + Stripe).

Fixed decisions (not revisited here):

- Monetization runs through **RevenueCat Web Billing + Stripe** on a web landing page. The iOS app **links out** to this funnel to purchase; the app then honors the entitlement/balance. **No Apple in-app purchase for v1** (avoids the 30% cut and anti-steering rules; a web funnel linked from the app is App Store-compliant).
- One access entitlement: **`pro`** (free = absence of `pro`).
- Two purchase types: **subscriptions** (grant `pro` + a monthly token allotment) and **one-time consumable "app tokens"** (a spendable balance that pays for actions).

Grounding facts (read from the repo):

- `supabase/functions/generate-itinerary/index.ts` — the only real LLM cost. Model is **`gpt-4o-mini`**, one non-streaming call per action, strict-JSON output. Both `generate` and `refine` (iteration) hit the same endpoint; refine echoes the full prior itinerary back as input, so it costs slightly more.
- `supabase/functions/trip-intel/index.ts` — static lookup table, **zero** marginal cost; never billed.
- On-device backend (Apple Foundation Models) — marginal cost ≈ $0; gated to supported hardware.
- `profiles.plan text default 'free'` already exists in Supabase.
- No RevenueCat project exists for Places yet (greenfield).

## 2. Critical dependency — Stripe availability in Kenya ⚠️ (OPEN)

RevenueCat Web Billing charges through **your own Stripe account**. Stripe does not currently offer standard accounts to Kenya-based businesses. Since the bounty *requires* Stripe web payments, this gates the entire feature.

**Status: user to verify before Stripe-specific implementation begins.** Candidate paths, in order of preference:

1. **Stripe Atlas** — incorporate a US Delaware C-corp (~$500) for a fully-supported Stripe account. Cleanest; days–weeks + ongoing compliance.
2. **Existing supported entity** — attach Stripe to a business entity in a Stripe-supported country.
3. Confirm current Kenya availability directly with Stripe.

A merchant-of-record (Paddle/Lemon Squeezy) would sidestep Stripe but **likely disqualifies the bounty** — not pursued.

This design is written Stripe-first. If verification fails, the RevenueCat/Supabase/app layers still hold; only the payment processor changes.

## 3. Token unit economics

### 3.1 Real cost per cloud action (`gpt-4o-mini`)

Pricing assumption: **$0.15 / 1M input**, **$0.60 / 1M output** (OpenAI list, no prompt caching). "Medium" trip = 5 days × 3 activities = 15 activities.

| Call | Input tok | Output tok | Real cost |
|---|---|---|---|
| Generation (5-day) | ~450 | ~2,200 | $0.00139 |
| Iteration/refine (5-day) | ~2,600 | ~2,200 | $0.00171 |

Loaded ceilings used for margin math (≈2.5× mean, to absorb long trips/retries/model drift): **$0.004/cloud generation**, **$0.005/cloud iteration**. If the model is upgraded, re-run this table — structure holds, constant changes.

### 3.2 Value anchor

**1 token = $0.02 of retail value.** Chosen so a single generation is an impulse price (~$0.16) and a Pro 500-token grant reads as ~$10 of included value.

### 3.3 Action pricing (tokens) + margin

| Action | Tokens | Retail @ $0.02 | Real COGS | Gross margin |
|---|---|---|---|---|
| Cloud generation | **8** | $0.16 | $0.004 | ~97% |
| Cloud iteration | **5** | $0.10 | $0.005 | ~95% |
| Local generation | **2** | $0.04 | ~$0 | ~100% |
| Local iteration | **1** | $0.02 | ~$0 | ~100% |
| Border Pass (one multi-country plan) | **15** | $0.30 | $0.004 | ~99% |
| Offline maps (per region) | **25** | $0.50 | ~$0 | ~99% |
| Profile customization (future) | **10** each | $0.20 | ~$0 | ~100% |

Rationale: iteration is priced *below* generation (5 vs 8) despite marginally higher real cost — refining is the retention loop and drives web-payment volume. Local < cloud nudges capable hardware onto the free-to-us backend while still draining balance (habit + abuse control).

### 3.4 Token packs (à-la-carte top-ups)

USD list, KES at ~130 = $1 (FX is an open decision, §9):

| Pack | Tokens | USD | KES | $/token | Net margin (worst case, all-cloud-gen, after Stripe fee) |
|---|---|---|---|---|---|
| Starter | 25 | $0.99 | 129 | $0.0396 | 65% |
| Explorer | 75 | $2.49 | 324 | $0.0332 | 82% |
| Voyager | 200 | $5.99 | 779 | $0.0300 | 89% |
| Expedition | 500 | $12.99 | 1,689 | $0.0260 | 92% |

The Starter pack's margin is capped by Stripe's ~$0.30 intl fixed fee, **not** COGS — hence a **$0.99 SKU floor** and the "subscribe / buy bigger" gradient.

## 4. Subscription tiers

Four SKUs, no further sprawl:

| Plan | Product id | USD | KES | Tokens | Cadence |
|---|---|---|---|---|---|
| Trip Pass | `trip_pass_14d` | $4.99 | 649 | 120 once | 14-day access, **non-renewing** (inbound tourists) |
| Pro Monthly | `pro_monthly` | $6.99 | 899 | 500 / mo | recurring |
| Pro Annual | `pro_annual` | $59.99 | 7,799 | 500 / mo | recurring (~29% off) |
| **Pro Lifetime** | `pro_lifetime` | **$149.99** | **19,499** | **500 / mo (metered, forever)** | one-time |

**500 tokens/month is validated** as effectively-unlimited for real use (a genuine user would need ~15 heavily-refined trips/month to exhaust it) while staying **metered** so no pathological user can invert the margin. Worst-case Pro Monthly COGS: 500 × $0.001/token = $0.50 vs $6.99 revenue (~92% gross).

**Lifetime is metered, not unlimited** — grants `pro` forever + a recurring 500-token/month allotment (same as Monthly). This caps a lifetime user's worst-case cloud cost at ~$0.50/mo (~$6/yr). $149.99 ≈ 21 months of monthly; COGS payback is trivial, the trade-off is one-time revenue vs recurring LTV. If a lifetime user burns their 500, they buy a top-up like anyone else.

**Token rollover:** subscription-granted tokens roll over up to a **cap of 1,000** (2 months' grant), so lapse-then-renew isn't punished without unbounded accrual.

## 5. Free vs Pro feature matrix

| Capability | Free | Pro (Trip Pass / Monthly / Annual / Lifetime) |
|---|---|---|
| New-user grant | **15 tokens once** (activation seed) | n/a |
| Cloud generation | 8 tok/gen | Included, metered vs 500/mo |
| Cloud iteration | 5 tok/iter | Included, metered |
| Local generation | 2 tok/gen (hardware-gated) | Included, metered @2 |
| Multi-country planning | Locked → **Border Pass 15 tok** per trip | Included / unlimited |
| Offline maps | 25 tok/region | Included (fair-use for saved trips) |
| trip-intel context | Free (static) | Free |
| Profile customization (future) | 10 tok each | Included |
| Saved trips | Capped (e.g. 3 active) | Unlimited |
| Higher-tier cloud model (future option) | mini | Reserve routing option |
| Upsell nags | Standard | None |

Principle: Free is fully functional but à-la-carte — never hard-walled from the core magic. Pro converts pay-per-action anxiety into flat-fee + effectively-unlimited. Border Pass and offline maps are the clearest "taste of Pro" conversion drivers.

## 6. RevenueCat modeling (Web Billing)

Greenfield. New RC **project "Places"**, one **Web Billing app** (Stripe-connected).

- **Entitlement:** `pro` (presence = Pro). Attach `pro_monthly`, `pro_annual`, `pro_lifetime`, `trip_pass_14d`.
- **Virtual Currency:** one — `TOK` (Places Tokens). RevenueCat's consumable-economy primitive: per-customer balance, grants on subscription renewal, top-ups via one-time purchase, deduction on spend.
- **Products:**
  - Subs: `pro_monthly`, `pro_annual` → grant `pro` + 500 TOK/period.
  - `pro_lifetime` → grant `pro` permanently + 500 TOK/month recurring.
  - `trip_pass_14d` → non-renewing, grants `pro` for 14 days + 120 TOK once.
  - Top-ups: `tokens_25`, `tokens_75`, `tokens_200`, `tokens_500` → one-time, TOK grant only (no entitlement).
- **Offering:** `default` with packages `$rc_monthly`, `$rc_annual`, plus custom `lifetime`, `trip_pass`, `tokens_starter/explorer/voyager/expedition`. This is what the web paywall renders.

**Grant / spend flow:**

1. **Renewal** → Stripe renewal via RC → RC auto-grants 500 TOK → `RENEWAL` webhook → Supabase upserts `plan='pro'` + mirrors balance.
2. **Top-up** → Stripe one-time → RC grants pack TOK → `NON_RENEWING_PURCHASE` webhook → Supabase +credit.
3. **Spend** (user taps Generate) → app calls Supabase spend edge function → atomic Postgres debit (see §7) → invoke `generate-itinerary` → best-effort async RC VC deduct to reconcile. Debit **before** the LLM call; auto-refund on non-2xx.
4. **Refund/chargeback** → `CANCELLATION`/`REFUND` webhook → revoke `pro`, claw back unspent grant (§8).

RevenueCat = billing/entitlement source of truth; **Supabase = spendable-balance source of truth** (§7).

## 7. Supabase data model

Reuse `profiles.plan` (`'free' | 'pro' | 'trip_pass'`). Add:

- `profiles.pro_expires_at timestamptz` — Trip Pass window + period end; drives client gating before a webhook lands.
- `profiles.rc_customer_id text` — join RC → Supabase in webhooks.
- `token_balances` — `user_id PK, balance int not null default 0 check (balance >= 0), updated_at`. Live spendable balance.
- `token_ledger` — append-only: `id, user_id, delta int, reason text, ref text, created_at`. `reason ∈ {grant_sub, grant_topup, grant_signup, spend_gen, spend_iter, spend_border, spend_offline, refund_error, clawback_refund}`. Balance = Σ delta; auditable + anti-abuse analytics.
- `offline_regions text[]` on profile (owned downloads); optional `border_pass_credits int` if sold as stored credit (default model is immediate spend — §8).

**Source-of-truth choice:** Supabase authoritative for the *balance* (spend is on the generation hot path, already Supabase-routed; atomic Postgres debit is fast + transactional + offline-tolerant). RC VC kept eventually-consistent as the grant/audit ledger.

**RLS:** users `select` own balance/ledger, **never** `insert/update` — all mutations via `security definer` edge functions (webhook handler + spend function). Stops client-side tampering.

## 8. Abuse & edge cases

- **Endless free local gen:** local still costs 2 tok; after the 15-tok signup grant, free users must buy. Closes the "infinite free AI on supported hardware" hole.
- **Signup-grant farming:** 15 tok once per verified auth identity (email/Apple); small enough that farming isn't worth the friction.
- **Refund reverses a grant:** on `REFUND`/`CANCELLATION`, claw back the **unspent** portion — `balance = max(0, balance − granted)`, log `clawback_refund`. Never drive negative if already spent (COGS is pennies). Revoke `pro`/`pro_expires_at` immediately.
- **Offline maps refunded:** durable entitlement; remove region flag, app expires cached tiles next launch. Low stakes (~$0 marginal).
- **Token expiry:** sub-granted tokens **expire at period end** (rollover cap 1,000); **purchased top-up tokens never expire** (paid property; expiring invites chargebacks). Ledger `reason` distinguishes buckets so only the right one expires. On Pro lapse, purchased balance stays spendable at free-tier action prices.
- **Concurrent-spend race:** single atomic statement — `update token_balances set balance = balance − :cost where user_id = :u and balance >= :cost returning balance`; 0 rows → "insufficient tokens." Never read-then-write.
- **LLM failure after debit:** spend function debits, calls `generate-itinerary`, auto-refunds on non-2xx (`refund_error` row). No charge for failed generations.

## 9. Adopted policy defaults (confirmed)

- Pro is **metered 500**, not marketed as "unlimited."
- **15-token** one-time signup grant.
- Sub-granted tokens **expire monthly** (rollover cap 1,000); **purchased tokens never expire**.
- **Supabase-authoritative** balance; RC VC = grant ledger.
- **Border Pass = immediate 15-token spend** when a free user toggles multi-country (not a stored credit).
- Pricing **as recommended** (§3.4, §4).

## 10. Remaining open decisions

- **Stripe availability (§2)** — user to verify; top blocker.
- **Settlement currency / FX** — recommend charge **USD via Stripe**, display KES at a padded ~130 rate; or Stripe local presentment if KES settlement is available to the entity. Depends on §2 outcome.
- **Lifetime price** — $149.99 proposed; confirm at review.

## 11. Scope & implementation decomposition

This spec is the **economy design**. Implementation is large enough to split into **separate plans** (each independently shippable):

1. **RevenueCat + Stripe setup** — project, Web Billing app, entitlement, `TOK` virtual currency, products, offering, webhook integration. (Blocked on §2.)
2. **Web funnel** — landing → paywall → checkout page powered by RC Web Billing; the bounty surface (RevenueCat Funnels wired for analytics).
3. **Backend token ledger** — Supabase migration (tables + RLS), webhook handler edge function (grants/claws), spend edge function (atomic debit + auto-refund) wrapping `generate-itinerary`.
4. **iOS app wiring** — "Upgrade"/"Buy tokens" link-out to the funnel, entitlement + balance gating, token spend on generate/iterate, Border Pass toggle, offline-maps purchase, paywall/upsell surfaces.

Recommend building in order 3 → 1 → 2 → 4, with 1 unblocked once §2 resolves. `Wallets.swift` (the card-wallet UI) is **out of scope** for this economy work — a separate future product bet.
