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
