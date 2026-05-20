-- Store trusted devices for biometric login
create table if not exists public.device_biometrics (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.users on delete cascade not null,
  device_id text not null,
  is_enabled boolean default false not null,
  last_verified_at timestamp with time zone default timezone('utc'::text, now()) not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(user_id, device_id)
);

-- Register or enable biometric for a device
create or replace function public.register_device_biometric(
  p_user_id uuid,
  p_device_id text
) returns void
language plpgsql
as $$
begin
  insert into public.device_biometrics (user_id, device_id, is_enabled, last_verified_at)
  values (p_user_id, p_device_id, true, timezone('utc'::text, now()))
  on conflict (user_id, device_id)
  do update set
    is_enabled = true,
    last_verified_at = timezone('utc'::text, now()),
    updated_at = timezone('utc'::text, now());
end;
$$;

-- Disable biometric for a device
create or replace function public.unregister_device_biometric(
  p_user_id uuid,
  p_device_id text
) returns void
language plpgsql
as $$
begin
  update public.device_biometrics
  set is_enabled = false, updated_at = timezone('utc'::text, now())
  where user_id = p_user_id and device_id = p_device_id;
end;
$$;

-- Check if a device has valid biometric login within 7-day session window
-- Returns user_id + days_remaining if valid, null otherwise
create or replace function public.check_device_biometric(
  p_email text,
  p_device_id text
) returns jsonb
language plpgsql
as $$
declare
  v_result jsonb;
  v_user_id uuid;
  v_last_verified_at timestamp with time zone;
  v_days_diff integer;
begin
  -- Get the user id from auth.users
  select id into v_user_id
  from auth.users
  where email = p_email;

  if v_user_id is null then
    return null;
  end if;

  -- Check device biometric record
  select last_verified_at into v_last_verified_at
  from public.device_biometrics
  where user_id = v_user_id
    and device_id = p_device_id
    and is_enabled = true;

  if v_last_verified_at is null then
    return null;
  end if;

  v_days_diff := extract(day from (timezone('utc'::text, now()) - v_last_verified_at));

  if v_days_diff >= 7 then
    return null;
  end if;

  v_result := jsonb_build_object(
    'user_id', v_user_id,
    'days_remaining', 7 - v_days_diff
  );

  return v_result;
end;
$$;

-- Update last_verified_at on successful biometric auth (extends session)
create or replace function public.refresh_device_biometric(
  p_user_id uuid,
  p_device_id text
) returns void
language plpgsql
as $$
begin
  update public.device_biometrics
  set last_verified_at = timezone('utc'::text, now()),
      updated_at = timezone('utc'::text, now())
  where user_id = p_user_id
    and device_id = p_device_id
    and is_enabled = true;
end;
$$;

-- Allow access for authenticated users
alter table public.device_biometrics enable row level security;

create policy "Users can manage their own device biometrics"
  on public.device_biometrics
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
