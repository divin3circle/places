# Token Ledger Backend Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Supabase-authoritative token economy backbone — balance + ledger tables, atomic grant/spend functions, signup grant, cloud-generation debit, RevenueCat webhook sync, and the lifetime monthly grant cron — so the app and RevenueCat can transact tokens safely.

**Architecture:** A single Postgres balance table (`token_balances`) with an append-only audit `token_ledger`, mutated only through `security definer` RPCs (`grant_tokens`, `spend_tokens`) that enforce atomicity and non-negative balance. The existing `generate-itinerary` edge function debits before calling OpenAI and refunds on failure. A new `revenuecat-webhook` edge function turns purchase/renewal/refund events into grants/claws and maintains `profiles.plan`. A `pg_cron` job grants lifetime holders their monthly allotment idempotently.

**Tech Stack:** Supabase Postgres (plpgsql, RLS, pg_cron), Supabase Edge Functions (Deno/TypeScript), pgTAP for SQL tests, `deno test` for pure TS helpers.

## Global Constraints

- Supabase project ref: **`bwafaffjhaxclcmrjhdg`** (project "Places").
- Balance source of truth is **Supabase**; RevenueCat Virtual Currency is the grant/audit mirror. The app reads the Supabase balance.
- All ledger/balance mutations go through `security definer` functions only. RLS grants users **select** on their own rows and **no** insert/update/delete.
- Ledger `reason ∈ {grant_weekly, grant_monthly, grant_annual, grant_lifetime, grant_topup, grant_signup, spend_gen, spend_iter, spend_border, spend_offline, refund_error, clawback_refund}`.
- Action costs (tokens): cloud generation **8**, cloud iteration **5**, local generation **2**, local iteration **1**, Border Pass **15**, offline maps **25**.
- Grant amounts: signup **15**; `pro_weekly` **50**, `pro_monthly` **500**, `pro_annual` **6000**, `pro_lifetime` **1000/mo**; packs `tokens_25/75/200/500` → **25/75/200/500**.
- Subscription-granted tokens expire at cycle end (tracked by reason bucket); purchased-pack tokens never expire.
- `profiles.id uuid` is the PK and equals `auth.users.id` (from Phase 1). A `handle_new_user()` trigger already inserts a `profiles` row on signup.
- Migrations are version-controlled under `supabase/migrations/` **and** applied to the remote project (via the Supabase MCP `apply_migration` or `supabase db push`). Tests live under `supabase/tests/` and run with `supabase test db`.

---

## Task 1: Schema — balance, ledger, profile columns, RLS

**Files:**
- Create: `supabase/migrations/20260811090000_token_ledger_schema.sql`
- Test: `supabase/tests/token_schema_test.sql`

**Interfaces:**
- Produces: tables `public.token_balances(user_id uuid pk, balance int, updated_at timestamptz)`, `public.token_ledger(id bigint pk, user_id uuid, delta int, reason text, ref text, created_at timestamptz)`; new `public.profiles` columns `pro_expires_at timestamptz`, `rc_customer_id text`, `plan_product text`.

- [ ] **Step 1: Write the failing test**

`supabase/tests/token_schema_test.sql`:
```sql
begin;
select plan(6);

select has_table('public', 'token_balances', 'token_balances exists');
select has_table('public', 'token_ledger', 'token_ledger exists');
select has_column('public', 'profiles', 'pro_expires_at', 'profiles.pro_expires_at exists');
select has_column('public', 'profiles', 'plan_product', 'profiles.plan_product exists');

-- RLS is enabled on both tables
select is(relrowsecurity, true, 'RLS on token_balances')
  from pg_class where relname = 'token_balances';
select is(relrowsecurity, true, 'RLS on token_ledger')
  from pg_class where relname = 'token_ledger';

select * from finish();
rollback;
```

- [ ] **Step 2: Run test to verify it fails**

Run: `supabase test db`
Expected: FAIL — relations/columns do not exist yet.

- [ ] **Step 3: Write the migration**

