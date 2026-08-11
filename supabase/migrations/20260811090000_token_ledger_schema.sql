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
