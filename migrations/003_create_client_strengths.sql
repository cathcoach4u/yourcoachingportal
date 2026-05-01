-- 003_create_client_strengths.sql
-- Run once in the Supabase SQL editor (project eekefsuaefgpqmjdyniy).
-- Creates a per-client list of Gallup CliftonStrengths themes (top N, in order).
-- Idempotent: safe to re-run.

-- 1. Table
create table if not exists client_strengths (
  user_id uuid not null references auth.users(id) on delete cascade,
  rank    int  not null check (rank between 1 and 34),
  theme   text not null,
  primary key (user_id, rank)
);

-- 2. RLS — each client only ever sees their own rows
alter table client_strengths enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename  = 'client_strengths'
      and policyname = 'client_strengths_select_own'
  ) then
    create policy client_strengths_select_own
      on client_strengths
      for select
      using (auth.uid() = user_id);
  end if;
end $$;

-- Inserts/updates are admin-only via the service role; no insert/update/delete
-- policies for the anon role on purpose.

-- 3. How to load a client's strengths (one-off, not part of this migration):
-- In the OTHER Supabase project, export the rows for this client (e.g. as CSV).
-- Then in THIS project's SQL editor, run something like:
--
--   insert into client_strengths (user_id, rank, theme)
--   select u.id, x.rank, x.theme
--   from auth.users u,
--        (values
--           (1, 'Strategic'),
--           (2, 'Learner'),
--           (3, 'Achiever'),
--           (4, 'Input'),
--           (5, 'Activator')
--        ) as x(rank, theme)
--   where lower(u.email) = lower('client@example.com')
--   on conflict (user_id, rank) do update set theme = excluded.theme;