`supabase/migrations/20260811090000_token_ledger_schema.sql`:
```sql
alter table public.profiles
  add column if not exists pro_expires_at timestamptz,
  add column if not exists rc_customer_id text,
  add column if not exists plan_product text;

create table if not exists public.token_balances (
  user_id uuid primary key references auth.users(id) on delete cascade,
  balance int not null default 0 check (balance >= 0),
  updated_at timestamptz not null default now()
);

create table if not exists public.token_ledger (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  delta int not null,
  reason text not null,
  ref text,
  created_at timestamptz not null default now()
);
create index if not exists token_ledger_user_idx
  on public.token_ledger(user_id, created_at desc);

alter table public.token_balances enable row level security;
alter table public.token_ledger enable row level security;

create policy "own balance read" on public.token_balances
  for select using (auth.uid() = user_id);
create policy "own ledger read" on public.token_ledger
  for select using (auth.uid() = user_id);
-- Intentionally no insert/update/delete policies: only SECURITY DEFINER
-- functions (Tasks 2-3) mutate these tables.
```

- [ ] **Step 4: Apply + run test to verify it passes**

Run: `supabase db push` (or MCP `apply_migration` with this SQL), then `supabase test db`
Expected: PASS (6/6).

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260811090000_token_ledger_schema.sql supabase/tests/token_schema_test.sql
git commit -m "feat(tokens): balance + ledger schema with RLS"
```

---

## Task 2: Atomic grant/spend functions

**Files:**
- Create: `supabase/migrations/20260811091000_token_functions.sql`
- Test: `supabase/tests/token_functions_test.sql`

**Interfaces:**
- Produces:
  - `public.grant_tokens(p_user uuid, p_amount int, p_reason text, p_ref text default null) returns int` — upserts balance += amount, appends a `+amount` ledger row, returns new balance. Raises if `p_amount <= 0`.
  - `public.spend_tokens(p_user uuid, p_cost int, p_reason text, p_ref text default null) returns int` — atomically decrements iff `balance >= p_cost`, appends `-p_cost` ledger row, returns new balance. Raises `insufficient_tokens` (SQLSTATE P0001) when the balance is too low; raises if `p_cost <= 0`. **Service-role only** (edge functions).
  - `public.spend_my_tokens(p_cost int, p_reason text, p_ref text default null) returns int` — the client-safe wrapper; forces the spender to `auth.uid()` so an authenticated user can only ever debit their **own** balance. Granted to `authenticated` for the app's local-gen / Border Pass / offline-maps spends.

- [ ] **Step 1: Write the failing test**

`supabase/tests/token_functions_test.sql`:
```sql
begin;
select plan(7);

-- seed a fake user id (bypass auth.users FK for the test via a local row)
insert into auth.users (id, email) values ('00000000-0000-0000-0000-000000000001', 't@t.co')
  on conflict do nothing;
\set u '00000000-0000-0000-0000-000000000001'

select is(public.grant_tokens(:'u', 100, 'grant_signup', null), 100, 'grant sets 100');
select is(public.grant_tokens(:'u', 50, 'grant_topup', 'pack1'), 150, 'grant accumulates to 150');
select is(public.spend_tokens(:'u', 40, 'spend_gen', 'itin1'), 110, 'spend leaves 110');

select throws_ok(
  $$ select public.spend_tokens('00000000-0000-0000-0000-000000000001', 999, 'spend_gen', null) $$,
  'insufficient_tokens', 'overspend raises insufficient_tokens');

select is((select balance from public.token_balances where user_id = :'u'), 110,
  'balance unchanged after failed overspend');

select is((select count(*)::int from public.token_ledger where user_id = :'u'), 3,
  'ledger has 3 rows (2 grants + 1 spend)');

select throws_ok(
  $$ select public.grant_tokens('00000000-0000-0000-0000-000000000001', 0, 'grant_topup', null) $$,
  null, 'non-positive grant raises');

select * from finish();
rollback;
```

- [ ] **Step 2: Run test to verify it fails**

Run: `supabase test db`
Expected: FAIL — functions do not exist.

- [ ] **Step 3: Write the migration**

`supabase/migrations/20260811091000_token_functions.sql`:
```sql
create or replace function public.grant_tokens(
  p_user uuid, p_amount int, p_reason text, p_ref text default null
) returns int
language plpgsql security definer set search_path = public as $$
declare v_balance int;
begin
  if p_amount is null or p_amount <= 0 then
    raise exception 'amount must be positive';
  end if;
  insert into public.token_balances(user_id, balance)
    values (p_user, p_amount)
    on conflict (user_id) do update
      set balance = public.token_balances.balance + p_amount,
          updated_at = now()
    returning balance into v_balance;
  insert into public.token_ledger(user_id, delta, reason, ref)
    values (p_user, p_amount, p_reason, p_ref);
  return v_balance;
