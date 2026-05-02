# Your Coaching Portal — Claude Code Guide

Single-page hub that signs a Coach4U client in and shows the coaching tools (sub-portals) they have access to, plus their CliftonStrengths Top 10. Each tool is its own GitHub Pages site; this repo only does login + landing.

- **Live site:** https://cathcoach4u.github.io/yourcoachingportal/
- **Repo:** `cathcoach4u/yourcoachingportal`
- **Long-lived branch:** `main` (push triggers GitHub Pages deploy)
- **Current version stamp:** `2026-05-02.3` (bump `VERSION` const in `index.html` on every push)

---

## Purpose

- **One front door for Coach4U clients.** After sign-in, the page shows two collapsible panels: Your Strengths and Your Tools. Active portals have an Open button; locked ones say "Contact your coach to unlock".
- **Sub-portals** live in their own repos and open in a new tab.
- **No app data lives here.** Auth + portal lookup happen here; everything else lives in the sub-portal apps.
- Installable as a PWA (manifest, service worker, apple-touch icon).

---

## Stack

- Static `index.html` hosted on GitHub Pages
- Supabase for auth and the `portals` / `client_access` / `client_strengths` tables
- Supabase Edge Function (`get-strengths`) for fetching CliftonStrengths data cross-project
- Supabase JS UMD build loaded from jsDelivr (no ES modules, no bundler)

---

## Supabase project

| | |
|---|---|
| URL | `https://eekefsuaefgpqmjdyniy.supabase.co` |
| Anon key | `sb_publishable_pcXHwQVMpvEojb4K3afEMw_RMvgZM-Y` |

### Tables this page reads

- `portals` — one row per coaching tool. Columns: `slug`, `name`, `description`, `url`, `display_order`, `coming_soon` (bool, filtered to `false`). The `url` is what the Open button opens; null falls back to `#`.
- `client_access` — grants. Columns: `user_id`, `portal_slug`. The page reads rows for the signed-in user; every matching slug is unlocked.
- `client_strengths` — per-client Gallup themes. Columns: `user_id`, `rank`, `theme`. Read via the Edge Function, not directly.

A portal is **active** if its slug is in `client_access` for the user. Otherwise it renders as **locked**.

### Edge Function: `get-strengths`

