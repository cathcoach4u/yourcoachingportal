# Changelog

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
