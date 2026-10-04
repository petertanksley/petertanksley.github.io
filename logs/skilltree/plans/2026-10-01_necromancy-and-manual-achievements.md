# Plan: Necromancy + manual achievements

**Status:** COMPLETED 2026-10-03 (approved same day; Gold box confirmed). Built and verified; the backfill is seeded but
not yet logged, pending Peter's check of `achievements_manual.yml`. Session log: `logs/skilltree/2026-10-03_necromancy-manual.md`.

Decided today: achievements stay DCC-faithful. No locked or `???` slots, anywhere. They appear when they fire.

## 1. Necromancy (citation-driven, automatic)

**The data problem.** Only three snapshots exist (09-18, 09-20, 09-27), so "dormant for a year" can't be read
from snapshot diffs for years. OpenAlex carries per-work `counts_by_year`. Add it to the works `select=` in
`fetch_scholar.R` and store it as `articles.<id>.by_year` in each snapshot.

**Rule (as decided).** A paper is *dormant* at the old snapshot when it is at least `min_age: 3` calendar years old and
had zero citations in the last `dormant_years: 1` complete calendar year and so far in the current one. It fires when
the next snapshot shows its OpenAlex count go up. Key = `necromancy-<article id>-<snapshot date>`, so a paper can rise
more than once if it dies again.

**New trigger:** `revival`, in `check_achievements.R`, alongside step/round/threshold/ladder. It reads
`by_year` from the old snapshot to judge dormancy and the per-paper count to judge the rise.

**Reward:** one flat Gold box (decision 2).

**Guardrail.** Necromancy jokes on a mortality paper are exactly the "first blood" problem from 09-19. Resurrection
wording must stay about the *paper*. Mortality-cohort papers either get a wording variant list with no death
imagery, or are excluded by an `exclude_tag`. See question 3.

## 2. Manual achievements (append-only file)

**File:** `5_skilltree/data/achievements_manual.yml`, hand-appended. One entry per event:
`{kind, date, what, note?}`. Kinds and templates live in `achievements.yml` under a `manual:` block, the same
register (title variants, body = fact then mock, reward).

Proposed kinds and rewards (from the 09-19 proposal, plus today's):

| kind | reward |
|------|--------|
| talk | Silver box |
| grant | Gold Grant Box |
| award | Platinum |
| media | Bronze |
| rr_survived | joke reward |
| irb_first_try | Legendary |
| desk_reject | joke reward, no box |
| review_done | Bronze ceiling, ever |

Celestial stays reserved for tenure (one manual kind, `tenure`, which never fires on its own).

**Plumbing.** `check_achievements.R --log` merges new manual entries into the ledger (key
`<kind>-<date>-<slug>`), idempotently, with the same archival rules as citation entries. The site already renders
from the ledger, so no rendering change.

**Reviews completed** could later read from the `/bob review` archive instead of hand entry. Out of scope for v1.

## Files

`R/fetch_scholar.R`, `R/check_achievements.R`, `data/achievements.yml`, new `data/achievements_manual.yml`,
`ACHIEVEMENTS.md`, repo `CLAUDE.md` (one line), `bob.md`.

## Verification

Synthetic snapshot pairs in the scratchpad (a dormant paper revived, a paper too young, a paper still dormant).
Manual entries round-trip through `--log` twice with no duplicates. `--replay` reproduces the ledger exactly.
Render `achievements.qmd` and the homepage card locally and check them.

## Decisions (Peter, 2026-10-01)

1. **Dormancy:** zero citations in the last complete calendar year; paper at least 3 years old (`dormant_years: 1`,
   `min_age: 3`). No ladder on silence length.
2. **Reward:** since dormancy is a single threshold, one flat themed box, Gold (confirmed by Peter 2026-10-03).
3. **Mortality papers:** they can fire, but draw from a separate death-free variant list (the paper *wakes up*,
   is *dusted off*, *found in the archive*), never rising-from-the-dead imagery. Selected by the paper's tag in
   `articles.yml`.
4. **Manual backfill:** yes. Seed `achievements_manual.yml` from the CV's talks, grants and awards, dated to the
   real events. Peter checks the seeded list before the first `--log`.
