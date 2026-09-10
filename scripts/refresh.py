#!/usr/bin/env python3
"""
UCL Power Index — refresh job.

Runs on a schedule (GitHub Actions, every 5 minutes by default). Each run:
  1. Pulls current team state from Supabase.
  2. Checks ESPN's public (unofficial, undocumented) scoreboard JSON endpoint
     for finished Champions League league-phase matches on a rolling window
     of dates, skipping any match already processed.
  3. Folds each new finished match into that team's cumulative standings and
     into a running composite "power score" (pre-season baseline, adjusted
     match by match for result margin and upset factor).
  4. Recomputes ranks, the flagged-swing check, coefficient gap, and the
     knockout-outlook heuristics, and writes everything back to Supabase.

This talks to a free, unofficial ESPN endpoint that can change or block
requests without notice — see the README's "if scores stop updating"
section. It is intentionally dependency-light (stdlib + requests + the
supabase client) so it runs cleanly in GitHub Actions.
"""

import os
import re
import sys
import math
import unicodedata
import difflib
from datetime import datetime, timedelta, timezone

import requests
from supabase import create_client

SUPABASE_URL = os.environ["SUPABASE_URL"]
SUPABASE_SERVICE_KEY = os.environ["SUPABASE_SERVICE_KEY"]

ESPN_SCOREBOARD = "https://site.api.espn.com/apis/site/v2/sports/soccer/uefa.champions/scoreboard"

# 2026/27 league phase schedule — used only to decide how wide a date
# window is worth checking; matching itself is fully dynamic against
# whatever ESPN actually returns.
MATCHDAY_WINDOWS = [
    (1, "2026-09-08", "2026-09-10"),
    (2, "2026-10-13", "2026-10-14"),
    (3, "2026-10-20", "2026-10-21"),
    (4, "2026-11-03", "2026-11-04"),
    (5, "2026-11-24", "2026-11-25"),
    (6, "2026-12-08", "2026-12-09"),
    (7, "2027-01-19", "2027-01-20"),
    (8, "2027-01-27", "2027-01-27"),
]

# Known ESPN display-name variants per team slug. ESPN's exact strings can
# drift; the normalize()+difflib fallback below catches anything missed here.
ALIASES = {
    "paris-saint-germain": ["Paris Saint-Germain", "Paris Saint Germain", "PSG"],
    "bayern-munich": ["Bayern Munich", "FC Bayern München", "Bayern München"],
    "barcelona": ["Barcelona", "FC Barcelona"],
    "real-madrid": ["Real Madrid"],
    "arsenal": ["Arsenal"],
    "manchester-city": ["Manchester City", "Man City"],
    "liverpool": ["Liverpool"],
    "manchester-united": ["Manchester United", "Man United", "Man Utd"],
    "borussia-dortmund": ["Borussia Dortmund", "Dortmund", "BVB"],
    "inter": ["Inter Milan", "Inter", "FC Internazionale Milano", "Internazionale"],
    "atletico-madrid": ["Atletico Madrid", "Atlético Madrid", "Atletico de Madrid", "Club Atlético de Madrid"],
    "aston-villa": ["Aston Villa"],
    "roma": ["Roma", "AS Roma"],
    "sporting-cp": ["Sporting CP", "Sporting Lisbon", "Sporting Clube de Portugal"],
    "real-betis": ["Real Betis", "Betis"],
    "porto": ["Porto", "FC Porto"],
    "psv-eindhoven": ["PSV Eindhoven", "PSV"],
    "como": ["Como", "Como 1907"],
    "galatasaray": ["Galatasaray"],
    "stuttgart": ["Stuttgart", "VfB Stuttgart"],
    "lille": ["Lille", "LOSC Lille"],
    "club-brugge": ["Club Brugge", "Club Brugge KV"],
    "rb-leipzig": ["RB Leipzig", "Leipzig"],
    "fenerbahce": ["Fenerbahce", "Fenerbahçe"],
    "napoli": ["Napoli", "SSC Napoli"],
    "feyenoord": ["Feyenoord"],
    "shakhtar-donetsk": ["Shakhtar Donetsk", "Shakhtar"],
    "villarreal": ["Villarreal"],
    "bodo-glimt": ["Bodo/Glimt", "Bodø/Glimt", "FK Bodo/Glimt", "FK Bodø/Glimt"],
    "aek-athens": ["AEK Athens"],
    "slavia-praha": ["Slavia Praha", "Slavia Prague", "SK Slavia Praha"],
    "lens": ["Lens", "RC Lens"],
    "slovan-bratislava": ["Slovan Bratislava", "SK Slovan Bratislava"],
    "lask": ["LASK", "LASK Linz"],
    "viking": ["Viking", "Viking FK"],
    "sabah": ["Sabah", "Sabah FK"],
}
NAME_TO_SLUG = {}
for slug, names in ALIASES.items():
    for n in names:
        NAME_TO_SLUG[n.lower()] = slug


