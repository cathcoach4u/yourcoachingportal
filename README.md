# Business Coach4U

EOS-style business operating system for Coach4U clients.

Vision/Traction Organiser, Accountability Chart, Goals, Scorecard, Weekly Meetings, Issues, Team Alignment.

## Stack

- Static HTML/CSS/JS hosted on GitHub Pages
- Supabase for auth, membership, and data
- PWA-installable

## Getting started

1. Run `migrations/001_create_users_table.sql` in the Supabase SQL editor
2. Sign up via `login.html` (or use Supabase dashboard to create the user)
3. Activate the membership:
   ```sql
   INSERT INTO users (id, email, membership_status)
   SELECT id, email, 'active'
   FROM auth.users
   WHERE LOWER(email) = LOWER('your@email.com');
   ```
4. Sign in at `login.html` and you'll land in the app

## Status

- ✅ Auth scaffolding complete (login, forgot password, reset, inactive, membership gating)
- ✅ Full HTML structure for all panels (VTO, Accountability, Goals, Scorecard, Meetings, Issues, Alignment)
- ✅ BrandLock v1.4 styling applied
- ⏳ Panel logic (`js/app.js`) — to be built next

See `CLAUDE.md` for the full design system and build guide.

## Brand

This app uses the locked Coach4U design system v1.4. Do not modify colours, fonts, or login spec without updating `CLAUDE.md` and bumping the design system version.
