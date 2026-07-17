-- 016: Remove the 'it' portal (Your IT Efficiency Coach).
-- The YourITEfficiencyCoach repo was never built out (its only tool card was a
-- dead link) and is being deleted. Removing the portals row cascades to
-- subscription_app_bundle (FK ON DELETE CASCADE); client_access is cleaned
-- explicitly. Idempotent — safe to re-run.

DELETE FROM public.client_access
 WHERE portal_slug = 'it';

DELETE FROM public.portals
 WHERE slug = 'it';
