-- 019: Remove the 'strengths' portal (Your Strengths Coach).
-- The yourstrengthscoach repo has been deleted (2026-07-17 repo audit): its
-- Top 10 sub-app's backing tables (strengths_catalog / user_top_strengths /
-- hub_strengths) were never created in this project, so no client ever saved
-- data in it. The working client-facing strengths experience is the in-portal
-- Coach4U Tools CliftonStrengths page (slug 'coach4u-tools', client_strengths
-- + get-strengths edge function) — unaffected by this migration.
-- Idempotent — safe to re-run.

DELETE FROM public.client_access
 WHERE portal_slug = 'strengths';

DELETE FROM public.portals
 WHERE slug = 'strengths';