- **Endpoint:** `${SUPABASE_URL}/functions/v1/get-strengths`
- Called with `Authorization: Bearer <access_token>` (the session token, not the anon key).
- Returns `{ strengths: ["Strategic", "Learner", ...] }` — an ordered array of theme names.
- Lives in the **admin Supabase project** (separate from this hub's project); it does a cross-project lookup using `hub_profile_id`.
- Fetched async and decoupled from portal render — a failing edge function never blocks the tile grid. Uses an 8-second AbortController timeout; returns `[]` on any failure.
- If a client has no strengths data the `strengthsSection` div stays hidden entirely.

### Confirmed portal URLs (as at 2026-05-02)

| Slug | URL |
|---|---|
| `business` | https://cathcoach4u.github.io/yourbusinesscoach/ |
| `team` | https://cathcoach4u.github.io/yourteamcoach/ |
| `marketing` | https://cathcoach4u.github.io/yourmarketingcoach/ |
| `life` | https://cathcoach4u.github.io/coach4Uapp-dashboard/personal/ |
| `relationship` | https://cathcoach4u.github.io/yourrelationshipcoach/ |
| `thrivehq` | https://cathcoach4u.github.io/yourthrivehqcoach/ |
| `strengths` | https://cathcoach4u.github.io/yourstrengthscoach/ |
| `career` | null (not built yet) |
| `it` | null (not built yet) |

Note: the `coaching-portal` row was deleted from the `portals` table — it was appearing as its own tile.

### Reset password redirect

`RESET_REDIRECT` in `index.html` points at the dashboard repo's `auth.html`. Update it there if the auth handler ever moves.

---

## Portal slug → icon map

Only icons live in code (the `ICONS` object in `index.html`). The Open URL comes from `portals.url` in Supabase, so adding a new portal usually only needs an `insert` into `portals`. Add to `ICONS` for a custom emoji; otherwise falls back to 🔧.

| Slug | Icon |
|---|---|
| `business` | 💼 |
| `team` | 👥 |
| `marketing` | 📈 |
| `life` | 🌱 |
| `relationship` | ❤️ |
| `thrivehq` | ⚡ |
| `career` | 🎯 |
| `strengths` | 💪 |
| `it` | 💻 |

---

## CliftonStrengths domain colours (Gallup standard)

Used for the left border and domain dot on each strength card.

| Domain | Colour |
|---|---|
| Executing | `#7B2D8B` (purple) |
| Influencing | `#E8622A` (orange) |
| Relationship Building | `#1F96D3` (blue) |
| Strategic Thinking | `#2EAF6E` (green) |

CSS classes: `.domain-executing`, `.domain-influencing`, `.domain-relationship`, `.domain-strategic`.

---

## Brand

- Header / primary buttons / titles: navy `#003366`
- Accent (active card border, links, secondary buttons): teal `#0D9488`, hover `#0F766E`
- App background `#f5f7fa`, cards white
- Font stack: Aptos then system sans
- Tone: warm, professional, Australian English. No exclamation marks, no em-dashes.

### UI invariants (don't reintroduce)

These have been deliberately removed or set. Don't change unless asked.

- No "Welcome back" heading anywhere. The dashboard banner (`#welcomeHeading`) is set by JS to `Welcome, [name]`; its HTML placeholder stays empty.
- The header has no subtitle — "Coach4U — Strengths-Based Coaching" is footer-only.
- The header has no signed-in user name on the right — just the Sign Out button. The welcome banner is the sole greeting.
- All PWA references (`manifest.json`, `icon.svg`, `sw.js`) use **relative** paths — no `/yourcoachingportal/...` prefix.
- The Open button URL uses `${p.url || '#'}` to avoid `window.open('undefined')`.
- Dashboard layout uses **collapsible panels** (see below) — do not revert to a flat always-visible card dump.

### Dashboard layout — collapsible sections

The portal content area (`#portalWrap`) has two toggle panels after the welcome banner:

1. **Your Strengths** (`#strengthsSection`) — hidden until strengths data loads; collapsed by default. Header shows 💪 icon. Content is a 2-column strengths grid (`#strengthsList`).
2. **Your Tools** (`#activeSection`) — always visible; **expanded by default** (chevron starts `.open`). Sub-label shows active portal count, e.g. "3 active portals". Content: active portal cards (`#activePortals`) then a tucked "Also Available" sub-section (`#lockedSection`) for locked portals.

Toggle function: `toggleSection(bodyId, chevronId)` — flips `display` and toggles the `.open` class on the chevron.

---

## File structure

```
yourcoachingportal/
├── index.html        login + portal hub, all logic inline
├── manifest.json     PWA manifest (start_url and scope are "./" — path-agnostic)
├── sw.js             service worker (caches index + root, ignores Supabase calls)
├── icon.svg          PWA / apple-touch icon (4U on teal #0D9488, 512×512)
├── migrations/       one-off SQL run in the Supabase SQL editor (numbered, idempotent)
├── CLAUDE.md         this file
├── CHANGELOG.md
└── README.md
```

Everything is in one file by design. Don't split into modules — GitHub Pages serves ES modules unreliably for this account.

---

## Migrations

Run in numerical order in the Supabase **SQL Editor** (Dashboard → project `eekefsuaefgpqmjdyniy` → SQL Editor → New query → paste → Run). Each is idempotent so re-running is safe.

| File | What it does |
|---|---|
| `001_shorten_slugs_and_add_placeholders.sql` | Renames `<name>-coach` slugs to `<name>` in `portals` and `client_access`; seeds `career`, `strengths`, `it` placeholder rows. |
| `002_add_portal_url.sql` | Adds the `portals.url` column and seeds it for the six built portals (original URLs — superseded by 005). |
| `003_create_client_strengths.sql` | Creates `client_strengths` (user_id, rank, theme) with RLS so each client reads only their own rows. |
| `004_set_strengths_url.sql` | Points the `strengths` portal at `https://cathcoach4u.github.io/yourstrengthscoach/`. |
| `005_update_portal_urls_v2.sql` | Repoints business, team, marketing, relationship, thrivehq at renamed repos (`yourbusinesscoach`, `yourteamcoach`, etc.). |

Add new migrations as `NNN_what_it_does.sql`, numbered next, idempotent.

### Granting a client portal access (one-off SQL, not a tracked migration)

```sql
INSERT INTO client_access (user_id, portal_slug)
SELECT u.id, 'business'
FROM auth.users u
WHERE LOWER(u.email) = LOWER('client@example.com');
```

To revoke, delete the row. The admin repo handles this via UI — don't build admin UI here.

---

## Admin tooling lives elsewhere

This repo is the **client-facing** portal only. The coach-side admin (granting `client_access`, populating `client_strengths`, reading CliftonStrengths data) is a separate repo writing to the same Supabase project. Don't add admin UI here unless explicitly asked.

---

## Sub-portal SSO

All sub-portals are on `cathcoach4u.github.io` and share the same Supabase project, so the session is shared via `localStorage`. Clients do **not** re-enter a password when opening a sub-portal — provided each sub-portal calls `sb.auth.getSession()` on load and only shows its login form when there's no active session. If a sub-portal moves to a different origin, this breaks.

---

## Working with Claude (session protocol)

This project is small and I drive it directly on `main`. Follow this protocol in every session unless I say otherwise.

### Workflow

1. **Branch:** push directly to `main`. No feature branches, no PR review unless I ask. Pages auto-deploys on push.
2. **Commit prefixes:** `feat` `fix` `style` `docs` `data` `chore`.
3. **After every change:** stage → commit → push to `origin main` in the same turn. Don't leave dirty working trees.
4. **Bump `VERSION`** in `index.html` on every push (format `YYYY-MM-DD.N`).
5. **Rollback:** `git revert HEAD && git push origin main`.
6. **Migrations are content, not commands.** Adding a `.sql` file is just a record — the change only takes effect when I paste it into the Supabase SQL editor and run it. Always tell me which migrations need running after any data-shape change.

### Common paste artefacts (strip before saving every time)

When I paste source from my chat or notes it often arrives with these. Always strip them:

- **Angle-bracketed URLs:** `<https://example.com>` → `https://example.com`. Affects `<script src>`, `SUPABASE_URL`, `RESET_REDIRECT`, footer link, SVG `xmlns`.
- **Angle-bracketed identifiers:** `<user.id>` → `user.id`.
- **Stray `>` after emojis:** `'💼>'` → `'💼'`.
- **Footer anchor body:** `<a ...><coach4u.com.au></a>` → `<a ...>coach4u.com.au</a>`.
- **Markdown link artefacts in code:** `[user.id](http://user.id)` → `user.id`.

### When a paste regresses prior fixes

I sometimes paste a full `index.html` from a base draft that doesn't include recent cleanups. **Don't blindly overwrite** — diff against the live file and preserve these unless I explicitly ask to revert:

- Relative PWA paths (no `/yourcoachingportal/...`).
- No "Welcome back" anywhere; empty `#welcomeHeading` placeholder.
- No `.header-sub` line.
- No `#headerName` span.
- `${p.url || '#'}` fallback in the Open button.
- Collapsible section toggle structure (`.section-toggle`, `.section-body`, `toggleSection()`).
- Strengths fetched async and decoupled from portal render.
- `VERSION` const and `hardRefresh()` in footer.

If the new paste's only differences are regressions, say so — don't apply it.

---

## Sanity checks before claiming a change works

For UI changes (can't drive a browser):

1. Read the file back and confirm the edit landed.
2. Mentally walk the user flow: login → welcome banner → two collapsed/expanded panels → open a portal → sign out.
3. State explicitly that I haven't browser-tested.
