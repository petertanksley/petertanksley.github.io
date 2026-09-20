# 2026-09-20 — Achievements on the site: numeral, page, homepage card, panel, origin

Follow-on to `2026-09-19_achievements-rules.md`. Plan: `plans/2026-09-20_achievements-surfaces.md` (APPROVED →
COMPLETED same day). Peter's decisions, in his words: "gold, career achievements to origin hex, keep the
achievements separate (single latest) from the news stream. Go." Page location defaulted to Research ▸ Achievements.

## What was built

- **Ledger is the spine.** Every surface reads `data/achievements_log.yml`; nothing reads the rules. Entries gained
  `key` (id-date, the anchor), `paper` (title, for a byline), `rank` (tier index, sorts within a date) and
  `featured` (from the paper). `check_achievements.R --replay` rebuilds the ledger from every consecutive snapshot
  pair, so the ledger is derived state and a wording edit is one rerun away. Verified: replay reproduced the
  `--log` output byte for byte. R's yaml writes logicals as yes/no; forced to true/false, because Quarto's YAML 1.2
  reader would keep "no" as a truthy string.
- **Tree.** `build_tree.R` packs per-node `achievements {n, best, items}` and `meta.origin.achievements` (entries with
  no `article`), plus `meta.achievements {label, page, total, latest}`. `skilltree.js` draws a gold roman numeral
  (`.hex-num`, 15 % of hex width, ink halo via paint-order) on the lower-left edge, rotated 30° to run along it,
  the mirror of the pips; the origin gets the same at its scale. Panel: Achievements section after Lineage, tier
  chip + title per row linking to `achievements.html#<key>`. Sheet: same section for career-level entries. Stats
  card: fourth figure (roman total) linking to the page, drawn once both fetches have landed. Legend item added.
  Tooltip meta carries the numeral. `?v=2026-09-20a`.
- **Page.** `achievements.qmd` is dark end to end (same `page-dark` mechanism as the tree). A Quarto listing over the
  ledger with `achievements-listing.ejs`: grouped by snapshot date, each entry a system message (header, title,
  paper byline, body, Reward line), tier colour on the left rule, `:target` ring, "Find the hex" link. Sort
  `["date desc", "rank desc"]`. A listing over a YAML inside the render-excluded `5_skilltree/` works fine.
- **Homepage.** Second listing on `index.qmd`, template `achievement-home.ejs`: one dark card under News with the
  newest featured entry and the total as a roman numeral. `news.yml` untouched. The template skips
  `featured: false` papers (McAllister/Gonzalez biomarker papers, per CLAUDE.md), which is why the ledger carries
  `featured` and the listing has no `max-items`.
- **Titles** now carry the feat only ("Top 2% of 2023.", "Cited once."); the paper is the byline. In the panel the
  byline is omitted since the panel is the paper. This closes open item 5 from the 09-19 log.
- **Refresh wrapper** `5_skilltree/R/refresh.R`: fetch → check `--log` → build_tree, stopping at the first failure.
- **Styles:** `$tiers` map + `tier-colour` mixin in `theme.scss`, used by `[data-tier]` on panel rows, page
  entries and the card. Bronze #B87A4B, Silver #B9BCC6, Gold = --st-gold, Platinum #C9E4EC, Legendary #E0A0FF,
  Celestial paper.

## The first real fire

Snapshot 2026-09-20 vs 2026-09-18: no citation count moved in two days; 12 `paper-percentile` achievements fired
(1 Gold, 7 Silver, 4 Bronze) because the earlier snapshot had no percentiles. Logged deliberately (open item 1:
the tutorial floor drowns you in boxes). No career-level entry has fired yet, so the origin numeral and the
sheet section were verified with a synthetic `tree.json` served from the scratchpad.

## Verified

Headless Chrome over a local server: tree at rest (numerals on 12 hexes), pinned Nature-adjacent hex with the
panel section, `#me` with three synthetic career entries, achievements page, homepage card. Real-browser hover
check owed by Peter, per the standing rule.

## Still open (from the 09-19 list)

Total-citation ladder stretch (2), h/i10 milestone ladders (3), manual achievements for talks/grants/awards (4).
Peter has not reviewed the drafted wording; the ledger is regenerable with `--replay` after he does.

## Review pass (same day)

Peter, from the browser: the percentile achievement was "way too plentiful", and the rotated numerals looked odd.

- **Percentile rule** now `min_age: 2` (a paper must be two calendar years old at the snapshot date; implemented
  in the checker so eligibility is judged per snapshot, and an under-age paper counts as 0 at the old snapshot
  so the first eligible snapshot fires the rung it already sits on) and a top-3% ladder, 97 / 98 / 99 / 100 =
  Silver / Gold / Platinum / Legendary. Replayed: 12 entries became 1 (raffington_2023, Gold). `--replay` did
  exactly what it was built for on its first day.
- **Numeral** is upright, centred on the bottom vertex, 0.17 w up at 0.14 w. At that height the two lower edges
  are ~0.59 w apart, so VIII and XIII (checked with a synthetic tree) clear the border. `?v=2026-09-20b`.
