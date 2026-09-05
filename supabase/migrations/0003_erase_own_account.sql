-- GDPR Art. 17: the signed-in user may erase their Auth row after client-side
-- cleanup. SECURITY DEFINER is required because auth.users is not writable via RLS.

create or replace function public.erase_own_account()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'not authenticated';
  end if;
  delete from public.board_nodes where owner_id = uid;
  delete from public.boards where owner_id = uid;
  delete from public.consent_events where user_id = uid;
  delete from public.security_events where user_id = uid;
  delete from public.profiles where id = uid;
  delete from auth.users where id = uid;
end;
$$;

revoke all on function public.erase_own_account() from public;
grant execute on function public.erase_own_account() to authenticated;