def normalize(name: str) -> str:
    name = unicodedata.normalize("NFKD", name).encode("ascii", "ignore").decode()
    name = name.lower()
    name = re.sub(r"\b(fc|cf|sk|ac|afc|kv|the)\b", "", name)
    name = re.sub(r"[^a-z0-9]+", "", name)
    return name


NORM_TO_SLUG = {normalize(n): slug for slug, names in ALIASES.items() for n in names}


def match_team(espn_name: str):
    key = espn_name.lower().strip()
    if key in NAME_TO_SLUG:
        return NAME_TO_SLUG[key]
    norm = normalize(espn_name)
    if norm in NORM_TO_SLUG:
        return NORM_TO_SLUG[norm]
    close = difflib.get_close_matches(norm, NORM_TO_SLUG.keys(), n=1, cutoff=0.72)
    if close:
        return NORM_TO_SLUG[close[0]]
    return None


def _extract_score(raw):
    """ESPN has returned scores both as a bare number/string and as
    {"value": ..., "displayValue": ...} depending on endpoint/sport version —
    handle both shapes."""
    if raw is None:
        return None
    if isinstance(raw, dict):
        raw = raw.get("value", raw.get("displayValue"))
    try:
        return int(raw)
    except (TypeError, ValueError):
        return None


def fetch_scoreboard(date_str: str):
    """date_str: YYYYMMDD. Returns list of finished match dicts."""
    try:
        resp = requests.get(
            ESPN_SCOREBOARD,
            params={"dates": date_str},
            headers={"User-Agent": "Mozilla/5.0 (compatible; ucl-power-index-refresh/1.0)"},
            timeout=20,
        )
        resp.raise_for_status()
        data = resp.json()
    except Exception as e:
        print(f"  [warn] scoreboard fetch failed for {date_str}: {e}")
        return []

    matches = []
    for ev in data.get("events", []):
        comps = ev.get("competitions", [])
        if not comps:
            continue
        comp = comps[0]
        status = comp.get("status", {}).get("type", {})
        if not status.get("completed"):
            continue
        competitors = comp.get("competitors", [])
        if len(competitors) != 2:
            continue
        home = next((c for c in competitors if c.get("homeAway") == "home"), competitors[0])
        away = next((c for c in competitors if c.get("homeAway") == "away"), competitors[1])
        home_score = _extract_score(home.get("score"))
        away_score = _extract_score(away.get("score"))
        if home_score is None or away_score is None:
            continue
        matches.append({
            "match_id": str(ev.get("id")),
            "played_at": ev.get("date"),
            "home_name": home.get("team", {}).get("displayName", ""),
            "away_name": away.get("team", {}).get("displayName", ""),
            "home_score": home_score,
            "away_score": away_score,
        })
    return matches


def matchday_for_date(d: datetime):
    ds = d.strftime("%Y-%m-%d")
    for md, start, end in MATCHDAY_WINDOWS:
        if start <= ds <= end:
            return md
    return None


def sigmoid(x):
    return 1 / (1 + math.exp(-x))


