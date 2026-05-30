-- ============================================================================
-- 014 — Read what's actually in subscription_admins
-- ============================================================================
-- Diagnostic for: admin.html shows "No admins yet" on Saruba even though
-- migration 012 verification said admin_rows = 1 for cath@coach4u.
--
-- Read-only. Safe to re-run any time.
-- ============================================================================

SELECT
  sa.subscription_id,
  s.name             AS subscription_name,
  s.subscription_type,
  sa.user_id,
  u.email            AS admin_email,
  sa.granted_at,
  sa.granted_by
FROM public.subscription_admins sa
JOIN public.users u         ON u.id = sa.user_id
JOIN public.subscriptions s ON s.id = sa.subscription_id
ORDER BY s.name, u.email;
