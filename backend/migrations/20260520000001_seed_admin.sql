-- Seed: Promote an existing user to super admin
-- INSTRUCTIONS: Replace the email below with your actual Supabase Auth user email.
-- Then run this migration or execute it manually in the Supabase SQL editor.

-- Promote by email (find user in auth.users, update public.profiles)
do $$
declare
  admin_user_id uuid;
begin
  select id into admin_user_id
  from auth.users
  where email = 'fehkelvink@gmail.com'
  limit 1;

  if admin_user_id is not null then
    update public.profiles
    set is_super_admin = true
    where id = admin_user_id;
    
    raise notice 'User % promoted to super admin.', admin_user_id;
  else
    raise notice 'No user found with that email. Sign up first, then re-run this script.';
  end if;
end $$;
