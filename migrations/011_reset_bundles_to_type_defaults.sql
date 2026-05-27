-- ============================================================================
-- 011 — Reset subscription_app_bundle to per-type defaults
-- ============================================================================
--
-- Migration 010's backfill set bundle = UNION of slugs the owner already
-- held in client_access. That over-grants — e.g. a thrivehq subscription
-- ended up with business+marketing+everything because the owner happened
-- to have personal access to those slugs.
--
-- This migration replaces those bundles with the per-type defaults that
-- match coach4Uapp-dashboard/admin.html's PORTAL_GROUPS constant — the
-- bundle definitions already proven in production.
--
-- coach-type subscriptions get EVERY non-coming-soon portal (the coach
-- subscription is internal/unlimited, e.g. "Saruba" / "Coaching with Cath").
--
-- Idempotent. Safe to re-run.
-- ============================================================================


-- 1. Clear current bundle rows (we're going to rewrite them all)
TRUNCATE public.subscription_app_bundle;


-- 2. Insert per-type defaults

-- Individual: life, career, strengths, coach4u-tools
INSERT INTO public.subscription_app_bundle (subscription_id, portal_slug)
SELECT s.id, slug
  FROM public.subscriptions s
  CROSS JOIN UNNEST(ARRAY['life','career','strengths','coach4u-tools']) AS slug
 WHERE s.subscription_type = 'individual';

-- Business: business, team, marketing, it
INSERT INTO public.subscription_app_bundle (subscription_id, portal_slug)
SELECT s.id, slug
  FROM public.subscriptions s
  CROSS JOIN UNNEST(ARRAY['business','team','marketing','it']) AS slug
 WHERE s.subscription_type = 'business' OR s.subscription_type IS NULL;

-- Couple: relationship
INSERT INTO public.subscription_app_bundle (subscription_id, portal_slug)
SELECT s.id, slug
  FROM public.subscriptions s
  CROSS JOIN UNNEST(ARRAY['relationship']) AS slug
 WHERE s.subscription_type = 'couple';

-- ThriveHQ: thrivehq
INSERT INTO public.subscription_app_bundle (subscription_id, portal_slug)
SELECT s.id, slug
  FROM public.subscriptions s
  CROSS JOIN UNNEST(ARRAY['thrivehq']) AS slug
 WHERE s.subscription_type = 'thrivehq';

-- Coach (internal): every live portal — coach subs are unlimited
INSERT INTO public.subscription_app_bundle (subscription_id, portal_slug)
SELECT s.id, p.slug
  FROM public.subscriptions s
  CROSS JOIN public.portals p
 WHERE s.subscription_type = 'coach'
   AND p.coming_soon = false;

-- Owner (internal): same as coach — full access
INSERT INTO public.subscription_app_bundle (subscription_id, portal_slug)
SELECT s.id, p.slug
  FROM public.subscriptions s
  CROSS JOIN public.portals p
 WHERE s.subscription_type = 'owner'
   AND p.coming_soon = false;


-- 3. Verification: show each subscription with its new bundle
SELECT s.name AS subscription,
       s.subscription_type,
       (SELECT array_agg(b.portal_slug ORDER BY b.portal_slug)
          FROM public.subscription_app_bundle b
         WHERE b.subscription_id = s.id) AS bundle
  FROM public.subscriptions s
  ORDER BY s.subscription_type, s.name;
