# Your Coaching Portal — Claude Code Guide

The Coach4U **client-facing** portal. Handles sign-in, the dashboard, the in-house **Strengths Hub** (CliftonStrengths reports), and the **free coaching resources** (Feelings Chart, SMART Goal Builder, Issue Clarifier). Also the source of truth for the Supabase migrations and the `get-strengths` Edge Function contract.

Sub-portals (business, team, marketing, etc.) live in their own GitHub Pages repos and are linked from the dashboard via rows in the `portals` table. They share the same Supabase project so auth carries across via `localStorage` (no re-login).

- **Live site:** https://cathcoach4u.github.io/yourcoachingportal/
- **Repo:** `cathcoach4u/yourcoachingportal`
- **Long-lived branch:** `main` (push triggers GitHub Pages deploy)
- **Current version stamp:** `2026-05-02.28` (bump `VERSION` const in `index.html` on every push)

---

## Two Design Systems

This repo uses two separate design systems. Use the right one — do not mix them.

| | Dashboard | Activity |
|---|---|---|
| CSS file | `css/style.css` | `css/activity.css` |
| Font | Aptos system stack (no Google Fonts) | Inter + Montserrat (Google Fonts required) |
| Primary colour | `#003366` navy | `#1B3664` dark blue |
| Accent | `#0D9488` teal | `#5684C4` mid blue |
| CSS prefix | none | `act-` |
| Used for | Dashboard, auth, Strengths Hub pages | All pages under `resources/` |

**What is an activity?** A page where the user produces a personal output through interaction — selections, reflections, multi-step flows. Static or informational pages are NOT activities and use the dashboard system.

Both stylesheets are copied from `coach4u-shared`. Each app owns its own local copy — do not link to the shared repo live.

---

## What this repo owns vs what lives elsewhere

**Owned here (change in this repo):**

- Login flow, password reset, dashboard layout (`index.html`).
- **Strengths Hub** landing (`coach4u-tools.html`) and the **CliftonStrengths** sub-page (`coach4u-tools/strengths-clifton.html`) — including the `THEME_INFO` content for all 34 themes, domain mapping, and Edge Function call.
- All **free resources** under `resources/` (Feelings Chart, SMART Goal Builder, Issue Clarifier) and the directory page `resources.html`.
- PWA assets (`manifest.json`, `sw.js`, `icon.svg`).
- All Supabase **migrations** under `migrations/`. SQL is run manually in the Supabase SQL editor; this folder is the audit trail.
- The **contract** for the `get-strengths` and `get-coaching-relationship` Edge Functions (endpoint, request/response shape) is documented here even though the function code itself is deployed inside Supabase.

**Lives elsewhere — do NOT change here:**

- Sub-portals (business, team, marketing, life, relationship, thrivehq, strengths). Each is its own GitHub Pages repo. The dashboard links to them via the `portals.url` column.
- Coach-side admin UI for granting `client_access` and populating `client_strengths`. Separate repo writing to the same Supabase project.
- The deployed `get-strengths` and `get-coaching-relationship` Edge Function code (both live in this Supabase project as functions; the secret env-vars they need stay there too).

**"Coach4U Tools" specifically:** the Strengths Hub, and any future Coach4U-built tools, are surfaced on the dashboard as gated tiles in the **Your Coach4U Tools** section. Routing is controlled by the `COACH4U_SLUGS` set in `index.html` plus a row in the `portals` table whose `url` points at an in-repo HTML file (e.g. `coach4u-tools.html`). Access is gated by `client_access` like every other portal.

---

## Purpose

- **One front door for Coach4U clients.** After sign-in, the dashboard shows three free-resource tiles (Feelings Chart, SMART Goal Builder, Issue Clarifier) at the top, then the **Your Tools** panel. Active portals have an Open button; locked ones say "Contact your coach to unlock".
- **Sub-portals** live in their own repos and open in a new tab.
- **Strengths Hub** is a dedicated page in this repo (`coach4u-tools.html`), surfaced via a gated `coach4u-tools` portal tile inside the Your Tools grid (existing-client only).
- **Global Resources** (`resources.html`) is still in the repo as a directory page for the free tools, but the dashboard links to each tool directly now.
- **No app data lives here.** Auth + portal lookup happen here; everything else lives in the sub-portal apps.
- Installable as a PWA (manifest, service worker, apple-touch icon).

---

## Stack

