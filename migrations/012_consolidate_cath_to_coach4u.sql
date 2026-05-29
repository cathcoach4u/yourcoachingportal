-- ============================================================================
-- 012 — Consolidate Cath's data: coachingwithcath → coach4u
-- ============================================================================
--
-- Moves all user-keyed data from cath@coachingwithcath.com.au to
-- cath@coach4u.com.au so a single email holds all roles:
--   • Super admin (users.is_admin already true)
--   • Subscription owner (Saruba)
--   • Personal user (apps, brain pulse, relationships)
--
-- After running:
--   • cath@coach4u.com.au has everything
--   • cath@coachingwithcath.com.au exists but owns nothing
--   • Auth users + passwords are untouched
--   • Sign in only as cath@coach4u.com.au going forward
--   • The other account can be deleted later or left dormant
--
-- One-way migration. Make sure Supabase has a recent backup before running.
-- ============================================================================

DO $$
DECLARE
  v_old uuid := 'f8327825-0022-4c16-b735-cd1c90897889';  -- cath@coachingwithcath.com.au
  v_new uuid := '59066d37-7ddd-4e3e-9efd-67076060b253';  -- cath@coach4u.com.au
  v_count integer;
BEGIN
  -- 1. Subscriptions: ownership
  UPDATE public.subscriptions SET owner_user_id = v_new WHERE owner_user_id = v_old;
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RAISE NOTICE 'subscriptions.owner_user_id: % rows moved', v_count;

  UPDATE public.subscriptions SET partner_user_id = v_new WHERE partner_user_id = v_old;
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RAISE NOTICE 'subscriptions.partner_user_id: % rows moved', v_count;

  -- 2. Subscription admins: drop old user from any sub the new user is already admin of, then move the rest
  DELETE FROM public.subscription_admins
    WHERE user_id = v_old
      AND subscription_id IN (
        SELECT subscription_id FROM public.subscription_admins WHERE user_id = v_new
      );
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RAISE NOTICE 'subscription_admins: % duplicate rows pruned', v_count;

  UPDATE public.subscription_admins SET user_id = v_new WHERE user_id = v_old;
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RAISE NOTICE 'subscription_admins.user_id: % rows moved', v_count;

  UPDATE public.subscription_admins SET granted_by = v_new WHERE granted_by = v_old;
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RAISE NOTICE 'subscription_admins.granted_by: % rows moved', v_count;

  -- 3. Team members
  UPDATE public.team_members SET user_id = v_new WHERE user_id = v_old;
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RAISE NOTICE 'team_members.user_id: % rows moved', v_count;

  -- 4. Client access: drop duplicates first, then move
  DELETE FROM public.client_access
    WHERE user_id = v_old
      AND portal_slug IN (
        SELECT portal_slug FROM public.client_access WHERE user_id = v_new
      );
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RAISE NOTICE 'client_access: % duplicate rows pruned', v_count;

  UPDATE public.client_access SET user_id = v_new WHERE user_id = v_old;
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RAISE NOTICE 'client_access.user_id: % rows moved', v_count;

  -- 5. Brain pulse results
  UPDATE public.brain_pulse_results SET user_id = v_new WHERE user_id = v_old;
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RAISE NOTICE 'brain_pulse_results.user_id: % rows moved', v_count;

  -- 6. User relationships
  UPDATE public.user_relationships SET user_id = v_new WHERE user_id = v_old;
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RAISE NOTICE 'user_relationships.user_id: % rows moved', v_count;

  -- 7. hub_profile_id — copy from old user to new if new is null
  UPDATE public.users
     SET hub_profile_id = (SELECT hub_profile_id FROM public.users WHERE id = v_old)
   WHERE id = v_new
     AND hub_profile_id IS NULL
     AND EXISTS (SELECT 1 FROM public.users WHERE id = v_old AND hub_profile_id IS NOT NULL);
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RAISE NOTICE 'users.hub_profile_id: % linkage moved', v_count;
END $$;


-- ─────────────────────────────────────────────────────────────────
-- Verification — old account should be empty, new should have it all
-- ─────────────────────────────────────────────────────────────────

SELECT 'cath@coachingwithcath.com.au (should be all zeros now)' AS status;
SELECT
  (SELECT COUNT(*) FROM public.subscriptions       WHERE owner_user_id = 'f8327825-0022-4c16-b735-cd1c90897889') AS owns_subs,
  (SELECT COUNT(*) FROM public.subscription_admins WHERE user_id       = 'f8327825-0022-4c16-b735-cd1c90897889') AS admin_rows,
  (SELECT COUNT(*) FROM public.team_members        WHERE user_id       = 'f8327825-0022-4c16-b735-cd1c90897889') AS team_member_rows,
  (SELECT COUNT(*) FROM public.client_access       WHERE user_id       = 'f8327825-0022-4c16-b735-cd1c90897889') AS app_access_rows,
  (SELECT COUNT(*) FROM public.brain_pulse_results WHERE user_id       = 'f8327825-0022-4c16-b735-cd1c90897889') AS brain_pulse_rows,
  (SELECT COUNT(*) FROM public.user_relationships  WHERE user_id       = 'f8327825-0022-4c16-b735-cd1c90897889') AS coaching_relationship_rows;

SELECT 'cath@coach4u.com.au (should now hold everything)' AS status;
SELECT
  (SELECT COUNT(*) FROM public.subscriptions       WHERE owner_user_id = '59066d37-7ddd-4e3e-9efd-67076060b253') AS owns_subs,
  (SELECT COUNT(*) FROM public.subscription_admins WHERE user_id       = '59066d37-7ddd-4e3e-9efd-67076060b253') AS admin_rows,
  (SELECT COUNT(*) FROM public.team_members        WHERE user_id       = '59066d37-7ddd-4e3e-9efd-67076060b253') AS team_member_rows,
  (SELECT COUNT(*) FROM public.client_access       WHERE user_id       = '59066d37-7ddd-4e3e-9efd-67076060b253') AS app_access_rows,
  (SELECT COUNT(*) FROM public.brain_pulse_results WHERE user_id       = '59066d37-7ddd-4e3e-9efd-67076060b253') AS brain_pulse_rows,
  (SELECT COUNT(*) FROM public.user_relationships  WHERE user_id       = '59066d37-7ddd-4e3e-9efd-67076060b253') AS coaching_relationship_rows;
