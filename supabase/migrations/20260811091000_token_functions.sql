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