- Static `index.html` hosted on GitHub Pages
- Supabase for auth and the `portals` / `client_access` / `client_strengths` tables
- Supabase Edge Functions (`get-strengths`, `get-coaching-relationship`) for fetching client data cross-project
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

### Edge Functions

#### `get-strengths`

- **Endpoint:** `${SUPABASE_URL}/functions/v1/get-strengths`
- Called with `Authorization: Bearer <access_token>` (the session token, not the anon key).
- Returns `{ strengths: ["Strategic", "Learner", ...] }` — an ordered array of theme names.
- Lives in the **admin Supabase project** (separate from this hub's project); it does a cross-project lookup using `hub_profile_id`.
- Fetched async and decoupled from portal render — a failing edge function never blocks the tile grid. Uses an 8-second AbortController timeout; returns `[]` on any failure.
- If a client has no strengths data the `strengthsSection` div stays hidden entirely.

#### `get-coaching-relationship`

- **Endpoint:** `${SUPABASE_URL}/functions/v1/get-coaching-relationship`
- Called with `Authorization: Bearer <access_token>` AND `apikey: <SUPABASE_ANON>` headers. Both are required because the function is deployed with `verify_jwt: true` (Supabase default).
- Returns `{ groups: [{ role, relationship_name, members: [...] }, ...] }`. The logged-in user is filtered out of each `members` array server-side.
- **Secrets stay server-side.** The function holds the Internal Hub URL + service-role key as Supabase env-vars; do NOT bring that key into this repo. The client only ever sends its session JWT.
- Function-side env vars are configured in the Supabase Dashboard (Project Settings → Edge Functions → Secrets). The function source must reference the secrets by their **exact** names. Mismatched names make the outbound call to the Internal Hub silently hang (no error, just times out). If a future invocation hangs, check Supabase logs for `reason: EarlyDrop` with very low `cpu_time_used` (e.g. 11ms) — that's the signature.
- Used by `coach4u-tools/coaching-admin.html`. 10-second AbortController + graceful fallback pattern — a failing function shows a friendly error state, not a broken page.

### Confirmed portal URLs (as at 2026-05-04)

| Slug | URL |
|---|---|
| `business` | https://cathcoach4u.github.io/yourbusinesscoach/ |
| `team` | https://cathcoach4u.github.io/yourteamcoach/ |
| `marketing` | https://cathcoach4u.github.io/yourmarketingcoach/ |
| `life` | https://cathcoach4u.github.io/coach4Uapp-dashboard/personal/ |
| `relationship` | https://cathcoach4u.github.io/yourrelationshipcoach/ |
| `thrivehq` | https://cathcoach4u.github.io/yourthrivehqcoach/ |
| `strengths` | https://cathcoach4u.github.io/yourstrengthscoach/ |
| `coach4u-tools` | `coach4u-tools.html` (relative — opens the in-repo Coach4U Tools landing) |
| `career` | null (not built yet) |
| `it` | https://cathcoach4u.github.io/YourITEfficiencyCoach/ |

Note: the `coaching-portal` row was deleted from the `portals` table — it was appearing as its own tile.

### Reset password redirect

`RESET_REDIRECT` in `index.html` points at `https://cathcoach4u.github.io/yourcoachingportal/index.html`. This explicit override is kept in code because the Supabase project is shared across multiple apps — without it, Supabase would use the project-level Site URL which may point elsewhere. Ensure this URL is also listed in Supabase → **Authentication → URL Configuration → Redirect URLs**; Supabase will reject the redirect if it isn't. Update the constant if the post-reset landing page ever changes.

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
| `coach4u-tools` | 💪 |
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

## Brand — Dashboard pages

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
- Dashboard layout uses **collapsible panels** (see below) — do not revert to a flat always-visible card dump.
- **`body` has no `display: flex` / `flex-direction: column`**. Sticky footer is achieved via `footer { position: sticky; top: 100vh }`. Login and loading panels use `min-height: calc(100vh - 120px)` for vertical centering.
- **Welcome banner gradient is navy → teal**: `linear-gradient(135deg, #003366 0%, #0D9488 100%)`. Do not revert to all-navy (`#005599` as the end stop).
- **Free resource card borders are teal `#0D9488` at rest** — do not revert to grey `#eee`.
- **Card icon background is `rgba(13,148,136,0.1)`** — do not hardcode `#e6f4f1`.
- **Sign-out button class is `.sign-out-btn`** (not `.logout-btn`).
- **Portal card grid class is `.app-grid`** (not `.cards-grid`).
- **Section toggle icons use `.section-toggle-icon`** class — no inline `style="font-size:20px"` on the emoji spans.

### Security invariants (don't regress)

- **Supabase JS is loaded with a pinned version + SRI hash**. The `<script>` tag in `index.html`, `coach4u-tools.html`, `coach4u-tools/strengths-clifton.html`, `coach4u-tools/coaching-admin.html`, and `resources.html` looks like `<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@<version>/dist/umd/supabase.min.js" integrity="sha384-..." crossorigin="anonymous"></script>`. When bumping the version, recompute the integrity hash in **all five files**:

  ```bash
  V=2.105.1 && curl -sL "https://cdn.jsdelivr.net/npm/@supabase/supabase-js@${V}/dist/umd/supabase.min.js" \
    | openssl dgst -sha384 -binary | openssl base64 -A
  ```

- **Portal-card render escapes user-supplied DB strings** (`p.name`, `p.description`) and **validates `p.url`** before opening (`safePortalUrl()` allows `https://...` and relative `*.html` only). Any rewrite of `renderPortals()` must keep both. The Open control is a real `<a href target="_blank" rel="noopener noreferrer">`, not an inline `onclick="window.open(...)"`.
- **CliftonStrengths render escapes theme names and theme text** before injecting via `innerHTML` (`escapeHtml()` helper).
- **No service-role key in this repo, ever.** Only the publishable anon key (`SUPABASE_ANON`). The service role lives in the admin project.

### Dashboard layout

The portal content area (`#portalWrap`) renders these in order after the welcome banner:

1. **Free resources row** (`.free-resources-row`) — three anchor links (`<a class="free-resource-card">`), no heading. Visible to every signed-in user:
   - **Feelings Chart** → `resources/feelings-chart.html` (💗)
   - **SMART Goal Builder** → `resources/smart-goal.html` (🎯)
   - **Issue Clarifier** → `resources/issue-clarifier.html` (🧭)
2. **Your Coach4U Tools** (`#coach4uSection`) — collapsible toggle, hidden entirely for clients with no active Coach4U-built tools. Content: active tiles only (`#coach4uPortals`), no locked variant. Slugs that route here are listed in `COACH4U_SLUGS` (`new Set(['coach4u-tools'])`). The Strengths Hub renders here for clients with `client_access` to `coach4u-tools`.
3. **Your Tools** (`#activeSection`) — collapsible toggle, **expanded by default** (chevron starts `.open`). Sub-label shows active portal count, e.g. "3 active portals". Content: active portal cards (`#activePortals`) then a tucked "Also Available" sub-section (`#lockedSection`) for locked portals. Coach4U-tool slugs are filtered OUT of this section — they render in `#coach4uSection` above.

Toggle function: `toggleSection(bodyId, chevronId)` — flips `display` and toggles the `.open` class on the chevron.

`loadPortal()` filters out `slug === 'coaching-portal'` defensively (the hub itself shouldn't appear as a sub-portal tile inside itself).

### Strengths Hub and Global Resources pages

`coach4u-tools.html` and `resources.html` use the **dashboard design system** (Aptos / navy / teal, `css/style.css`). Each has a header with a "← Back" link.

Tools under `resources/` use the **activity design system** — `css/activity.css`, `act-*` CSS classes, Inter + Montserrat fonts, `--act-*` CSS variables (`#1B3664` dark blue, `#5684C4` mid blue). Add `class="activity-page"` to `<body>` and link both Google Fonts and `../css/activity.css` (note `../` since these files are one level inside `resources/`).

- **`coach4u-tools.html`** — Strengths Hub landing. Page banner + a grid of `<a class="hub-tile">` boxes, one per Coach4U-built strengths tool. Currently holds a single tile that navigates to `coach4u-tools/strengths-clifton.html`. Auth-gated; redirects to `./` if no session. Future strengths tools sit alongside as more `.hub-tile` boxes — no DB changes needed.
- **`coach4u-tools/strengths-clifton.html`** — CliftonStrengths page. Page banner followed by four collapsible toggles: **Your Domain Mix** (default open), **Your Top 10** (default closed), **What each theme means** (default closed), **What you bring** (default closed). Owns `DOMAIN_BY_THEME`, `DOMAIN_LABEL`, `STRENGTHS_ENDPOINT`, `fetchStrengths`, `renderStrengths`, `renderDomainMix`, `renderReports`, and the `THEME_INFO` object covering all 34 themes (description + brings per theme). Back arrow returns to `coach4u-tools.html`.
- **`coach4u-tools/coaching-admin.html`** — "Existing Coaching Admin" page. Page banner reads "🔗 Your Coaching Relationship". Calls the `get-coaching-relationship` Edge Function with the user's session token, then renders one card per coaching group: a green role pill (Individual / Couple / Organisation), a blue relationship-name pill, and an unstyled list of any other members. Loading / empty / error states are handled in-page. No secrets in the file — the Edge Function is the only thing that holds the Internal Hub service-role key.
- **`resources.html`** — listing page for client-facing tools. Each tool is an `<a class="resource-card">` linking into the `resources/` subdirectory. Auth-gated.
- **`resources/<tool>.html`** — individual activity tool pages. Three currently:
  - **`feelings-chart.html`** — 4-step (Core → Layer → Nuance → Reflect) feelings naming wizard with multi-select at every step.
  - **`smart-goal.html`** — 5-step SMART goal builder. Final card stitches inputs into one paragraph (`I will [S] by [T]. This is achievable because [A]. I will measure progress by [M]. This matters to me because [R].`) with a Copy button, plus a five-letter breakdown and three reflect prompts.
  - **`issue-clarifier.html`** — 5-step issue clarifier (Scope pills → Facts → Impact → Underneath → Real issue with two template hints). Summary shows the journey from scope to core in a 5-row card with the real issue highlighted in the navy gradient banner. Includes 3 reflect prompts and a 1–10 confidence rating against the first small step.

`coach4u-tools.html`, `coach4u-tools/strengths-clifton.html`, `coach4u-tools/coaching-admin.html`, and `resources.html` auth-gate via `sb.auth.getSession()` and redirect to `./` (or `../` for files in the `coach4u-tools/` subdir) if no session. Tools under `resources/` are self-contained content (no Supabase calls) and don't auth-gate — public access via direct URL is fine. Shared session via `localStorage` (same Supabase project) means the user does not re-login when navigating between gated pages.

### Adding a new resource

1. Create `resources/<slug>.html`. Use the **activity design system**: `<body class="activity-page">`, link Google Fonts + `../css/activity.css`, use `act-*` CSS classes. Add a small page-specific `<style>` block only for components not covered by `activity.css`. Add a `← Back to Coaching Portal` link using `.act-back-link` at the top.
2. Add a matching `<a class="resource-card">` to `resources.html` (icon, title, description, link arrow).
3. Update `sw.js` `ASSETS` list to include the new file path.
4. Bump `sw.js` `CACHE` version (e.g. `coaching-portal-v5`) so old caches clear on next visit.
5. Bump `VERSION` in `index.html` and push to `main`.

### Adding a new Coach4U Tool (deep page under the Coach4U Tools landing)

Convention: every Coach4U-built deep page lives at `coach4u-tools/<slug>.html` so its URL reads `https://cathcoach4u.github.io/yourcoachingportal/coach4u-tools/<slug>.html`. Examples to follow: `coach4u-tools/strengths-clifton.html`. Future tools (e.g. Pulse Reports → `coach4u-tools/pulse-reports.html`) drop in alongside.

1. Create `coach4u-tools/<slug>.html`. These are dashboard-system pages — use the Aptos / navy / teal system from `css/style.css`. Copy the structure from `coach4u-tools/strengths-clifton.html` (header with back arrow, page banner, content area, footer, Supabase init).
2. Inside that file the relative paths are one level deeper than root files. Use `../manifest.json`, `../icon.svg`, `../sw.js`, and `location.href = '../'` for redirects. The back arrow goes to `../coach4u-tools.html`.
3. Add a matching `<a class="hub-tile">` to `coach4u-tools.html` (the landing) with `href="coach4u-tools/<slug>.html"` and an icon, title, description, arrow.
4. Use the same Supabase script tag (pinned version + SRI hash + `crossorigin="anonymous"`) used in the other gated pages — see "Security invariants" above.
5. Update `sw.js` `ASSETS` to include `./coach4u-tools/<slug>.html`. Bump the `CACHE` version.
6. Bump `VERSION` in `index.html`. No DB / migrations needed — the `coach4u-tools` portal slug already routes the dashboard tile to `coach4u-tools.html`, and access stays gated by the existing `client_access` row.

---

## File structure

```
yourcoachingportal/
├── index.html                login + dashboard (free resources row + Coach4U Tools + Your Tools)
├── coach4u-tools.html        Coach4U Tools landing — boxes for each Coach4U-built tool
├── coach4u-tools/            deep pages for each Coach4U-built tool
│   ├── strengths-clifton.html  CliftonStrengths content (Domain Mix + Top 10 + 2 reports)
│   └── coaching-admin.html     "Your Coaching Relationship" — calls get-coaching-relationship
├── css/
│   ├── style.css             Dashboard design system (navy/teal, Aptos) — copied from coach4u-shared
│   └── activity.css          Activity design system (dark-blue/mid-blue, Inter/Montserrat) — copied from coach4u-shared
├── resources.html            Global Resources hub — lists client-facing tools
├── resources/
│   ├── feelings-chart.html   4-step feelings chart (activity design system)
│   ├── smart-goal.html       5-step SMART goal builder (activity design system)
│   └── issue-clarifier.html  5-step issue clarifier (activity design system)
├── manifest.json             PWA manifest (start_url and scope are "./" — path-agnostic)
├── sw.js                     service worker (caches all HTML pages, ignores Supabase calls)
├── icon.svg                  PWA / apple-touch icon (4U on teal #0D9488, 512×512)
├── migrations/               one-off SQL run in the Supabase SQL editor (numbered, idempotent)
├── CLAUDE.md                 this file
├── CHANGELOG.md
└── README.md
```

Dashboard pages (`index.html`, `coach4u-tools.html`, etc.) have their own inline `<style>` and `<script>` — no shared CSS for these by design (no bundler, no ES modules — GitHub Pages serves ES modules unreliably for this account). Activity pages under `resources/` use the shared `css/activity.css` stylesheet.

When adding new HTML pages, update `sw.js` ASSETS list and bump the `CACHE` version (e.g. `coaching-portal-v3`) so old caches clear on next visit.

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
| `006_add_coach4u_tools_portal.sql` | Adds the `coach4u-tools` portal row (originally pointing at `strengths.html`, now `coach4u-tools.html` via 007). |
| `007_rename_coach4u_tools_url.sql` | Repoints the `coach4u-tools` portal `url` from `strengths.html` to `coach4u-tools.html` after the file was renamed. |
| `008_set_it_portal_url.sql` | Sets the `it` portal URL to `https://cathcoach4u.github.io/YourITEfficiencyCoach/`. |

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
- **Markdown link artefacts in code:** `[user.id](http://user.id)` → `user.id`. Also affects any plain-word identifier with a dot, like `[link.id](http://link.id)`, `[arr.map](http://arr.map)`, `[obj.prop](http://obj.prop)`.
- **Markdown link artefacts in text:** `[www.coach4u.com.au](http://www.coach4u.com.au)` → wrap in a real `<a href>` instead. Same with email addresses like `[cath@coach4u.com.au](mailto:cath@coach4u.com.au)` → `<a href="mailto:cath@coach4u.com.au">cath@coach4u.com.au</a>`.

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
- No `display: flex; flex-direction: column` on `body` — footer uses `position: sticky; top: 100vh`.
- Welcome banner gradient ends in `#0D9488` teal, not `#005599`.
- Free resource card border is `#0D9488` at rest, not `#eee`.
- Card icon background is `rgba(13,148,136,0.1)`, not `#e6f4f1`.
- Sign-out button class is `.sign-out-btn`, not `.logout-btn`.
- Portal card grid class is `.app-grid`, not `.cards-grid`.
- Section toggle icons use class `.section-toggle-icon`, not inline `style="font-size:20px"`.
- `RESET_REDIRECT` points at `https://cathcoach4u.github.io/yourcoachingportal/index.html`.

If the new paste's only differences are regressions, say so — don't apply it.

---

## Sanity checks before claiming a change works

For UI changes (can't drive a browser):

1. Read the file back and confirm the edit landed.
2. Mentally walk the user flow: login → welcome banner → free resources row → Your Coach4U Tools panel (only visible if granted) → Your Tools panel → click a tile → sign out.
3. If touching the Strengths Hub: also walk dashboard → Your Coach4U Tools tile → Strengths Hub landing → CliftonStrengths box → back arrow returns to hub → back returns to dashboard.
4. State explicitly that I haven't browser-tested.
