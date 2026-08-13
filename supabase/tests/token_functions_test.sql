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
