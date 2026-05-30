-- ============================================================================
-- 013 — Verify the Cath consolidation (companion to 012)
-- ============================================================================
--
-- Read-only check. Shows both Cath accounts side-by-side so you can
-- confirm 012 worked correctly.
--
-- Expected after 012 ran successfully:
--   • cath@coach4u.com.au          — non-zero counts (all data moved here)
--   • cath@coachingwithcath.com.au — all zeros (empty after move)
--
-- Safe to re-run any time. No changes.
-- ============================================================================

SELECT
  email,
  (SELECT COUNT(*) FROM public.subscriptions       WHERE owner_user_id = users.id) AS owns_subs,
  (SELECT COUNT(*) FROM public.subscription_admins WHERE user_id       = users.id) AS admin_rows,
  (SELECT COUNT(*) FROM public.team_members        WHERE user_id       = users.id) AS team_member_rows,
  (SELECT COUNT(*) FROM public.client_access       WHERE user_id       = users.id) AS app_access_rows,
  (SELECT COUNT(*) FROM public.brain_pulse_results WHERE user_id       = users.id) AS brain_pulse_rows
FROM public.users
WHERE email LIKE 'cath@%'
ORDER BY email;
