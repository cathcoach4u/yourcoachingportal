-- ============================================================================
-- 015 — Provision Staff Subscriptions for andrew@coach4u.com.au + contact@coach4u.com.au
-- ============================================================================
--
-- Two-step idempotent SQL:
--   1) For each existing user with these emails, create a
--      subscription with subscription_type='staff' and add them
--      as subscription_admin (the owner is auto-admin).
--   2) Report any of the two emails that DON'T yet exist as users
--      so they can be invited via admin.html first.
--
-- After running, re-run to see the result.  Safe to run repeatedly.
-- ============================================================================


-- ---------------------------------------------------------------------------
-- 1. Create staff subscriptions for any existing user with these emails
-- ---------------------------------------------------------------------------
INSERT INTO public.subscriptions (owner_user_id, name, subscription_type, status)
SELECT u.id,
       split_part(u.email, '@', 1) || ' (Staff)',
       'staff',
       'active'
  FROM public.users u
 WHERE u.email IN ('andrew@coach4u.com.au', 'contact@coach4u.com.au')
   AND NOT EXISTS (
     SELECT 1 FROM public.subscriptions s
      WHERE s.owner_user_id = u.id AND s.subscription_type = 'staff'
   );

-- Auto-admin the owner of every staff sub
INSERT INTO public.subscription_admins (subscription_id, user_id, granted_by)
SELECT s.id, s.owner_user_id, s.owner_user_id
  FROM public.subscriptions s
 WHERE s.subscription_type = 'staff'
ON CONFLICT (subscription_id, user_id) DO NOTHING;

-- Give each staff sub the full live-portal bundle (matches getBundleForSub default)
INSERT INTO public.subscription_app_bundle (subscription_id, portal_slug)
SELECT s.id, p.slug
  FROM public.subscriptions s
  CROSS JOIN public.portals p
 WHERE s.subscription_type = 'staff'
   AND p.coming_soon = false
ON CONFLICT (subscription_id, portal_slug) DO NOTHING;


-- ---------------------------------------------------------------------------
-- 2. Report which emails are still missing as users
-- ---------------------------------------------------------------------------
SELECT email AS missing_user
  FROM (VALUES ('andrew@coach4u.com.au'), ('contact@coach4u.com.au')) AS t(email)
 WHERE email NOT IN (SELECT email FROM public.users);


-- ---------------------------------------------------------------------------
-- 3. Show the staff subscriptions that now exist
-- ---------------------------------------------------------------------------
SELECT s.name           AS subscription,
       u.email          AS owner_email,
       s.subscription_type,
       s.status,
       s.created_at
  FROM public.subscriptions s
  JOIN public.users u ON u.id = s.owner_user_id
 WHERE s.subscription_type = 'staff'
 ORDER BY s.created_at;
