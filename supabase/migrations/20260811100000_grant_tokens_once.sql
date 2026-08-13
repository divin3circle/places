-- Idempotent grant keyed on (user, reason, ref). The RevenueCat webhook calls
-- this so a retried delivery (or an at-least-once notification) can't double-grant:
-- non-lifetime grants use the store transaction id as `ref`, lifetime uses YYYY-MM.
-- Service-role only (the webhook runs as service role).
create or replace function public.grant_tokens_once(
  p_user uuid, p_amount int, p_reason text, p_ref text
) returns int
language plpgsql security definer set search_path = public as $$
declare v_balance int;
begin
  -- No idempotency key -> behave like a plain grant.
  if p_ref is null then
    return public.grant_tokens(p_user, p_amount, p_reason, p_ref);
  end if;
  -- Already granted for this (user, reason, ref): no-op, return current balance.
  if exists (
    select 1 from public.token_ledger
    where user_id = p_user and reason = p_reason and ref = p_ref
  ) then
    select balance into v_balance from public.token_balances where user_id = p_user;
    return coalesce(v_balance, 0);
  end if;
  return public.grant_tokens(p_user, p_amount, p_reason, p_ref);
end; $$;

revoke all on function public.grant_tokens_once(uuid, int, text, text) from public, anon, authenticated;
