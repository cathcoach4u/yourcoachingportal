-- 018: Remove the 'marketing' portal (Your Marketing Coach / Growth Hub).
-- The yourmarketingcoach repo has been deleted (2026-07-17 repo audit): the
-- Growth Hub SPA's entire data layer called a /api backend that never existed
-- on GitHub Pages, and its ai-proxy edge function was never deployed — no
-- client data ever existed. Cath's own marketing lives in the Internal Hub's
-- Marketing Hub. Deleting the portals row cascades to subscription_app_bundle
-- (the business bundle default included 'marketing'); client_access is
-- cleaned explicitly. Idempotent — safe to re-run.

DELETE FROM public.client_access
 WHERE portal_slug = 'marketing';

DELETE FROM public.portals
 WHERE slug = 'marketing';
