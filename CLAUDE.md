# Business Coach4U — Claude Code Guide

> **Design system version: 1.4**
> This file is self-contained. Do not link to or depend on any other Coach4U repo at runtime.

---

## App-Specific Notes

- **Purpose:** EOS-style business operating system for Coach4U clients. Vision/Traction Organiser, Accountability Chart, Goals (Rocks), Scorecard (Metrics), Weekly Meetings, Issues, Team Alignment.
- **Multi-business:** Single user owns multiple businesses. Holding company sits at the top, sub-businesses roll up.
- **Status:** Auth scaffolding live. All panel logic (`js/app.js`) is to be built in the next phase.
- **AI Coach:** Removed in v1.0. Can be re-added later as an optional sidebar.

---

## Coach4U Brand Standard (locked)

**Fonts**
- Headings: Inter Bold
- Body: Montserrat Regular
- Fallback chain: Inter / Montserrat → Aptos → Calibri → sans-serif

**Colours**
- Dark blue `#1B3664` — titles, headings, primary buttons
- Light blue `#5684C4` — accents, links, highlights
- Dark grey `#2D2D2D` — body text
- Light grey `#DDDDDD` — dividers
- App background `#F8F9FA` — light grey for the dense multi-panel app
- Card background `#FFFFFF` — white

**Tone**
- Warm, professional, clear
- Strengths-based, not clinical
- Australian English
- No exclamation marks, no em-dashes

---

## Supabase Project

| | |
|---|---|
| URL | `https://eekefsuaefgpqmjdyniy.supabase.co` |
| Anon Key | `sb_publishable_pcXHwQVMpvEojb4K3afEMw_RMvgZM-Y` |

---

## Critical Rules

**Supabase init for ES modules — always inline.** GitHub Pages does not reliably load external `.js` modules. Always initialise Supabase inline in a `<script type="module">` block on every page that needs it. Classic `<script src="...">` tags (non-module) are fine to load externally — only ES modules have the loading issue.

**Reset password redirect.** Use `window.location.href` (not `window.location.origin`) when building the `redirectTo` URL. Using `origin` drops the path and breaks Supabase's redirect matching.

**Membership gating.** Every page except `login.html`, `forgot-password.html`, `reset-password.html`, and `inactive.html` must verify `users.membership_status = 'active'` after confirming a session. Redirect to `inactive.html` if not.

**Login subtitle wording locked.** "Sign in to access your account." Do not change.

---

## Login Page Spec — locked v1.4

| Element | Value |
|---|---|
| Background | `linear-gradient(135deg, #1B3664 0%, #5684C4 100%)` |
| Card | White, max 420px wide, 16px radius, 36px 32px padding |
| App name (h1) | Inter Bold, 36px, `#1B3664`, centred |
| Title | Inter Bold, 22px, `#1B3664`, centred — "Welcome back" |
| Subtitle | Montserrat 400, 15px, `#6C757D`, centred — "Sign in to access your account." |
| Labels | Montserrat 600, 14px, `#2D2D2D` |
| Inputs | Montserrat 400, 15px, border `#DDDDDD`, focus `#5684C4`, 8px radius |
| Button | Montserrat 600, 16px, white on `#1B3664`, 8px radius, full width |
| Forgot password link | Montserrat 500, 14px, `#5684C4` |

---

## File Structure

```
business-coach4u/
├── index.html               main app, auth gate inline at top
├── login.html               sign in
├── forgot-password.html     reset request
├── reset-password.html      set new password
├── inactive.html            shown if membership_status != 'active'
├── manifest.json            PWA manifest
├── sw.js                    service worker
├── js/
│   └── app.js               panel logic (to be built)
├── migrations/
│   └── 001_create_users_table.sql
├── icons/
│   ├── icon-192.png         (to add)
│   └── icon-512.png         (to add)
├── CLAUDE.md                this file
└── CHANGELOG.md
```

---

## Sign Out — Standard Placement

Top-right of the header on every authenticated page. Already wired in `index.html`:

```html
<button class="sign-out-btn" onclick="window.signOut()">Sign Out</button>
```

`window.signOut` is defined in the auth gate at the top of `index.html`.

---

## Add a New Member (SQL)

Run in the Supabase SQL editor after the user has signed up:

```sql
INSERT INTO users (id, email, membership_status)
SELECT id, email, 'active'
FROM auth.users
WHERE LOWER(email) = LOWER('email@here.com');
```

---

## Version Control

### Git workflow

- `main` is the only long-lived branch
- Commit directly for small fixes; branch for larger work
- Every push to `main` triggers GitHub Pages deploy

### Commit message format

```
<type>: <short summary>
```

Types: `feat` `fix` `style` `docs` `data` `chore`

### Service worker cache busting

Every meaningful deploy: bump `'business-coach4u-v1'` → `v2` in `sw.js`.

### Rollback

```bash
git revert HEAD
git push origin main
```

---

## Next Phase — Building `js/app.js`

When ready to build the panel logic, hand Claude Code each panel one at a time. Suggested order:

1. **Business switcher** — load businesses, switch active business, persist selection
2. **Panel switching** — clicking nav tabs shows/hides panels
3. **VTO** — load and save Vision/Traction Organiser fields per business
4. **Accountability Chart** — render org tree, seat CRUD
5. **Goals (Rocks)** — quarterly priorities CRUD, progress calculation
6. **Scorecard (Metrics)** — metric CRUD, weekly cell editing
7. **Issues** — kanban CRUD, status moves
8. **Weekly Meetings** — meeting CRUD, agenda accordion, todo/headline tracking
9. **Team Alignment** — rating cells, GWC scoring, summary calculation
10. **Vision banner** — populate from VTO data, collapse/expand

Each panel will need its own Supabase migration (e.g. `002_create_businesses_table.sql`, `003_create_vto_table.sql` etc.). Build the migration, run it, then build the panel logic.
