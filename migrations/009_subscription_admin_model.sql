-- ============================================================================
-- 009 — Subscription admin model: scoped admin + per-account app bundle
-- ============================================================================
--
-- Goal: enable business owners (and any other account holder) to invite
-- their own users and grant them app access — without Cath being in the
-- loop. See coach4Uapp-dashboard/CLAUDE.md ("Target design") for the
-- complete model and reasoning.
--
-- What this migration adds:
--   1. subscription_app_bundle  — which portals an account subscribes to
--   2. subscription_admins      — scoped admin role per subscription
--      (NOT the same as users.is_admin, which stays global super-admin)
--
-- What this migration does NOT do:
--   • Backfill bundle from existing client_access rows (separate step,
--     run after this when bundles per existing subscription are confirmed)
--   • Constrain client_access writes to the bundle (a later RLS tightening)
--   • Add an 'individual' or 'couple' subscription_type CHECK constraint
--     — deferred until the generalised account abstraction is decided
--
-- Idempotent. Safe to re-run.
-- ============================================================================


-- ---------------------------------------------------------------------------
-- 1. subscription_app_bundle
-- ---------------------------------------------------------------------------
-- One row per (subscription, portal) the subscription pays for / has
-- access to. The "max set" of apps any user in this subscription
-- COULD be granted (subject to per-user subset via client_access).

CREATE TABLE IF NOT EXISTS public.subscription_app_bundle (
  subscription_id  uuid NOT NULL REFERENCES public.subscriptions(id) ON DELETE CASCADE,
  portal_slug      text NOT NULL REFERENCES public.portals(slug)     ON DELETE CASCADE,
  granted_at       timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (subscription_id, portal_slug)
);

CREATE INDEX IF NOT EXISTS subscription_app_bundle_slug_idx
  ON public.subscription_app_bundle (portal_slug);

ALTER TABLE public.subscription_app_bundle ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if rerun, then recreate
DROP POLICY IF EXISTS bundle_read_super_admin    ON public.subscription_app_bundle;
DROP POLICY IF EXISTS bundle_read_sub_member     ON public.subscription_app_bundle;
DROP POLICY IF EXISTS bundle_write_super_admin   ON public.subscription_app_bundle;

-- Super admins (is_admin) can read/write everything
CREATE POLICY bundle_read_super_admin
  ON public.subscription_app_bundle FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM public.users u WHERE u.id = auth.uid() AND u.is_admin = true)
  );

-- Anyone who belongs to the subscription (as team member, subscription
-- admin, or owner) can READ the bundle — needed so the portal can
-- render the right tile set for their account context.
CREATE POLICY bundle_read_sub_member
  ON public.subscription_app_bundle FOR SELECT
  USING (
    subscription_id IN (
      SELECT s.id FROM public.subscriptions s
        WHERE s.owner_user_id = auth.uid()
      UNION
      SELECT o.subscription_id FROM public.organisations o
        JOIN public.team_members tm ON tm.organisation_id = o.id
        WHERE tm.user_id = auth.uid()
    )
  );

-- Writes are restricted to super admins for now. Subscription admins
-- can manage user access within the bundle but cannot change the
-- bundle itself (that's a Cath / billing-tier decision).
CREATE POLICY bundle_write_super_admin
  ON public.subscription_app_bundle FOR ALL
  USING (
    EXISTS (SELECT 1 FROM public.users u WHERE u.id = auth.uid() AND u.is_admin = true)
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.users u WHERE u.id = auth.uid() AND u.is_admin = true)
  );


-- ---------------------------------------------------------------------------
-- 2. subscription_admins
-- ---------------------------------------------------------------------------
-- Scoped admin role: this user is an admin of this subscription.
-- DIFFERENT from users.is_admin (global super-admin). A subscription
-- admin can manage users WITHIN their subscription only.
--
-- Typical population:
--   - subscription owner is auto-added (handled by app logic)
--   - super admin can promote additional admins via admin.html

CREATE TABLE IF NOT EXISTS public.subscription_admins (
  subscription_id  uuid NOT NULL REFERENCES public.subscriptions(id) ON DELETE CASCADE,
  user_id          uuid NOT NULL REFERENCES auth.users(id)           ON DELETE CASCADE,
  granted_at       timestamptz NOT NULL DEFAULT now(),
  granted_by       uuid          REFERENCES auth.users(id) ON DELETE SET NULL,
  PRIMARY KEY (subscription_id, user_id)
);

CREATE INDEX IF NOT EXISTS subscription_admins_user_idx
  ON public.subscription_admins (user_id);

ALTER TABLE public.subscription_admins ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS sub_admins_read_super_admin    ON public.subscription_admins;
DROP POLICY IF EXISTS sub_admins_read_self_or_sub    ON public.subscription_admins;
DROP POLICY IF EXISTS sub_admins_write_super_admin   ON public.subscription_admins;

CREATE POLICY sub_admins_read_super_admin
  ON public.subscription_admins FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM public.users u WHERE u.id = auth.uid() AND u.is_admin = true)
  );

-- A subscription admin can see their own row + co-admins of the same sub.
-- (Needed so the admin UI can show "you are admin of X, Y, Z" and list
-- co-admins.)
CREATE POLICY sub_admins_read_self_or_sub
  ON public.subscription_admins FOR SELECT
  USING (
    user_id = auth.uid()
    OR
    subscription_id IN (
      SELECT sa.subscription_id FROM public.subscription_admins sa
        WHERE sa.user_id = auth.uid()
    )
  );

-- Only super admins can promote/demote subscription admins.
CREATE POLICY sub_admins_write_super_admin
  ON public.subscription_admins FOR ALL
  USING (
    EXISTS (SELECT 1 FROM public.users u WHERE u.id = auth.uid() AND u.is_admin = true)
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.users u WHERE u.id = auth.uid() AND u.is_admin = true)
  );


-- ---------------------------------------------------------------------------
-- 3. Helper view: is the current user a subscription admin?
-- ---------------------------------------------------------------------------
-- Convenience for client-side queries: returns the list of subscription
-- IDs the calling user is an admin of. Used by the portal to decide
-- whether to render the "Manage my team / partner" tile.

CREATE OR REPLACE VIEW public.my_admin_subscriptions AS
  SELECT subscription_id
    FROM public.subscription_admins
   WHERE user_id = auth.uid()
  UNION
  SELECT s.id AS subscription_id
    FROM public.subscriptions s
   WHERE s.owner_user_id = auth.uid();

-- View inherits RLS from underlying tables.
