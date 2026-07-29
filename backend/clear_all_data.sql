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
    select tablename from pg_tables
    where schemaname = 'public'
    order by tablename
  loop
    execute format('truncate public.%I cascade', tbl);
    raise notice 'Truncated public.%', tbl;
  end loop;
end $$;
