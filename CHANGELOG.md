# Changelog

## 2026-05-02 (v10)

- feat: Issue Clarifier — third Global Resource (`resources/issue-clarifier.html`). Five-step wizard (Scope pills → Facts → Impact → Underneath → Real issue with two template hints) plus a journey-summary card, three reflect prompts, and a 1–10 confidence rating against the first small step.

## 2026-05-02 (v9)

- feat: SMART Goal Builder — second Global Resource (`resources/smart-goal.html`). Five-step wizard (S → M → A → R → T) ending with the goal stitched into one natural-reading paragraph (Copy button), a five-letter breakdown, and three reflect prompts.

## 2026-05-02 (v8)

- feat: Strengths Hub gets a Domain Mix grid (4 cards counting Top 10 themes per Gallup domain), plus two collapsible reports — "What each theme means" and "What you bring" — with plain-English descriptions for all 34 themes (`THEME_INFO` in `strengths.html`).
- style: stripped two stray em-dashes from `strengths.html` (page title and banner copy) — reinforces the no-em-dashes brand rule.

## 2026-05-02 (v7)

- fix: defensively filter out `slug === 'coaching-portal'` in `loadPortal()` so the hub never appears as a sub-portal tile inside itself.

## 2026-05-02 (v6)

- style: dashboard hub card headings renamed — "Strengths Hub" → "Your Strengths Hub", "Global Resources" → "Your Access to Global Resources".

## 2026-05-02 (v5)

- feat: Strengths Hub and Global Resources are now dedicated pages (`strengths.html`, `resources.html`) — dashboard hub cards link to them
- feat: first Global Resource — `resources/feelings-chart.html`, a four-step Core → Layer → Nuance → Reflect feelings chart
- refactor: removed inline expandable hub sections from `index.html`; strengths fetch + domain colour map moved into `strengths.html`
- chore: bumped service worker cache to `coaching-portal-v2`; added new HTML pages to ASSETS list
- docs: CLAUDE.md updated for multi-page structure, paste artefact list expanded for markdown-link artefacts in plain text and identifiers with dots

## 2026-05-02

- feat: CliftonStrengths Top 10 panel — fetches from Supabase Edge Function `get-strengths` (cross-project lookup); decoupled from portal render so a 404/timeout never blocks tiles
- style: strengths cards — white bg, 4px left border in Gallup domain colour (Executing #7B2D8B, Influencing #E8622A, Relationship #1F96D3, Strategic #2EAF6E), small domain dot, teal rank, navy theme name
- style: collapsible dashboard sections — Your Strengths (collapsed by default) and Your Tools (expanded, shows active portal count); locked portals tucked inside Your Tools as "Also Available"
- fix: removed `coaching-portal` row from `portals` table (was appearing as its own tile)
- fix: stripped angle-bracket artefacts from all portal URLs in Supabase (`<https://...>` → `https://...`)
- fix: portal render decoupled from strengths fetch — `fetchStrengths` fires async after tiles render
- feat: version stamp + Hard Refresh link in footer (unregisters SW, clears caches, reloads)
- docs: rewrote `CLAUDE.md` — added Edge Function details, domain colours, confirmed portal URLs, collapsible layout invariants, paste artefact list, and full session protocol

## 2026-05-01

- chore: repurposed repo from Business Coach4U EOS app to Your Coaching Portal hub
- feat: single-page login + portal landing in `index.html`, reads `portals` and `client_access` from Supabase
- feat: PWA install — `manifest.json`, `sw.js`, `icon.svg` (4U on teal)
- feat: portal Open URL now read from `portals.url` column; only icons remain in code (`ICONS` map)
- fix: relative PWA paths so `manifest.json`, `icon.svg`, `sw.js` work at any host root
- style: stripped "Welcome back" headings (login + dashboard banner placeholder)
- style: tightened header — removed "Coach4U — Strengths-Based Coaching" subtitle and the duplicate user-name span (the welcome banner is the single greeting)
- data: migration `001_shorten_slugs_and_add_placeholders.sql` — renames `<name>-coach` slugs to `<name>` in `portals` and `client_access`; seeds `career`, `strengths`, `it` placeholder rows
- data: migration `002_add_portal_url.sql` — adds `portals.url` column and seeds the six built portals
- docs: rewrote `CLAUDE.md` and `README.md` for the new app; added session protocol and paste-pitfall notes to `CLAUDE.md`
