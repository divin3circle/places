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
