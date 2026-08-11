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
