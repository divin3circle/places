-- Public support/feedback inbox for the marketing site (places-web.vercel.app/support).
-- Anyone may SUBMIT a message (anon insert); nobody can read/update/delete via the API.
-- The owner reads messages in the Supabase dashboard (Table Editor / SQL editor),
-- which uses the service role and bypasses RLS.

create table if not exists public.support_messages (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  name text        check (name is null or char_length(name) <= 200),
  email text       check (email is null or char_length(email) <= 320),
  subject text     check (subject is null or char_length(subject) <= 300),
  message text     not null check (char_length(message) between 1 and 5000),
  page text        check (page is null or char_length(page) <= 300),
  user_agent text  check (user_agent is null or char_length(user_agent) <= 500)
);

create index if not exists support_messages_created_idx
  on public.support_messages (created_at desc);

alter table public.support_messages enable row level security;

-- Only INSERT is allowed, and only writes (no reads) — anyone can submit.
create policy "anyone can submit a support message"
  on public.support_messages
  for insert
  to anon, authenticated
  with check (true);

-- Deliberately NO select/update/delete policies:
-- with RLS on and no SELECT policy, anon/authenticated cannot read any rows.
-- Only the service role (dashboard, SQL editor, server with the service key) can read.
