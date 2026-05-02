# Your Coaching Portal

Client-facing hub for Coach4U. After signing in, clients land on a dashboard with two side-by-side hub cards (**Your Strengths Hub**, **Your Access to Global Resources**) and a **Your Tools** panel that lists their unlocked sub-portals.

- **Live:** https://cathcoach4u.github.io/yourcoachingportal/
- **Branch:** `main` (push triggers GitHub Pages deploy)
- **Version stamp:** `2026-05-02.10` (in `index.html`, bump on every push)

## Stack

- Static HTML on GitHub Pages, no bundler, no ES modules
- Supabase for auth and the `portals` / `client_access` / `client_strengths` tables
- Supabase Edge Function `get-strengths` (cross-project lookup) for CliftonStrengths data
- Supabase JS UMD via jsDelivr

## Pages

| File | What it does |
|---|---|
| `index.html` | Login + dashboard. Hub cards link to the two hubs; Your Tools shows unlocked sub-portals. |
| `strengths.html` | Strengths Hub. Domain mix visual, Top 10 grid, two collapsible reports (Descriptions, What you bring) covering all 34 themes. |
| `resources.html` | Global Resources hub. Card grid linking into `resources/`. |
| `resources/feelings-chart.html` | Four-step feelings chart (Core → Layer → Nuance → Reflect). |
| `resources/smart-goal.html` | Five-step SMART goal builder with paragraph summary + Copy. |
| `resources/issue-clarifier.html` | Five-step issue clarifier (Scope → Facts → Impact → Underneath → Real issue) with confidence rating. |

Sub-portal HTML pages (Strengths Hub, Global Resources, individual resources) auth-gate via `sb.auth.getSession()` and redirect to `./` if no session. Session is shared across pages via `localStorage` (same Supabase project), so clients do not re-login.

## How the dashboard works

1. Client signs in on `index.html`.
2. The dashboard fetches `portals` (where `coming_soon = false` and `slug != 'coaching-portal'`) and `client_access` for the user.
3. Active portals (slug in `client_access`) render as cards with an Open button. Locked portals render under "Also Available" inside the Your Tools panel.
4. Strengths Hub and Global Resources are accessed via the two top hub cards (separate pages).

The slug → emoji icon map lives in `ICONS` in `index.html`. The Open URL comes from the `portals.url` column in Supabase, so adding a new portal usually only needs a SQL `insert`.

## Granting a client access

```sql
INSERT INTO client_access (user_id, portal_slug)
SELECT u.id, 'business'
FROM auth.users u
WHERE LOWER(u.email) = LOWER('client@example.com');
```

To revoke, delete the row. Admin tooling lives in a separate repo.

See `CLAUDE.md` for the full developer guide, including the Supabase project details, migration order, edge function spec, design system, and session protocol.
