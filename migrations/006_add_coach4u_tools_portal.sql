-- 006_add_coach4u_tools_portal.sql
-- Run once in the Supabase SQL editor.
-- Adds a "coach4u-tools" portal row that surfaces the in-repo Strengths Hub
-- (strengths.html) as a gated tile inside the dashboard "Your Tools" grid.
-- Only clients with a matching client_access row will see it as active.
-- Idempotent: safe to re-run.

insert into portals (slug, name, description, url, display_order, coming_soon)
values (
  'coach4u-tools',
  'Your Coach4U Tools',
  'Your Strengths Hub and curated tools, available to existing clients.',
  'strengths.html',
  7,
  false
)
on conflict (slug) do update set
  name          = excluded.name,
  description   = excluded.description,
  url           = excluded.url,
  display_order = excluded.display_order,
  coming_soon   = excluded.coming_soon;

-- To grant a client access (replace email):
--
-- insert into client_access (user_id, portal_slug)
-- select u.id, 'coach4u-tools'
-- from auth.users u
-- where lower(u.email) = lower('client@example.com')
-- on conflict do nothing;
