-- 002_add_portal_url.sql
-- Run once in the Supabase SQL editor.
-- Adds a "url" column to portals so the front-end can read it directly
-- (replaces the hardcoded URL map that used to live in index.html).
-- Idempotent: safe to re-run.

-- 1. Add the column if it isn't there yet
alter table portals
  add column if not exists url text;

-- 2. Seed URLs for the six built portals
update portals set url = 'https://cathcoach4u.github.io/Coach4uapp-strategy/business/'   where slug = 'business';
update portals set url = 'https://cathcoach4u.github.io/coach4Uapp-teamcoach4U/'         where slug = 'team';
update portals set url = 'https://cathcoach4u.github.io/Coach4U-Growth/'                 where slug = 'marketing';
update portals set url = 'https://cathcoach4u.github.io/coach4Uapp-dashboard/personal/'  where slug = 'life';
update portals set url = 'https://cathcoach4u.github.io/Coach4Uapp-relationships/'       where slug = 'relationship';
update portals set url = 'https://cathcoach4u.github.io/coach4Uapp-thrivehq/'            where slug = 'thrivehq';

-- career, strengths, it: leave url null until those sub-portal sites exist.
-- The page falls back to '#' for missing urls.
