# Your Coaching Portal

Single-page hub for Coach4U clients. After signing in, the page lists the coaching tools (sub-portals) the client has access to and links out to each one.

## Stack

- Static `index.html` hosted on GitHub Pages
- Supabase for auth and the `portals` / `client_access` tables
- Supabase JS UMD build via jsDelivr — no bundler, no modules

## How it works

1. Client lands on `index.html` and signs in (or requests a reset link).
2. The page queries `portals` (where `coming_soon = false`) and `client_access` for the current user.
3. Portals whose slug appears in `client_access` render as active (Open button); the rest render as locked.
4. The slug → URL/icon map lives in `PORTAL_MAP` inside `index.html`.

## Granting a client access

```sql
INSERT INTO client_access (user_id, portal_slug)
SELECT u.id, 'business-coach'
FROM auth.users u
WHERE LOWER(u.email) = LOWER('client@example.com');
```

See `CLAUDE.md` for the full guide, including the current portal slug map and the Supabase project details.
