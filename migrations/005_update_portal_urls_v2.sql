-- 005_update_portal_urls_v2.sql
-- Run once in the Supabase SQL editor.
-- Repoints business, team, marketing, relationship, and thrivehq portals at
-- their renamed sub-portal repos. life and strengths are already correct.
-- Idempotent: safe to re-run.

update portals set url = 'https://cathcoach4u.github.io/yourbusinesscoach/'     where slug = 'business';
update portals set url = 'https://cathcoach4u.github.io/yourteamcoach/'         where slug = 'team';
update portals set url = 'https://cathcoach4u.github.io/yourmarketingcoach/'    where slug = 'marketing';
update portals set url = 'https://cathcoach4u.github.io/yourrelationshipcoach/' where slug = 'relationship';
update portals set url = 'https://cathcoach4u.github.io/yourthrivehqcoach/'     where slug = 'thrivehq';
