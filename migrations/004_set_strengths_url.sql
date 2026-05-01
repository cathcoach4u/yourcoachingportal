-- 004_set_strengths_url.sql
-- Run once in the Supabase SQL editor.
-- Points the "strengths" portal at its newly-live sub-portal site.
-- Idempotent: safe to re-run.

update portals
   set url = 'https://cathcoach4u.github.io/yourstrengthscoach/'
 where slug = 'strengths';
