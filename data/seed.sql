-- UCL Power Index — seed data (real Matchday 1 results, 2026/27 league phase)
-- Run this in the Supabase SQL editor AFTER schema.sql.

insert into teams (slug, team, country, league, pot, coeff, coeff_rank, expert_baseline_rank, power_rank_baseline, power_score, power_rank, movement, flagged_swing, gap_vs_coeff, table_rank, pts, gd, gf, ga, mp, form, last_result, last_match_date, top8_pct, advance_pct, xpts) values
('paris-saint-germain', 'Paris Saint-Germain', 'France', 'Ligue 1', 1, 132.0, 3, 1, 1, 39.3, 1, 0, false, 2, 1, 3, 5, 6, 1, 1, 'W', '6-1 vs Slovan Bratislava (H)', '2026-09-09', 99.9, 99.9, 22.0),
('bayern-munich', 'Bayern Munich', 'Germany', 'Bundesliga', 1, 147.5, 1, 3, 2, 38.78, 2, 0, false, -1, 2, 3, 5, 5, 0, 1, 'W', '5-0 vs Bodo/Glimt (H)', '2026-09-10', 97.5, 99.9, 21.8),
('barcelona', 'Barcelona', 'Spain', 'LaLiga', 1, 113.25, 8, 2, 4, 36.0, 3, 1, false, 5, 3, 3, 4, 5, 1, 1, 'W', '5-1 vs Feyenoord (H)', '2026-09-09', 92.8, 99.9, 20.7),
('real-madrid', 'Real Madrid', 'Spain', 'LaLiga', 1, 144.5, 2, 5, 3, 34.8, 4, -1, false, -2, 14, 3, 1, 2, 1, 1, 'W', '2-1 vs Inter (H)', '2026-09-08', 85.5, 99.9, 20.3),
('arsenal', 'Arsenal', 'England', 'Premier League', 1, 119.0, 7, 4, 5, 33.66, 5, 0, false, 2, 16, 3, 1, 1, 0, 1, 'W', '1-0 vs Napoli (H)', '2026-09-09', 80.6, 99.9, 19.8),
('manchester-city', 'Manchester City', 'England', 'Premier League', 1, 125.5, 6, 6, 6, 33.16, 6, 0, false, 0, 8, 3, 2, 2, 0, 1, 'W', '2-0 vs Porto (H)', '2026-09-08', 76.1, 99.9, 19.6),
('liverpool', 'Liverpool', 'England', 'Premier League', 1, 130.0, 4, 8, 7, 32.14, 7, 0, false, -3, 13, 3, 1, 2, 1, 1, 'W', '2-1 vs Atletico Madrid (H)', '2026-09-09', 69.3, 99.9, 19.2),
('manchester-united', 'Manchester United', 'England', 'Premier League', 2, 76.5, 15, 10, 12, 28.48, 8, 4, false, 7, 4, 3, 4, 4, 0, 1, 'W', '4-0 vs Sabah (H)', '2026-09-10', 66.1, 99.9, 17.8),
('borussia-dortmund', 'Borussia Dortmund', 'Germany', 'Bundesliga', 2, 100.75, 10, 11, 10, 28.26, 9, 1, false, 1, 10, 3, 1, 3, 2, 1, 'W', '3-2 vs Villarreal (H)', '2026-09-08', 56.9, 99.9, 17.7),
('inter', 'Inter', 'Italy', 'Serie A', 1, 127.0, 5, 9, 8, 28.24, 10, -2, false, -5, 26, 0, -1, 1, 2, 1, 'L', '1-2 vs Real Madrid (A)', '2026-09-08', 39.7, 94.0, 17.7),
('atletico-madrid', 'Atletico Madrid', 'Spain', 'LaLiga', 1, 104.75, 9, 7, 9, 27.891, 11, -2, false, -2, 25, 0, -1, 1, 2, 1, 'L', '1-2 vs Liverpool (A)', '2026-09-09', 33.9, 92.9, 17.6),
('aston-villa', 'Aston Villa', 'England', 'Premier League', 2, 83.0, 13, 13, 13, 25.66, 12, 1, false, 1, 9, 3, 1, 3, 2, 1, 'W', '3-2 vs Club Brugge (H)', '2026-09-08', 39.4, 99.2, 16.7),
('roma', 'Roma', 'Italy', 'Serie A', 2, 97.75, 11, 12, 11, 24.7, 13, -2, false, -2, 19, 1, 0, 1, 1, 1, 'D', '1-1 vs Fenerbahce (A)', '2026-09-10', 27.5, 92.9, 16.3),
('sporting-cp', 'Sporting CP', 'Portugal', 'Primeira Liga', 2, 84.0, 12, 20, 15, 22.26, 14, 1, false, -2, 6, 3, 2, 3, 1, 1, 'W', '3-1 vs Galatasaray (H)', '2026-09-09', 31.2, 96.7, 15.4),
('real-betis', 'Real Betis', 'Spain', 'LaLiga', 2, 74.5, 17, 17, 16, 21.58, 15, 1, false, 2, 12, 3, 1, 3, 2, 1, 'W', '3-2 vs Lille (H)', '2026-09-08', 26.5, 93.8, 15.1),
('porto', 'Porto', 'Portugal', 'Primeira Liga', 2, 80.75, 14, 15, 14, 20.564, 16, -2, false, -2, 31, 0, -2, 0, 2, 1, 'L', '0-2 vs Manchester City (A)', '2026-09-08', 11.3, 83.0, 14.7),
('psv-eindhoven', 'PSV Eindhoven', 'Netherlands', 'Eredivisie', 2, 71.25, 18, 18, 17, 18.4, 17, 0, false, 1, 18, 1, 0, 1, 1, 1, 'D', '1-1 vs Shakhtar Donetsk (H)', '2026-09-10', 13.7, 83.8, 13.9),
('como', 'Como', 'Italy', 'Serie A', 4, 19.989, 33, 14, 22, 18.08, 18, 4, false, 15, 5, 3, 3, 4, 1, 1, 'W', '4-1 vs RB Leipzig (H)', '2026-09-10', 20.5, 87.0, 13.8),
('galatasaray', 'Galatasaray', 'Turkey', 'Super Lig', 3, 53.5, 27, 16, 18, 14.849, 19, -1, false, 8, 29, 0, -2, 1, 3, 1, 'L', '1-3 vs Sporting CP (A)', '2026-09-09', 4.8, 73.4, 12.5),
('stuttgart', 'Stuttgart', 'Germany', 'Bundesliga', 4, 27.5, 30, 21, 27, 14.56, 20, 7, true, 10, 7, 3, 2, 3, 1, 1, 'W', '3-1 vs Viking (H)', '2026-09-09', 16.3, 78.7, 12.4),
('lille', 'Lille', 'France', 'Ligue 1', 3, 68.75, 20, 22, 20, 14.457, 21, -1, false, -1, 22, 0, -1, 2, 3, 1, 'L', '2-3 vs Real Betis (A)', '2026-09-08', 3.2, 66.0, 12.4),
('club-brugge', 'Club Brugge', 'Belgium', 'Pro League', 2, 75.25, 16, 25, 21, 14.189, 22, -1, false, -6, 21, 0, -1, 2, 3, 1, 'L', '2-3 vs Aston Villa (A)', '2026-09-08', 2.3, 61.4, 12.3),
('rb-leipzig', 'RB Leipzig', 'Germany', 'Bundesliga', 3, 61.0, 23, 19, 19, 14.122, 23, -4, false, 0, 32, 0, -3, 1, 4, 1, 'L', '1-4 vs Como (A)', '2026-09-10', 0.1, 55.0, 12.2),
('fenerbahce', 'Fenerbahce', 'Turkey', 'Super Lig', 3, 57.75, 25, 24, 25, 13.3, 24, 1, false, 1, 17, 1, 0, 1, 1, 1, 'D', '1-1 vs Roma (H)', '2026-09-10', 5.0, 54.5, 11.9),
('napoli', 'Napoli', 'Italy', 'Serie A', 3, 63.0, 22, 23, 23, 12.819, 25, -2, false, -3, 28, 0, -1, 0, 1, 1, 'L', '0-1 vs Arsenal (A)', '2026-09-09', 0.6, 46.7, 11.7),
('feyenoord', 'Feyenoord', 'Netherlands', 'Eredivisie', 3, 71.0, 19, 26, 24, 10.91, 26, -2, false, -7, 33, 0, -4, 1, 5, 1, 'L', '1-5 vs Barcelona (A)', '2026-09-09', 0.1, 39.4, 11.0),
('shakhtar-donetsk', 'Shakhtar Donetsk', 'Ukraine', 'Premier League (UKR)', 3, 56.25, 26, 29, 29, 9.8, 27, 2, false, -1, 20, 1, 0, 1, 1, 1, 'D', '1-1 vs PSV Eindhoven (A)', '2026-09-10', 4.0, 39.8, 10.6),
('villarreal', 'Villarreal', 'Spain', 'LaLiga', 3, 59.0, 24, 28, 28, 9.019, 28, 0, false, -4, 24, 0, -1, 2, 3, 1, 'L', '2-3 vs Borussia Dortmund (A)', '2026-09-08', 0.1, 32.4, 10.3),
('bodo-glimt', 'Bodo/Glimt', 'Norway', 'Eliteserien', 3, 64.0, 21, 27, 26, 9.017, 29, -3, false, -8, 36, 0, -5, 0, 5, 1, 'L', '0-5 vs Bayern Munich (A)', '2026-09-10', 0.1, 24.9, 10.3),
('aek-athens', 'AEK Athens', 'Greece', 'Super League Greece', 4, 24.0, 31, 32, 32, 6.92, 30, 2, false, 1, 15, 3, 1, 1, 0, 1, 'W', '1-0 vs LASK (H)', '2026-09-08', 10.5, 31.8, 9.4),
('slavia-praha', 'Slavia Praha', 'Czech Republic', 'Czech First League', 4, 44.0, 28, 30, 30, 6.321, 31, -1, false, -3, 23, 0, -1, 2, 3, 1, 'L', '2-3 vs Lens (A)', '2026-09-10', 0.1, 20.6, 9.2),
('lens', 'Lens', 'France', 'Ligue 1', 4, 16.699, 34, 34, 34, 4.74, 32, 2, false, 2, 11, 3, 1, 3, 2, 1, 'W', '3-2 vs Slavia Praha (H)', '2026-09-10', 10.3, 25.0, 8.6),
('slovan-bratislava', 'Slovan Bratislava', 'Slovakia', 'Slovak Super Liga', 4, 36.0, 29, 31, 31, 3.315, 33, -2, false, -4, 35, 0, -5, 1, 6, 1, 'L', '1-6 vs Paris Saint-Germain (A)', '2026-09-09', 0.1, 11.4, 8.0),
('lask', 'LASK', 'Austria', 'Austrian Bundesliga', 4, 21.0, 32, 33, 33, 3.108, 34, -1, false, -2, 27, 0, -1, 0, 1, 1, 'L', '0-1 vs AEK Athens (A)', '2026-09-08', 0.1, 12.2, 8.0),
('viking', 'Viking', 'Norway', 'Eliteserien', 4, 8.247, 35, 35, 35, 0.164, 35, 0, false, 0, 30, 0, -2, 1, 3, 1, 'L', '1-3 vs Stuttgart (A)', '2026-09-09', 0.1, 9.3, 6.8),
('sabah', 'Sabah', 'Azerbaijan', 'Azerbaijan Premier League', 4, 6.0, 36, 36, 36, -1.958, 36, 0, false, 0, 34, 0, -4, 0, 4, 1, 'L', '0-4 vs Manchester United (A)', '2026-09-10', 0.1, 5.9, 6.0)
on conflict (slug) do nothing;

insert into meta (id, matchdays_played, matchdays_total, matches_played, matches_total, goals_per_match, total_goals, biggest_mover_team, biggest_mover_value, biggest_mover_rank, widest_gap_team, widest_gap_value, flagged_count, flagged_teams, last_refreshed) values
('summary', 1, 8, 18, 144, 3.83, 69, 'Stuttgart', 7, 20, 'Como', 15, 1, ARRAY['Stuttgart'], '2026-09-10T21:00:00Z')
on conflict (id) do update set
  matchdays_played = excluded.matchdays_played, matches_played = excluded.matches_played,
  goals_per_match = excluded.goals_per_match, total_goals = excluded.total_goals,
  biggest_mover_team = excluded.biggest_mover_team, biggest_mover_value = excluded.biggest_mover_value,
  biggest_mover_rank = excluded.biggest_mover_rank, widest_gap_team = excluded.widest_gap_team,
  widest_gap_value = excluded.widest_gap_value, flagged_count = excluded.flagged_count,
  flagged_teams = excluded.flagged_teams, last_refreshed = excluded.last_refreshed;
