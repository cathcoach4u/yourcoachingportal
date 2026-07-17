-- 017: Remove the 'team' portal (Your Team Coach).
-- The yourteamcoach repo is being deleted (2026-07-17 repo audit): its two
-- tools (Accountability Chart, Team Alignment) called a /api backend that
-- never existed on GitHub Pages, and their data tables were never created —
-- no client data exists. Cath confirmed no placeholder is wanted.
-- Deleting the portals row cascades to subscription_app_bundle (the business
-- bundle default included 'team'); client_access is cleaned explicitly.
-- Idempotent — safe to re-run.

DELETE FROM public.client_access
 WHERE portal_slug = 'team';

DELETE FROM public.portals
 WHERE slug = 'team';
