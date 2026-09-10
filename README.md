# UCL Power Index — self-hosted

A standalone version of the Champions League power-index dashboard: a static
page + a free database + a scheduled job that checks for new results every 5
minutes (GitHub's fastest free cron interval). No paid services required.

**Stack:** GitHub (repo, free static hosting via Pages, free scheduled job via
Actions) + Supabase (free Postgres database with realtime push updates).

## What you get vs. the original

- Refresh cadence: **every 5 minutes** instead of hourly, with no usage cost
  against any Claude plan.
- Same design, same composite power-index methodology, same filters and
  views (Power Index / vs. Coefficient / League Table).
- One real caveat: the refresh job reads scores from a **free, unofficial**
  ESPN JSON endpoint (`site.api.espn.com`). It isn't a paid, guaranteed
  live-scores API — if ESPN changes that endpoint or blocks the request, the
  job will just no-op until it's fixed (see "If scores stop updating" below).
  It is not second-by-second live — matches are usually reflected within a
  few minutes of going final.

## One-time setup (about 15 minutes)

### 1. Create the Supabase project

1. Go to [supabase.com](https://supabase.com) → New project (free tier, no
   credit card required). Pick any name/region/password.
2. Once it's ready, open **SQL Editor** → New query, paste in the contents
   of [`supabase/schema.sql`](supabase/schema.sql), and run it.
3. New query again, paste in [`data/seed.sql`](data/seed.sql), and run it —
   this loads the real Matchday 1 results so the dashboard isn't empty on
   first load.
4. Go to **Project Settings → Data API**. You'll need three values from here
   (and nearby pages) in the steps below:
   - **Project URL** (e.g. `https://xxxx.supabase.co`)
   - **anon / public key** — safe to expose in the browser, protected by the
     read-only policies in `schema.sql`
   - **service_role key** (Project Settings → API → reveal) — **secret**,
     never put this in the frontend; it's only for the GitHub Actions job.
5. Go to **Database → Replication** and confirm `teams` and `meta` are
   listed under the `supabase_realtime` publication (schema.sql already adds
   them, but it's worth checking — this is what makes updates push live to
   open browser tabs instead of requiring a manual refresh).

### 2. Fill in the frontend

Open [`frontend/index.html`](frontend/index.html) and near the bottom of the
`<script>` block, replace:

```js
const SUPABASE_URL = "YOUR_SUPABASE_PROJECT_URL";
const SUPABASE_ANON_KEY = "YOUR_SUPABASE_ANON_KEY";
```

with your actual **Project URL** and **anon key** from step 1.4.

### 3. Push to GitHub and turn on Pages

1. Create a new GitHub repo and push this whole folder to it.
2. Repo → **Settings → Pages** → Source: "Deploy from a branch" → Branch:
   `main`, folder: `/frontend` (or move `index.html` to the repo root if you'd
   rather not use a subfolder — either works, just point Pages at wherever
   `index.html` lives).
3. GitHub gives you a URL like `https://<you>.github.io/<repo>/` — that's
   your live dashboard.

### 4. Add the refresh job's secrets

Repo → **Settings → Secrets and variables → Actions → New repository
secret**. Add two:

- `SUPABASE_URL` — same Project URL as above
- `SUPABASE_SERVICE_KEY` — the **service_role** key (not the anon key)

The workflow in [`.github/workflows/refresh.yml`](.github/workflows/refresh.yml)
is already set to run every 5 minutes and will pick these up automatically.
You can also trigger it manually from the repo's **Actions** tab
("Refresh UCL Power Index" → Run workflow) to test it right away instead of
waiting for the next scheduled tick.

That's it — the dashboard is live, and it'll pick up new results on its own
from here through the end of the season (matchday 8 is late January 2027).

## If scores stop updating

The refresh script (`scripts/refresh.py`) leans on ESPN's public scoreboard
endpoint, which is free but unofficial and undocumented — it can change
shape or start blocking automated requests without notice. If the dashboard
stalls on a matchday:

1. Check the **Actions** tab for the failing run's log.
2. If it's a team-name mismatch (`[warn] could not match teams for match...`
   in the log), add the missing name to the `ALIASES` dict near the top of
   `refresh.py`.
3. If ESPN's endpoint itself is erroring, that's the endpoint changing on
   its end — you'd need to swap in a different free source (or a paid one
   like API-Football) in `fetch_scoreboard()`.
4. Worst case, you can always update Supabase by hand in the SQL editor —
   the frontend just reads whatever is in the `teams`/`meta` tables.

## Project layout

```
frontend/index.html         the dashboard (static, deploy as-is via GitHub Pages)
scripts/refresh.py          the refresh job (fetches scores, recomputes ranks, writes to Supabase)
scripts/requirements.txt    its Python dependencies
.github/workflows/refresh.yml   the 5-minute GitHub Actions cron
supabase/schema.sql         database tables + row-level security policies
data/seed.sql               real Matchday 1 data to load on first setup
```

## Costs

Everything above is free at this scale (36 teams, 144 matches, a handful of
reads/writes every few minutes): GitHub public repos have unlimited Actions
minutes, and Supabase's free tier (500MB DB, 2M realtime messages/month) is
far more than this needs. The one thing to watch: Supabase **pauses free
projects after 7 days with no activity** — the 5-minute cron job touching
the database regularly should keep it awake on its own, but if you ever
disable the workflow for more than a week, you may need to manually resume
the project from the Supabase dashboard.
