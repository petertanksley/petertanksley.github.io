# 2026-10-03 — Necromancy and manual achievements

Built the plan in `plans/2026-10-01_necromancy-and-manual-achievements.md` after Peter's go-ahead (Gold box confirmed).

## What changed
- `fetch_scholar.R`: the OpenAlex works query also selects `counts_by_year`, stored per paper as `by_year`
  (`{"2023": 4}`; `{}` never cited; `null` no record). Checked live: the field comes back as expected.
- `check_achievements.R`: `revival` trigger (`revived()`), `by_tag` overrides (`tagged()`), `trigger: manual` rules that
  never fire from snapshots, and `achievements_manual.yml` merged by `--log` / `--replay` under the archival rules.
  New `--manual <file>` flag for tests. Runs with fewer than two snapshots now (manual events only).
- `achievements.yml`: `necromancy` (Phylactery Box Gold; mortality papers get "Back From the Stacks" / "Dusted Off" /
  "Found in the Archive", Archive Box Gold), and seven manual kinds (talk, grant, award, media, irb_first_try,
  review_done, tenure). rr_survived and desk_reject were written, then dropped at Peter's call: they would never be
  logged. review_done kept for now; Peter on the fence.
- `articles.yml` + `extract_cv.R`: new judgement field `tags`; `[mortality]` on tanksley_2025_mortality,
  tanksley_2026_clarifying, tanksley_2026_correctional. `extract_cv.R` now reads judgement fields by name, so a field
  added later reads as `~` instead of an NA-named element.
- `achievements_manual.yml`: first seeded from the CV (35 events), then emptied at Peter's call (below).
- `achievements-listing.ejs` / `achievement-home.ejs`: date groups of hand-logged events read "Event" and print
  `when` ("November 2023", "2023") instead of a fabricated day. One sentence added to the achievements page intro.

## Verified (scratchpad)
- Synthetic snapshot pairs: dormant 2019 paper fires (silent 2 years); mortality paper fires with archive wording;
  too-young, still-dormant, already-awake-this-year and count-rise-without-by_year cases do not.
- Replay of the real ledger with no manual events is byte-identical. `--log` twice: second adds nothing. `--replay`
  after logging keeps all 40 entries, no duplicates, and is a fixed point.
- Rendered `achievements.qmd`, `index.qmd` and ran `build_tree.R` in a scratch copy with the test ledger: groups and
  labels correct, homepage card still the 09-27 h-index entry (numeral XL), 36 career-level entries on the origin.

## Revision, same session: forward only, reviews automatic
Peter: no retrospective achievements, things pop up moving forward; only cumulative milestones (30th article, 50th
review) may count history. Make reviews automatic from the `/bob review` archive.
- CV backfill removed; `achievements_manual.yml` is header only. `review_done` manual kind removed.
- New `data/career.yml` + `career: {articles, reviews}` in each snapshot (`fetch_scholar.R`). Reviews = undated
  baseline (8, ASSUMED one per venue on the archive's undated line) + each `submitted YYYY-MM-DD` in the archive
  (2 today) = 10. Articles = CV-numbered entries = 28.
- Rules: `review-done` (step, `forward_only: true`, Bronze), `review-milestone` (10/25/50/100, all Bronze per the
  Bronze-ceiling decision), `article-milestone` (10 Bronze / 20 Silver / 30 Gold / 50 Platinum / 100 Legendary).
  New rule field `forward_only` in the checker.
- Blind-review guard: only the count is published; review achievements are dated to the refresh, no journal.
- Verified: first snapshot carrying counts fires only the two ladders (reviews 10 Bronze, articles 20 Silver), not the
  per-review rule; the next pair fires per-review (10 -> 11) and the 30th article (Gold). Real ledger replay identical.

## Revision 2: review archive as a table
The undated baseline was unreliable (AJCJ spans three manuscripts, PPR has two in 2026). The review queue card's legacy
folders were moved into `<JOURNAL>/<YEAR>/<topic_slug>/review_N/` and its Archive became a table, one row per
submitted round (16; older dates `~` from file timestamps). `fetch_scholar.R` now counts table rows; `reviews_undated`
is gone from `career.yml`. `/bob review done` (shared bob agent) appends a row. Narrative in the reviews folder's
`docs/logs/2026-10-03_layout-migration.md`.

## Open
- Next refresh (`refresh.R`) is the first with `by_year` and `career`: expect the review Bronze and the article
  Silver, nothing else new. Necromancy needs one more refresh after that.
- Real dormancy candidate: motz_2019_every, last cited 2023 per OpenAlex.
