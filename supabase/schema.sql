-- UCL Power Index — Supabase schema
-- Run this once in the Supabase SQL editor (Project > SQL Editor > New query).

create table if not exists teams (
  slug                  text primary key,
  team                  text not null,
  country               text not null,
  league                text not null,
  pot                   int not null,
  coeff                 numeric not null,
  coeff_rank            int not null,
  expert_baseline_rank  int not null,
  power_rank_baseline   int not null,     -- fixed at Matchday 1, never recomputed
  power_score           numeric not null, -- running composite score the refresh job adjusts match by match
  power_rank            int not null,
  movement              int not null default 0,
  flagged_swing         boolean not null default false,
  gap_vs_coeff          int not null default 0,
  table_rank            int not null,
  pts                   int not null default 0,
  gd                    int not null default 0,
  gf                    int not null default 0,
  ga                    int not null default 0,
  mp                    int not null default 0,
  form                  text,
  last_result           text,
  last_match_date       date,
  top8_pct              numeric,
  advance_pct           numeric,
  xpts                  numeric,
  updated_at            timestamptz not null default now()
);

create table if not exists meta (
  id                    text primary key default 'summary',
  matchdays_played      int not null default 0,
  matchdays_total       int not null default 8,
  matches_played        int not null default 0,
  matches_total         int not null default 144,
  goals_per_match       numeric,
  total_goals           int,
  biggest_mover_team    text,
  biggest_mover_value   int,
  biggest_mover_rank    int,
  widest_gap_team       text,
  widest_gap_value      int,
  flagged_count         int,
  flagged_teams         text[],
  last_refreshed        timestamptz not null default now()
);

-- Tracks which finished matches have already been folded into the
-- standings/composite score, so the 5-minute refresh job never double-counts
-- a match it has already processed on an earlier run.
create table if not exists processed_matches (
  match_id      text primary key,   -- ESPN event id
  matchday      int,
  home_slug     text not null,
  away_slug     text not null,
  home_score    int not null,
  away_score    int not null,
  played_at     timestamptz,
  processed_at  timestamptz not null default now()
);

-- Row Level Security: everyone can read (this is a public dashboard),
-- nobody can write via the public/anon key. Only the service_role key
-- (used by the GitHub Actions refresh job, never shipped to the browser)
-- bypasses RLS and can write.
alter table teams enable row level security;
alter table meta enable row level security;
alter table processed_matches enable row level security;

drop policy if exists "public read teams" on teams;
create policy "public read teams" on teams for select using (true);

drop policy if exists "public read meta" on meta;
create policy "public read meta" on meta for select using (true);

drop policy if exists "public read processed_matches" on processed_matches;
create policy "public read processed_matches" on processed_matches for select using (true);

-- Enable Realtime so the frontend gets pushed updates the instant the
-- refresh job writes new data (Database > Replication > supabase_realtime
-- in the dashboard, or the two lines below in the SQL editor):
alter publication supabase_realtime add table teams;
alter publication supabase_realtime add table meta;
