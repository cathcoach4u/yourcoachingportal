# Your Coaching Portal — Claude Code Guide

Single-page hub that signs a Coach4U client in and shows the coaching tools (sub-portals) they have access to. Each tool is its own GitHub Pages site; this repo only does login + landing.

---

## What this app is

- **Purpose:** One front door for Coach4U clients. After sign-in, the page lists the client's active coaching portals (with an Open button) and any locked portals (with a "Contact your coach to unlock" label).
- **Sub-portals** live in their own repos and are linked out via `target="_blank"`. The mapping from slug to URL/icon is hardcoded in `index.html` under `PORTAL_MAP`.
- **No app data lives here.** Everything except auth + portal lookup happens in the sub-portal apps.

---

## Stack

- Static `index.html` hosted on GitHub Pages
- Supabase for auth and the portal/access tables
- Supabase JS UMD build loaded from jsDelivr (no ES modules, no bundler)

---

## Supabase project

| | |
|---|---|
| URL | `https://eekefsuaefgpqmjdyniy.supabase.co` |
| Anon key | `sb_publishable_pcXHwQVMpvEojb4K3afEMw_RMvgZM-Y` |

### Tables this page reads

- `portals` — one row per coaching tool. Columns used: `slug`, `name`, `description`, `url`, `display_order`, `coming_soon` (bool, filtered to `false`). The `url` is what the Open button opens; null means "not built yet" and the button falls back to `#`.
- `client_access` — grants. Columns used: `user_id`, `portal_slug`. The page reads rows for the signed-in user and treats every matching `portal_slug` as unlocked.

A portal appears as **active** if its slug is present in `client_access` for the user. Otherwise it renders as **locked**.

### Reset password redirect

`RESET_REDIRECT` in `index.html` points at the dashboard repo's `auth.html`. Update it there if the auth handler ever moves.

---

## Portal slug → icon map

Only icons live in code now (the `ICONS` object in `index.html`). The Open URL comes from the `portals.url` column in Supabase, so adding a new portal usually doesn't need a code change — just an `insert` into `portals`. Add an entry to `ICONS` if you want a non-default emoji for the new slug; otherwise it falls back to 🔧.

Current `ICONS` keys:

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

## Brand

- Header / primary buttons / titles: navy `#003366`
- Accent (active card border, links, secondary buttons): teal `#0D9488`, hover `#0F766E`
- App background `#f5f7fa`, cards white
- Font stack: Aptos then system sans
- Tone: warm, professional, Australian English. No exclamation marks, no em-dashes.

---

## File structure

```
yourcoachingportal/
├── index.html        login + portal hub, all logic inline
├── manifest.json     PWA manifest
├── sw.js             service worker (offline shell, ignores Supabase calls)
├── icon.svg          PWA / apple-touch icon
├── migrations/       one-off SQL run in the Supabase SQL editor (numbered, idempotent)
├── CLAUDE.md         this file
├── CHANGELOG.md
└── README.md
```

Everything is in one file by design. Don't split into modules unless there's a real reason — GitHub Pages serves ES modules unreliably for this account.

---

## Granting access (SQL)

After a client signs up via the login screen, grant them access to one or more portals:

```sql
INSERT INTO client_access (user_id, portal_slug)
SELECT u.id, 'business-coach'
FROM auth.users u
WHERE LOWER(u.email) = LOWER('client@example.com');
```

To revoke, delete the row.

---

## Version control

- `main` is the only long-lived branch
- Push to `main` triggers GitHub Pages deploy
- Commit prefixes: `feat` `fix` `style` `docs` `data` `chore`
- Rollback: `git revert HEAD && git push origin main`