def clamp(v, lo, hi):
    return max(lo, min(hi, v))


def main():
    sb = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

    teams_resp = sb.table("teams").select("*").execute()
    teams = {t["slug"]: t for t in teams_resp.data}
    if not teams:
        print("No teams found in Supabase — run supabase/schema.sql and the seed data first.")
        sys.exit(1)

    processed_resp = sb.table("processed_matches").select("match_id").execute()
    processed_ids = {r["match_id"] for r in processed_resp.data}

    # Rolling window: check the last 4 days through tomorrow (UTC), which
    # comfortably covers a 2-3 day matchday window even if this job's clock
    # or ESPN's local match dates drift by a day.
    today = datetime.now(timezone.utc)
    dates_to_check = [today + timedelta(days=d) for d in range(-4, 2)]

    new_matches = []
    for d in dates_to_check:
        date_str = d.strftime("%Y%m%d")
        for m in fetch_scoreboard(date_str):
            if m["match_id"] in processed_ids:
                continue
            home_slug = match_team(m["home_name"])
            away_slug = match_team(m["away_name"])
            if not home_slug or not away_slug:
                print(f"  [warn] could not match teams for match {m['match_id']}: "
                      f"'{m['home_name']}' vs '{m['away_name']}' — add an alias in ALIASES")
                continue
            if home_slug not in teams or away_slug not in teams:
                continue
            m["home_slug"] = home_slug
            m["away_slug"] = away_slug
            m["matchday"] = matchday_for_date(d)
            new_matches.append(m)
            processed_ids.add(m["match_id"])  # avoid double-processing within this same run

    if not new_matches:
        print("No new finished matches. Touching last_refreshed and exiting.")
        sb.table("meta").update({"last_refreshed": datetime.now(timezone.utc).isoformat()}).eq("id", "summary").execute()
        return

    print(f"Found {len(new_matches)} new finished match(es).")

    # Sort chronologically so the sequential adjustment below matches the
    # order the matches were actually played in.
    new_matches.sort(key=lambda m: m.get("played_at") or "")

    for m in new_matches:
        h, a = teams[m["home_slug"]], teams[m["away_slug"]]
        hs, as_ = m["home_score"], m["away_score"]

        h["mp"] = h.get("mp", 0) + 1
        a["mp"] = a.get("mp", 0) + 1
        h["gf"] = h.get("gf", 0) + hs
        h["ga"] = h.get("ga", 0) + as_
        a["gf"] = a.get("gf", 0) + as_
        a["ga"] = a.get("ga", 0) + hs
        h["gd"] = h["gf"] - h["ga"]
        a["gd"] = a["gf"] - a["ga"]

        last_date = (m.get("played_at") or "")[:10] or None
        if hs > as_:
            h["pts"] = h.get("pts", 0) + 3
            h["form"], a["form"] = "W", "L"
        elif hs < as_:
            a["pts"] = a.get("pts", 0) + 3
            h["form"], a["form"] = "L", "W"
        else:
            h["pts"] = h.get("pts", 0) + 1
            a["pts"] = a.get("pts", 0) + 1
            h["form"] = a["form"] = "D"
        h["last_result"] = f"{hs}-{as_} vs {a['team']} (H)"
        a["last_result"] = f"{as_}-{hs} vs {h['team']} (A)"
        h["last_match_date"] = last_date
        a["last_match_date"] = last_date

        # --- composite score adjustment (same shape as the original methodology) ---
        margin = abs(hs - as_)
        gap_proxy = abs(h["power_score"] - a["power_score"]) / 3
        if hs != as_:
            winner, loser = (h, a) if hs > as_ else (a, h)
            base = 1.0 + 0.5 * min(margin, 5)
            upset = winner["power_score"] < loser["power_score"]
            bonus = (0.06 if upset else 0.02) * gap_proxy
            winner["power_score"] += base + bonus
            loser["power_score"] -= (base + bonus) * 0.85
        else:
            fav, dog = (h, a) if h["power_score"] > a["power_score"] else (a, h)
            fav["power_score"] -= 0.05 * gap_proxy
            dog["power_score"] += 0.05 * gap_proxy

        sb.table("processed_matches").insert({
            "match_id": m["match_id"],
            "matchday": m["matchday"],
            "home_slug": m["home_slug"],
            "away_slug": m["away_slug"],
            "home_score": hs,
            "away_score": as_,
            "played_at": m.get("played_at"),
        }).execute()

    # --- recompute ranks across all 36 teams ---
    all_teams = list(teams.values())
    all_teams.sort(key=lambda t: -t["power_score"])
    for i, t in enumerate(all_teams):
        t["power_rank"] = i + 1
    for t in all_teams:
        t["movement"] = t["power_rank_baseline"] - t["power_rank"]
        t["flagged_swing"] = abs(t["movement"]) > 5
        t["gap_vs_coeff"] = t["coeff_rank"] - t["power_rank"]

    table_order = sorted(all_teams, key=lambda t: (-t["pts"], -t["gd"], -t["gf"], t["team"]))
    for i, t in enumerate(table_order):
        t["table_rank"] = i + 1

    matchdays_played = max([t["mp"] for t in all_teams] or [0])
    for t in all_teams:
        avg_pts = t["pts"] / t["mp"] if t["mp"] else 1.0
        nudge = 3 * (avg_pts - 1.5)
        t["top8_pct"] = round(clamp(100 * sigmoid((8.5 - t["power_rank"]) / 4) + nudge, 0.1, 99.9), 1)
        t["advance_pct"] = round(clamp(100 * sigmoid((24.5 - t["power_rank"]) / 5) + nudge, 0.1, 99.9), 1)

    scores = [t["power_score"] for t in all_teams]
    smin, smax = min(scores), max(scores)
    top_x = 6 + 2.75 * matchdays_played
    for t in all_teams:
        norm = (t["power_score"] - smin) / (smax - smin) if smax > smin else 0.5
        t["xpts"] = round(6 + norm * (top_x - 6), 1)

    total_goals = sum(t["gf"] for t in all_teams)
    matches_played = sum(t["mp"] for t in all_teams) // 2
    biggest = max(all_teams, key=lambda t: abs(t["movement"]))
    widest = max(all_teams, key=lambda t: abs(t["gap_vs_coeff"]))
    flagged = [t for t in all_teams if t["flagged_swing"]]

    for t in all_teams:
        sb.table("teams").update({
            "power_score": t["power_score"], "power_rank": t["power_rank"],
            "movement": t["movement"], "flagged_swing": t["flagged_swing"],
            "gap_vs_coeff": t["gap_vs_coeff"], "table_rank": t["table_rank"],
            "pts": t["pts"], "gd": t["gd"], "gf": t["gf"], "ga": t["ga"], "mp": t["mp"],
            "form": t["form"], "last_result": t["last_result"], "last_match_date": t["last_match_date"],
            "top8_pct": t["top8_pct"], "advance_pct": t["advance_pct"], "xpts": t["xpts"],
            "updated_at": datetime.now(timezone.utc).isoformat(),
        }).eq("slug", t["slug"]).execute()

    sb.table("meta").update({
        "matchdays_played": matchdays_played,
        "matches_played": matches_played,
        "goals_per_match": round(total_goals / matches_played, 2) if matches_played else 0,
        "total_goals": total_goals,
        "biggest_mover_team": biggest["team"], "biggest_mover_value": biggest["movement"],
        "biggest_mover_rank": biggest["power_rank"],
        "widest_gap_team": widest["team"], "widest_gap_value": widest["gap_vs_coeff"],
        "flagged_count": len(flagged), "flagged_teams": [t["team"] for t in flagged],
        "last_refreshed": datetime.now(timezone.utc).isoformat(),
    }).eq("id", "summary").execute()

    print(f"Updated {len(all_teams)} teams. Matchdays played: {matchdays_played}. "
          f"{len(new_matches)} match(es) processed this run.")


if __name__ == "__main__":
    main()
