# Your Coaching Portal — Claude Code Guide

Single-page hub that signs a Coach4U client in and shows the coaching tools (sub-portals) they have access to. Each tool is its own GitHub Pages site; this repo only does login + landing.

- **Live site:** https://cathcoach4u.github.io/yourcoachingportal/
- **Repo:** `cathcoach4u/yourcoachingportal`
- **Long-lived branch:** `main` (push triggers GitHub Pages deploy)

---

## Purpose

- **One front door for Coach4U clients.** After sign-in, the page lists the client's active coaching portals (with an Open button) and any locked portals (labelled "Contact your coach to unlock").
- **Sub-portals** live in their own repos and open in a new tab.
- **No app data lives here.** Auth + portal lookup happen here; everything else lives in the sub-portal apps.
- Installable as a PWA (manifest, service worker, apple-touch icon).

---

## Stack

- Static `index.html` hosted on GitHub Pages
- Supabase for auth and the `portals` / `client_access` tables
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

Only icons live in code (the `ICONS` object in `index.html`). The Open URL comes from the `portals.url` column in Supabase, so adding a new portal usually doesn't need a code change — just an `insert` into `portals`. Add an entry to `ICONS` if you want a non-default emoji for the new slug; otherwise it falls back to 🔧.

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

### UI invariants (don't reintroduce)

These have been deliberately removed. Don't put them back unless asked.

- No "Welcome back" heading on the login screen.
- The dashboard banner heading (`#welcomeHeading`) is set by JS to `Welcome, [name]`. Its placeholder text in HTML stays empty.
- The header has no subtitle ("Coach4U — Strengths-Based Coaching" lives in the footer only).
- The header has no signed-in user name on the right; the Welcome banner is the single greeting. The top-right of the header is just the Sign Out button.
- All PWA references (`manifest.json`, `icon.svg`, `sw.js`) use **relative** paths so the same files work at the root of any host.
- The Open button URL uses `${p.url || '#'}` to avoid `window.open('undefined')` when a portal has no URL yet.

---

## File structure

```
yourcoachingportal/
├── index.html        login + portal hub, all logic inline
├── manifest.json     PWA manifest (start_url and scope are "./" — path-agnostic)
├── sw.js             service worker (caches index + root, ignores Supabase calls)
├── icon.svg          PWA / apple-touch icon (4U on teal)
├── migrations/       one-off SQL run in the Supabase SQL editor (numbered, idempotent)
├── CLAUDE.md         this file
├── CHANGELOG.md
└── README.md
```

Everything is in one file by design. Don't split into modules unless there's a real reason — GitHub Pages serves ES modules unreliably for this account.

---

## Migrations

Run in numerical order in the Supabase **SQL Editor** (Dashboard → project `eekefsuaefgpqmjdyniy` → SQL Editor → New query → paste → Run). Each migration is idempotent so re-running is safe.

| File | What it does |
|---|---|
| `001_shorten_slugs_and_add_placeholders.sql` | Renames `<name>-coach` slugs to `<name>` in `portals` and `client_access`; seeds `career`, `strengths`, `it` placeholder rows. |
| `002_add_portal_url.sql` | Adds the `portals.url` column and seeds it for the six built portals. |

Add new migrations as `NNN_what_it_does.sql`, numbered next, idempotent (use `if not exists`, `on conflict do nothing`, conditional DDL blocks).

### Granting a client access (one-off SQL, not a tracked migration)

After a client signs up via the login screen, grant them access to one or more portals:

```sql
INSERT INTO client_access (user_id, portal_slug)
SELECT u.id, 'business'
FROM auth.users u
WHERE LOWER(u.email) = LOWER('client@example.com');
```

To revoke, delete the row.

---

## Working with Claude (session protocol)

This project is small and I drive it directly on `main`. The protocol below should be followed in every new session unless I say otherwise.

### Workflow

1. **Branch:** push directly to `main`. No feature branches, no PR review unless I ask. Pages auto-deploys on push.
2. **Commit prefixes:** `feat` `fix` `style` `docs` `data` `chore`.
3. **After every change:** stage → commit → push to `origin main` in the same turn. Don't leave dirty working trees between turns.
4. **Rollback:** `git revert HEAD && git push origin main`.
5. **Migrations are content, not commands.** Adding a `.sql` file to `migrations/` is just a record — the change only takes effect when I paste it into the Supabase SQL editor and run it. Always tell me which migrations need running after any data-shape change.

### Common pitfalls (seen repeatedly — watch for these)

When I paste source from my chat or notes, the paste often arrives with these artefacts. Always strip them before saving:

- **Angle-bracketed URLs:** `<https://example.com>` → `https://example.com`. Affects `<script src>`, `SUPABASE_URL`, `RESET_REDIRECT`, footer link, the SVG `xmlns`.
- **Angle-bracketed identifiers:** `<user.id>` → `user.id`.
- **Stray `>` after emojis:** `'💼>'` → `'💼'`.
- **Footer anchor body:** `<a ...><coach4u.com.au></a>` → `<a ...>coach4u.com.au</a>`.

### When my paste regresses prior fixes

I sometimes paste a full `index.html` from a base draft that doesn't include the cleanups from the last few turns. **Don't blindly overwrite** — diff against the live file and preserve these unless I explicitly ask to revert them:

- Relative PWA paths (no `/yourcoachingportal/...`).
- No "Welcome back" anywhere; empty `#welcomeHeading` placeholder.
- No `.header-sub` line.
- No `#headerName` span / no top-right name on the header.
- `${p.url || '#'}` fallback in the Open button.

If the new paste's only differences from the live file are regressions, say so — don't apply it.

### Sub-portal SSO

All sub-portals are on `cathcoach4u.github.io` and use the same Supabase project, so the session is shared via `localStorage`. Users do **not** re-enter a password when opening a sub-portal — provided the sub-portal calls `sb.auth.getSession()` on load and only shows its login form when there's no session. If a sub-portal moves to a different origin, this breaks.

---

## Sanity checks before claiming a change works

For UI changes I can't drive a browser, I should at minimum:

1. Read the file back and confirm the edit landed.
2. Mentally walk the user-visible flow (login → dashboard → click Open → sign out).
3. State explicitly that I haven't browser-tested.