end; $$;

create or replace function public.spend_tokens(
  p_user uuid, p_cost int, p_reason text, p_ref text default null
) returns int
language plpgsql security definer set search_path = public as $$
declare v_balance int;
begin
  if p_cost is null or p_cost <= 0 then
    raise exception 'cost must be positive';
  end if;
  update public.token_balances
    set balance = balance - p_cost, updated_at = now()
    where user_id = p_user and balance >= p_cost
    returning balance into v_balance;
  if not found then
    raise exception 'insufficient_tokens' using errcode = 'P0001';
  end if;
  insert into public.token_ledger(user_id, delta, reason, ref)
    values (p_user, -p_cost, p_reason, p_ref);
  return v_balance;
end; $$;

-- Client-safe wrapper: an authenticated user can only debit their OWN balance.
-- (spend_tokens takes an explicit p_user, so it must NOT be exposed to clients —
-- otherwise one user could pass another's id and drain them.)
create or replace function public.spend_my_tokens(
  p_cost int, p_reason text, p_ref text default null
) returns int
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'not_authenticated'; end if;
  return public.spend_tokens(auth.uid(), p_cost, p_reason, p_ref);
end; $$;

-- grant_tokens and spend_tokens are service-role only (edge functions).
revoke all on function public.grant_tokens(uuid, int, text, text) from public, anon, authenticated;
revoke all on function public.spend_tokens(uuid, int, text, text) from public, anon, authenticated;
grant execute on function public.spend_my_tokens(int, text, text) to authenticated;
```

- [ ] **Step 4: Apply + run test to verify it passes**

Run: `supabase db push` (or MCP `apply_migration`), then `supabase test db`
Expected: PASS (7/7).

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260811091000_token_functions.sql supabase/tests/token_functions_test.sql
git commit -m "feat(tokens): atomic grant_tokens + spend_tokens RPCs"
```

---

## Task 3: Signup grant trigger

**Files:**
- Create: `supabase/migrations/20260811092000_signup_grant.sql`
- Test: `supabase/tests/signup_grant_test.sql`

**Interfaces:**
- Consumes: `public.grant_tokens` (Task 2).
- Produces: an `after insert on public.profiles` trigger that grants **15** tokens once with reason `grant_signup`.

- [ ] **Step 1: Write the failing test**

`supabase/tests/signup_grant_test.sql`:
```sql
begin;
select plan(2);

insert into auth.users (id, email) values ('00000000-0000-0000-0000-000000000002', 's@s.co')
  on conflict do nothing;
insert into public.profiles (id, name, email)
  values ('00000000-0000-0000-0000-000000000002', 'Sam', 's@s.co');

select is((select balance from public.token_balances
           where user_id = '00000000-0000-0000-0000-000000000002'), 15,
  'new profile is granted 15 tokens');
select is((select count(*)::int from public.token_ledger
           where user_id = '00000000-0000-0000-0000-000000000002'
             and reason = 'grant_signup'), 1,
  'exactly one signup grant row');

select * from finish();
rollback;
```

- [ ] **Step 2: Run test to verify it fails**

Run: `supabase test db`
Expected: FAIL — no balance row created on profile insert.

- [ ] **Step 3: Write the migration**

`supabase/migrations/20260811092000_signup_grant.sql`:
```sql
create or replace function public.grant_signup_tokens() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  perform public.grant_tokens(new.id, 15, 'grant_signup', null);
  return new;
end; $$;

drop trigger if exists on_profile_created_grant_tokens on public.profiles;
create trigger on_profile_created_grant_tokens
  after insert on public.profiles
  for each row execute function public.grant_signup_tokens();
```

- [ ] **Step 4: Apply + run test to verify it passes**

Run: `supabase db push`, then `supabase test db`
Expected: PASS (2/2).

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260811092000_signup_grant.sql supabase/tests/signup_grant_test.sql
git commit -m "feat(tokens): grant 15 tokens on profile creation"
```

---

## Task 4: Cloud-generation debit in `generate-itinerary`

**Files:**
- Create: `supabase/functions/_shared/cost.ts`
- Create: `supabase/functions/_shared/cost_test.ts`
- Modify: `supabase/functions/generate-itinerary/index.ts` (add auth + debit/refund around the OpenAI call)

**Interfaces:**
- Consumes: `public.spend_tokens`, `public.grant_tokens` (via service-role Supabase client).
- Produces: `costForAction(mode: "generate" | "refine", backend: "cloud" | "local"): number`. The function now returns HTTP **402** `{ error: "insufficient_tokens" }` when the caller can't afford the generation, and refunds on OpenAI failure.

- [ ] **Step 1: Write the failing test (pure cost helper)**

`supabase/functions/_shared/cost_test.ts`:
```ts
import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { costForAction } from "./cost.ts";

Deno.test("cloud generation costs 8", () => {
  assertEquals(costForAction("generate", "cloud"), 8);
});
Deno.test("cloud iteration costs 5", () => {
  assertEquals(costForAction("refine", "cloud"), 5);
});
Deno.test("local generation costs 2", () => {
  assertEquals(costForAction("generate", "local"), 2);
});
Deno.test("local iteration costs 1", () => {
  assertEquals(costForAction("refine", "local"), 1);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `deno test supabase/functions/_shared/cost_test.ts`
Expected: FAIL — `cost.ts` does not exist.

- [ ] **Step 3: Write the cost helper**

`supabase/functions/_shared/cost.ts`:
```ts
export type Mode = "generate" | "refine";
export type Backend = "cloud" | "local";

/** Token cost for an AI action. Cloud is the paid path; local is near-free. */
export function costForAction(mode: Mode, backend: Backend): number {
  if (backend === "local") return mode === "generate" ? 2 : 1;
  return mode === "generate" ? 8 : 5;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `deno test supabase/functions/_shared/cost_test.ts`
Expected: PASS (4/4).

- [ ] **Step 5: Wire the debit into `generate-itinerary`**

In `supabase/functions/generate-itinerary/index.ts`, add imports at the top:
```ts
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { costForAction } from "../_shared/cost.ts";
```
Immediately after the `body` is validated (after the `Missing config or placeNames` guard, before building `openaiBody`), insert:
```ts
  // --- Token debit (cloud generation) ---
  const authHeader = req.headers.get("Authorization") ?? "";
  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  const { data: userData, error: userErr } = await admin.auth.getUser(
    authHeader.replace("Bearer ", ""),
  );
  if (userErr || !userData?.user) return json({ error: "Unauthorized" }, 401);
  const userId = userData.user.id;

  const cost = costForAction(body.mode, "cloud");
  const reason = body.mode === "refine" ? "spend_iter" : "spend_gen";
  const { error: spendErr } = await admin.rpc("spend_tokens", {
    p_user: userId, p_cost: cost, p_reason: reason, p_ref: null,
  });
  if (spendErr) {
    // P0001 = insufficient_tokens raised by spend_tokens
    if (spendErr.message?.includes("insufficient_tokens")) {
      return json({ error: "insufficient_tokens" }, 402);
    }
    return json({ error: `Token debit failed: ${spendErr.message}` }, 500);
  }
```
Then, at BOTH OpenAI failure return sites (the `catch` after `fetch`, and the `if (!res.ok)` block, and the malformed-JSON / no-content guards), refund before returning. Replace each of those error returns so they first run:
```ts
    await admin.rpc("grant_tokens", {
      p_user: userId, p_amount: cost, p_reason: "refund_error", p_ref: null,
    });
```
Concretely, change the `if (!res.ok) { ... }` block to:
```ts
  if (!res.ok) {
    const text = await res.text();
    await admin.rpc("grant_tokens", {
      p_user: userId, p_amount: cost, p_reason: "refund_error", p_ref: null,
    });
    return json({ error: `OpenAI error ${res.status}: ${text}` }, 502);
  }
```
and apply the same refund line inside the `catch (e)` for the fetch, the `typeof content !== "string"` guard, and the `JSON.parse` catch.

- [ ] **Step 6: Deploy + integration verify**

Run:
```bash
supabase functions deploy generate-itinerary --project-ref bwafaffjhaxclcmrjhdg
```
Verify with a real user JWT (grab one from the app or `supabase auth`):
```bash
# 1. Insufficient path: a fresh user with <8 tokens → 402
curl -s -X POST "https://bwafaffjhaxclcmrjhdg.supabase.co/functions/v1/generate-itinerary" \
  -H "Authorization: Bearer $USER_JWT" -H "apikey: $ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"mode":"generate","config":{"travelers":2,"hasKids":false,"durationDays":3,"durationLabel":"3 days","multipleCountries":false,"expectation":""},"placeNames":["Maasai Mara"]}'
# Expect: {"error":"insufficient_tokens"} with HTTP 402 when balance < 8
```
Then grant the test user 100 tokens (`select grant_tokens('<uid>',100,'grant_topup','manual')` via MCP `execute_sql`), repeat the call, and confirm HTTP 200 + the balance dropped by 8 (`select balance from token_balances where user_id='<uid>'`).

Expected: 402 when poor, 200 + balance −8 when funded.

- [ ] **Step 7: Commit**

```bash
git add supabase/functions/_shared/cost.ts supabase/functions/_shared/cost_test.ts supabase/functions/generate-itinerary/index.ts
git commit -m "feat(tokens): debit cloud generation, refund on failure"
```

---

## Task 5: RevenueCat webhook handler

**Files:**
- Create: `supabase/functions/revenuecat-webhook/index.ts`
- Create: `supabase/functions/_shared/grants.ts`
- Create: `supabase/functions/_shared/grants_test.ts`

**Interfaces:**
- Consumes: `public.grant_tokens`, `public.spend_tokens`; `profiles` columns from Task 1.
- Produces: `grantForProduct(productId: string): { amount: number; reason: string } | null` and `planForProduct(productId: string): string | null`; an HTTP endpoint that authenticates via the `Authorization` header equal to `REVENUECAT_WEBHOOK_AUTH`, and on purchase/renewal grants tokens + sets `profiles.plan`/`plan_product`/`pro_expires_at`/`rc_customer_id`, and on refund/cancellation revokes.

- [ ] **Step 1: Write the failing test (pure mapping)**

`supabase/functions/_shared/grants_test.ts`:
```ts
import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { grantForProduct, planForProduct } from "./grants.ts";

Deno.test("weekly grants 50", () => {
  assertEquals(grantForProduct("pro_weekly"), { amount: 50, reason: "grant_weekly" });
});
Deno.test("annual grants 6000", () => {
  assertEquals(grantForProduct("pro_annual"), { amount: 6000, reason: "grant_annual" });
});
Deno.test("token pack grants its size", () => {
  assertEquals(grantForProduct("tokens_200"), { amount: 200, reason: "grant_topup" });
});
Deno.test("lifetime grants 1000", () => {
  assertEquals(grantForProduct("pro_lifetime"), { amount: 1000, reason: "grant_lifetime" });
});
Deno.test("unknown product → null", () => {
  assertEquals(grantForProduct("nope"), null);
});
Deno.test("subscription products map to pro plan", () => {
  assertEquals(planForProduct("pro_monthly"), "pro");
  assertEquals(planForProduct("tokens_25"), null);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `deno test supabase/functions/_shared/grants_test.ts`
Expected: FAIL — `grants.ts` does not exist.

- [ ] **Step 3: Write the mapping helper**

`supabase/functions/_shared/grants.ts`:
```ts
const TOKEN_PACKS: Record<string, number> = {
  tokens_25: 25, tokens_75: 75, tokens_200: 200, tokens_500: 500,
};
const SUB_GRANTS: Record<string, { amount: number; reason: string }> = {
  pro_weekly: { amount: 50, reason: "grant_weekly" },
  pro_monthly: { amount: 500, reason: "grant_monthly" },
  pro_annual: { amount: 6000, reason: "grant_annual" },
  pro_lifetime: { amount: 1000, reason: "grant_lifetime" },
};

export function grantForProduct(productId: string):
  { amount: number; reason: string } | null {
  if (productId in SUB_GRANTS) return SUB_GRANTS[productId];
  if (productId in TOKEN_PACKS) {
    return { amount: TOKEN_PACKS[productId], reason: "grant_topup" };
  }
  return null;
}

/** Subscriptions + lifetime unlock the `pro` plan; token packs don't. */
export function planForProduct(productId: string): string | null {
  return productId in SUB_GRANTS ? "pro" : null;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `deno test supabase/functions/_shared/grants_test.ts`
Expected: PASS (6/6).

- [ ] **Step 5: Write the webhook function**

`supabase/functions/revenuecat-webhook/index.ts`:
```ts
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { grantForProduct, planForProduct } from "../_shared/grants.ts";

// RevenueCat sends the app_user_id (we set it to the Supabase user id) and the
// product identifier. Auth: a shared secret in the Authorization header,
// configured in the RevenueCat webhook UI and stored as REVENUECAT_WEBHOOK_AUTH.
Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return new Response("Method not allowed", { status: 405 });
  if ((req.headers.get("Authorization") ?? "") !== Deno.env.get("REVENUECAT_WEBHOOK_AUTH")) {
    return new Response("Unauthorized", { status: 401 });
  }

  const payload = await req.json().catch(() => null);
  const event = payload?.event;
  if (!event) return new Response("No event", { status: 400 });

  const userId: string | undefined = event.app_user_id;
  const productId: string | undefined = event.product_id;
  const type: string = event.type ?? "";
  if (!userId) return new Response("No app_user_id", { status: 400 });

  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const GRANTING = ["INITIAL_PURCHASE", "RENEWAL", "NON_RENEWING_PURCHASE"];
  const REVOKING = ["CANCELLATION", "EXPIRATION", "SUBSCRIPTION_PAUSED"];

  if (GRANTING.includes(type) && productId) {
    const grant = grantForProduct(productId);
    if (grant) {
      // Lifetime is granted per calendar month; use the period as ref so the
      // monthly cron (Task 6) won't double-grant the purchase month.
      const ref = grant.reason === "grant_lifetime"
        ? new Date().toISOString().slice(0, 7) // YYYY-MM
        : (event.transaction_id ?? null);
      await admin.rpc("grant_tokens", {
        p_user: userId, p_amount: grant.amount, p_reason: grant.reason, p_ref: ref,
      });
    }
    const plan = planForProduct(productId);
    if (plan) {
      await admin.from("profiles").update({
        plan, plan_product: productId, rc_customer_id: userId,
        pro_expires_at: event.expiration_at_ms
          ? new Date(event.expiration_at_ms).toISOString() : null,
      }).eq("id", userId);
    }
  } else if (REVOKING.includes(type)) {
    // Keep purchased tokens; drop pro access. (Lifetime does not expire.)
    if (productId !== "pro_lifetime") {
      await admin.from("profiles").update({ plan: "free", plan_product: null })
        .eq("id", userId);
    }
  }
  // REFUND/chargeback clawback of unspent grant is handled in a follow-up;
  // RevenueCat sends CANCELLATION for refunds which already revokes access.

  return new Response("ok", { status: 200 });
});
```

- [ ] **Step 6: Deploy + verify with a sample payload**

Run:
```bash
supabase secrets set REVENUECAT_WEBHOOK_AUTH="<pick-a-long-random-string>" --project-ref bwafaffjhaxclcmrjhdg
supabase functions deploy revenuecat-webhook --project-ref bwafaffjhaxclcmrjhdg
```
Simulate a monthly purchase for an existing test user:
```bash
curl -s -X POST "https://bwafaffjhaxclcmrjhdg.supabase.co/functions/v1/revenuecat-webhook" \
  -H "Authorization: <the-secret>" -H "Content-Type: application/json" \
  -d '{"event":{"type":"INITIAL_PURCHASE","app_user_id":"<uid>","product_id":"pro_monthly","transaction_id":"tx1","expiration_at_ms":1755500000000}}'
```
Verify via MCP `execute_sql`: `select plan, plan_product from profiles where id='<uid>'` → `pro`, `pro_monthly`; `select balance from token_balances where user_id='<uid>'` increased by 500; a `grant_monthly` ledger row exists. Re-post with a wrong `Authorization` → 401.

Expected: 200 + grant applied; 401 on bad auth.

- [ ] **Step 7: Commit**

```bash
git add supabase/functions/revenuecat-webhook/index.ts supabase/functions/_shared/grants.ts supabase/functions/_shared/grants_test.ts
git commit -m "feat(tokens): RevenueCat webhook grants + plan sync"
```

---

## Task 6: Lifetime monthly grant cron

**Files:**
- Create: `supabase/migrations/20260811093000_lifetime_cron.sql`
- Test: `supabase/tests/lifetime_grant_test.sql`

**Interfaces:**
- Consumes: `public.grant_tokens` (Task 2); `profiles.plan_product` (Task 1).
- Produces: `public.grant_lifetime_tokens() returns void` — idempotent per `(user, YYYY-MM)`, grants 1000 to each `pro_lifetime` holder; a monthly `pg_cron` schedule.

- [ ] **Step 1: Write the failing test**

`supabase/tests/lifetime_grant_test.sql`:
```sql
begin;
select plan(2);

insert into auth.users (id, email) values ('00000000-0000-0000-0000-000000000003', 'l@l.co')
  on conflict do nothing;
insert into public.profiles (id, name, email, plan, plan_product)
  values ('00000000-0000-0000-0000-000000000003', 'Lee', 'l@l.co', 'pro', 'pro_lifetime');

-- First run grants 1000; second run in the same month grants nothing more.
select public.grant_lifetime_tokens();
select public.grant_lifetime_tokens();

select is((select balance from public.token_balances
           where user_id = '00000000-0000-0000-0000-000000000003'), 1000,
  'lifetime holder granted exactly 1000 (idempotent within the month)');
select is((select count(*)::int from public.token_ledger
           where user_id = '00000000-0000-0000-0000-000000000003'
             and reason = 'grant_lifetime'), 1,
  'only one lifetime grant row this month');

select * from finish();
rollback;
```

- [ ] **Step 2: Run test to verify it fails**

Run: `supabase test db`
Expected: FAIL — function does not exist.

- [ ] **Step 3: Write the migration**

`supabase/migrations/20260811093000_lifetime_cron.sql`:
```sql
create or replace function public.grant_lifetime_tokens() returns void
language plpgsql security definer set search_path = public as $$
declare r record; v_period text := to_char(now(), 'YYYY-MM');
begin
  for r in select id from public.profiles where plan_product = 'pro_lifetime' loop
    if not exists (
      select 1 from public.token_ledger
      where user_id = r.id and reason = 'grant_lifetime' and ref = v_period
    ) then
      perform public.grant_tokens(r.id, 1000, 'grant_lifetime', v_period);
    end if;
  end loop;
end; $$;

-- Requires the pg_cron extension (enable once): create extension if not exists pg_cron;
create extension if not exists pg_cron;
select cron.schedule(
  'grant-lifetime-tokens-monthly',
  '0 0 1 * *',
  $$ select public.grant_lifetime_tokens() $$
);
```

- [ ] **Step 4: Apply + run test to verify it passes**

Run: `supabase db push`, then `supabase test db`
Expected: PASS (2/2).

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260811093000_lifetime_cron.sql supabase/tests/lifetime_grant_test.sql
git commit -m "feat(tokens): idempotent monthly lifetime grant cron"
```

---

## Self-review notes

- **Spec coverage:** balance/ledger (§7) → Task 1; atomic spend/grant + concurrency (§8) → Task 2; signup grant (§9) → Task 3; cloud debit + auto-refund (§6, §8) → Task 4; webhook grants + plan sync (§6) → Task 5; lifetime monthly grant + idempotency (§6, §8) → Task 6. Border-pass/offline-maps/local-gen spends are **out of scope here** — they call the Task 2 `spend_tokens` RPC and belong to the iOS integration plan (spec §11 plan 3).
- **Deferred (call out, don't silently drop):** REFUND clawback of *unspent* tokens (§8) is stubbed in Task 5's comment — implement when wiring real RevenueCat refund events; needs the original grant amount from the ledger. Reconciliation of the Supabase balance back to RevenueCat's Virtual Currency (§6) is also deferred (app reads Supabase; RC VC is advisory).
- **Type consistency:** `costForAction(mode, backend)`, `grantForProduct → {amount, reason}`, `planForProduct → "pro"|null`, `grant_tokens(uuid,int,text,text)`, `spend_tokens(uuid,int,text,text)` used consistently across tasks.
