-- Make profiles.role nullable so new users don't get a default role
-- until they explicitly select one on the "who are you?" page.
alter table public.profiles
  alter column role drop not null,
  alter column role drop default;

-- Update the handle_new_user trigger to not assign a role at all.
-- Role stays null until the user explicitly picks one on the role
-- selection screen and completes their profile setup.
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email)
  values (new.id, coalesce(new.email, ''));
  return new;
end;
$$ language plpgsql security definer;
