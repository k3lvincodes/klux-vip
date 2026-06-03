-- =============================================================================
-- Klux VIP - Remove All Data Script
-- WARNING: This permanently deletes ALL rows from every table.
-- The schema (tables, functions, triggers, RLS policies) is preserved.
-- Use this to reset the database to a clean state.
-- =============================================================================

do $$
declare
  tbl text;
begin
  for tbl in
    select unnest(array[
      'fare_rates',
      'surge_zones',
      'profiles'
    ])
  loop
    if exists (
      select from pg_tables
      where schemaname = 'public' and tablename = tbl
    ) then
      execute format('truncate public.%I cascade', tbl);
      raise notice 'Truncated public.%', tbl;
    else
      raise notice 'Skipped public.% (table does not exist)', tbl;
    end if;
  end loop;
end $$;
