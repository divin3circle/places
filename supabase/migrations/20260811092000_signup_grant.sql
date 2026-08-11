create or replace function public.grant_signup_tokens() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  perform public.grant_tokens(new.id, 15, 'grant_signup', null);
  return new;
end; $$;

drop trigger if exists on_profile_created_grant_tokens on public.profiles;
create trigger on_profile_created_grant_tokens
  after insert on public.profiles
  for each row execute function public.grant_signup_tokens();
