-- 001_shorten_slugs_and_add_placeholders.sql
-- Run once in the Supabase SQL editor.
-- Renames the original "<name>-coach" slugs to "<name>" and seeds three new
-- placeholder portals (career, strengths, it). Idempotent: safe to re-run.

-- 1. Make sure portals.slug is unique so the upsert below works
do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'portals_slug_unique'
  ) then
    alter table portals add constraint portals_slug_unique unique (slug);
  end if;
end $$;

-- 2. Rename slugs in portals
update portals set slug = 'business'     where slug = 'business-coach';
update portals set slug = 'team'         where slug = 'team-coach';
update portals set slug = 'marketing'    where slug = 'marketing-coach';
update portals set slug = 'life'         where slug = 'life-coach';
update portals set slug = 'relationship' where slug = 'relationship-coach';

-- 3. Mirror the rename in client_access so existing grants keep working
update client_access set portal_slug = 'business'     where portal_slug = 'business-coach';
update client_access set portal_slug = 'team'         where portal_slug = 'team-coach';
update client_access set portal_slug = 'marketing'    where portal_slug = 'marketing-coach';
update client_access set portal_slug = 'life'         where portal_slug = 'life-coach';
update client_access set portal_slug = 'relationship' where portal_slug = 'relationship-coach';

-- 4. Seed the three new placeholder portals
insert into portals (slug, name, description, display_order, coming_soon) values
  ('career',    'Career Coach',    'Direction, transitions, and next-step planning.', 70, false),
  ('strengths', 'Strengths Coach', 'Discover and apply your top strengths.',           80, false),
  ('it',        'IT Support',      'Help with your portal access and tooling.',        90, false)
on conflict (slug) do nothing;
