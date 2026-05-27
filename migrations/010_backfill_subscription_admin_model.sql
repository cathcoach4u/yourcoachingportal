-- ============================================================================
-- 010 — Backfill subscription_app_bundle + subscription_admins
-- ============================================================================
--
-- Companion to migration 009. Run AFTER 009 has been applied.
--
-- What this does:
--   1. subscription_app_bundle <- UNION of slugs held by each subscription's
--      members (owner + team_members across all orgs in the sub)
--   2. subscription_admins     <- each subscription's owner becomes admin
--                                 of their own sub (so they can manage it)
--   3. Returns a verification view showing what landed
--
-- Idempotent. Safe to re-run.
-- ============================================================================


-- 1. Bundle: each subscription gets the UNION of slugs its members already hold
INSERT INTO public.subscription_app_bundle (subscription_id, portal_slug)
WITH sub_members AS (
  SELECT s.id AS subscription_id, s.owner_user_id AS user_id
    FROM public.subscriptions s
  UNION
  SELECT o.subscription_id, tm.user_id
    FROM public.organisations o
    JOIN public.team_members tm ON tm.organisation_id = o.id
   WHERE tm.user_id IS NOT NULL
)
SELECT DISTINCT sm.subscription_id, ca.portal_slug
  FROM sub_members sm
  JOIN public.client_access ca ON ca.user_id = sm.user_id
ON CONFLICT (subscription_id, portal_slug) DO NOTHING;


-- 2. Admins: subscription owner becomes admin of their own sub
INSERT INTO public.subscription_admins (subscription_id, user_id, granted_by)
SELECT s.id, s.owner_user_id, s.owner_user_id
  FROM public.subscriptions s
ON CONFLICT (subscription_id, user_id) DO NOTHING;


-- 3. Verification: shows each subscription with its bundle + admins
SELECT s.name AS subscription,
       s.subscription_type,
       (SELECT array_agg(b.portal_slug ORDER BY b.portal_slug)
          FROM public.subscription_app_bundle b
         WHERE b.subscription_id = s.id) AS bundle,
       (SELECT array_agg(au.email)
          FROM public.subscription_admins sa
          JOIN auth.users au ON au.id = sa.user_id
         WHERE sa.subscription_id = s.id) AS admins
  FROM public.subscriptions s
  ORDER BY s.name;
