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
