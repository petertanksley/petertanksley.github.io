# 2026-09-19 — Achievements: DCC register, rule shape, ladders, percentile rule, ledger

Evening session, after the impact pips and phase stickers. **Uncommitted at sign-out**; everything below is
tested against synthetic snapshot pairs in the session scratchpad, nothing has fired for real yet.

## What was decided

- **Register** (from the DCC wiki, fetched through its MediaWiki API; the HTML is Cloudflare-walled): every
  achievement is header, title, body (fact then mock, second person), and a `Reward:` line that is either a
  tiered box themed to the feat or a joke standing in for one. Routine progress gets no box. Written up with
  verbatim examples and the site mapping in `5_skilltree/ACHIEVEMENTS.md`. Camden's 2026-04-01 post (LLM-generated
  achievements) contributed only the output shape; generated prose at fire time was rejected.
- **Rule shape** in `data/achievements.yml`: `title`, `body`, `reward` (joke text, or `{type, tier}` with `tier`
  as a fixed tier or a ladder of `{at, tier}` rungs; `type` may be a map by the paper's dominant area).
- **Triggers**: step, round, threshold kept; `log10` added then superseded by `ladder` (fires when the value
  reaches a rung of the reward ladder that the old value had not). Peter: "attainable, not rock-star"; log10 left
  nothing above Gold reachable. Per-paper counts use the **quarters** ladder 1 / 10 / 25 / 50 / 100.
- **One rule per kind, expanded over every paper**: a metric containing `articles.*.` expands to one rule per
  article in `articles.yml`; `{paper} {venue} {year} {times} {top}` fill from the paper. Ledger id is
  `<rule>-<article id>` and entries carry `article:` for a future link to the hex.
- **Percentile rule**: `fetch_scholar.R` now requests OpenAlex `cited_by_percentile_year` and stores the
  conservative end as `articles.<id>.percentile`, only for papers with a full calendar year behind them (the
  publication-year cohort is mostly uncited and inflates the band). Rungs 90 / 95 / 98 / 99 / 100 because the
  measure runs high (a 4-citation 2021 paper sits at 89). Dry run against the live API: real values 88–98.
- **Ledger**: `check_achievements.R --log` appends fired achievements in full to `data/achievements_log.yml`
  (committed, append-only, idempotent on id + snapshot date, `--ledger <file>` for tests). The site will render
  from the ledger, never from the rules. **Where on the site is undecided.**
- Box types in use: Appendix (total citations); Flask / Handcuff / Challenge Coin by domain, Adventurer on a tie.
- The "first blood" title was dropped (a gaming idiom over a mortality paper); the id `first-blood-correctional`
  was folded into the generic rule anyway.

## Drafted lines (Bob's; Peter to edit in the YAML)

h-index step, i10 step, citations per hundred, per-paper cited, per-paper percentile. See `achievements.yml`.
Peter has not yet reviewed the wording.

## Open decisions for next session

1. **First-run flood.** The 2026-09-18 snapshot has no percentiles, so the first real refresh will fire ~14
   percentile achievements at once. On theme (tutorial-floor loot) or run the checker once *without* `--log`
   to set the baseline. Peter's call.
2. **Total citations**: stretch the ladder to Bronze <500, Silver 500, Gold 1000, Platinum 2500, Legendary 5000
   (still fires every hundred)? Proposed, not done.
3. **h-index / i10 milestone ladders** alongside the step jokes (h 15/20/25/30, i10 20/30/50, "Committee Box")?
   Proposed, not done.
4. **Manual achievements** for talks, grants, awards, media: an append-only manual file merged into the ledger
   by `--log`, with templates per kind (talk Silver, grant Gold in a Grant Box, award Platinum, reviewing none).
   Proposed, not done.
5. **Headline length**: full titles make long headlines. Options: a `short:` per article, or headline carries only
   "Cited once. Bronze Challenge Coin Box." and the body names the paper.
6. **Where achievements render**: news feed, own page, tree panel. Not discussed yet.

## Files touched (uncommitted)

`5_skilltree/ACHIEVEMENTS.md` (new), `5_skilltree/data/achievements.yml`, `5_skilltree/R/check_achievements.R`,
`5_skilltree/R/fetch_scholar.R`, `CLAUDE.md` (citation-stats bullet), `bob.md`, this log.
