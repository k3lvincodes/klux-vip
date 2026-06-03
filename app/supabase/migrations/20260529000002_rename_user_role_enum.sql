-- Ensure the handle_new_user trigger uses the new enum values
-- (only needed if this migration was applied before the phase4 migration)
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, role)
  values (new.id, coalesce(new.email, ''), 'client');
  return new;
end;
$$ language plpgsql security definer;
