-- Saved Places table
create table public.saved_places (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles on delete cascade not null,
  name text not null,
  address text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.saved_places enable row level security;

create policy "Users can view their own saved places." on public.saved_places
  for select using (auth.uid() = user_id);

create policy "Users can insert their own saved places." on public.saved_places
  for insert with check (auth.uid() = user_id);

create policy "Users can update their own saved places." on public.saved_places
  for update using (auth.uid() = user_id);

create policy "Users can delete their own saved places." on public.saved_places
  for delete using (auth.uid() = user_id);
