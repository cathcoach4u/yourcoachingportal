-- 007_rename_coach4u_tools_url.sql
-- Run once in the Supabase SQL editor.
-- The coach4u-tools portal previously pointed at strengths.html, which has
-- been renamed to coach4u-tools.html in the repo. This migration repoints
-- the portal so the dashboard tile opens the new path.
-- Idempotent: safe to re-run.

update portals
   set url = 'coach4u-tools.html'
 where slug = 'coach4u-tools';
