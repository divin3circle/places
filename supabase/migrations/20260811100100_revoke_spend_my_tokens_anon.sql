-- Defense-in-depth: spend_my_tokens is guarded (raises if auth.uid() is null),
-- but Postgres doesn't auto-revoke `public`/`anon` when granting to `authenticated`.
-- Revoke it explicitly so only authenticated callers can reach it.
revoke all on function public.spend_my_tokens(int, text, text) from anon, public;
grant execute on function public.spend_my_tokens(int, text, text) to authenticated;
