# 2026-10-10 — OpenAlex dropped; Scholar only

Peter decided to drop OpenAlex entirely (the open question from 10-04: drop it, or keep it for the Necromancy and
percentile achievements only).

## What changed

- `fetch_scholar.R`: no OpenAlex fetch, no `--no-openalex` flag, no ORCID/mailto. Snapshots now carry no `openalex`
  block and no per-article `openalex`, `percentile` or `by_year` fields. Old snapshots keep theirs; nothing reads them.
- **Percentile achievement retired.** Scholar has no year-percentile, so `paper-percentile` was deleted from
  `achievements.yml`. Its one ledger entry (Raffington 2023, Clinical Psychological Science, Gold Flask Box, earned
  2026-09-20) was **removed by hand at Peter's request**. This is the one deliberate exception to "earned is earned".
  `--replay` does not bring it back because no rule produces it any more (checked: replay keeps 6 entries, adds 0).
- **Necromancy moved to Scholar.** The rule's metric is now `articles.*.scholar`, and `revived()` reads Scholar's
  per-paper histogram (`scholar_by_year`, fetched since 10-04 for the panel bars) in place of OpenAlex `counts_by_year`.
  Tested on a synthetic dormant-then-cited pair (`tanksley_2020_identifying`): it fires, Gold Phylactery Box,
  "3 silent years". No paper is actually dormant at the moment.
- **Staleness fix that came with it.** The fetcher reused a paper's histogram whenever its count matched the previous
  snapshot, so a failed histogram fetch left stale bars forever once the count stopped moving. With Necromancy reading
  the histogram, that would have silently swallowed a revival. Snapshots now record `scholar_by_year_n` (the count the
  histogram was fetched at), and a paper is re-fetched whenever its count has moved past that.
- Stats-card tooltips: "Since 2021: N" only (the OpenAlex figure is gone). `tree.json` rebuilt (6 achievements).

## Achievement-template review (same session, not yet acted on)

Points raised for Peter, decisions pending:
- `grant` will fire first (NIOSH pilots, once signed). "Indirect Costs Unlocked" and "the university will take its
  share" assume an extramural award; check before logging the intramural pilots. Two pilots: two events or one?
- `h-index-up` + `h-index-milestone` (and the i10 pair, and `review-done` + `review-milestone`) both fire on the same
  refresh when a rung is crossed. Proposal: a milestone suppresses its matching step rule for that run.
- `review-done` fires on every review; consider dropping it and keeping only the milestones.
- `tenure` has one variant and may not fit a research-scientist line; keep as a joke or cut.
- `paper-cited` is the noisiest rule (28 papers, five rungs); watch the next refresh.

## 2026-10-11 — pushed; weekly automatic check

Pushed as `c946101` after rebasing onto three 10-06 commits from the other clone (two-page CV); bob.md conflict merged.

Peter asked for a weekly automatic stat check. Chosen: **refresh + notify, never commit or push** (his per-push rule
stands), **laptop only**, **Mondays 08:30**. Cloud agents and GitHub Actions were ruled out because Scholar blocks
datacenter IPs. Built:
- `fetch_scholar.R --skip-unchanged`: exit 3 (Scholar unreachable, nothing written) or 4 (no count that achievements
  read has moved: profile stats, per-paper counts, lineage, career), so quiet weeks add no snapshot to git.
- `5_skilltree/R/weekly_check.R`: fast-forwards from GitHub when the tree is clean, runs fetch / `--log` / `build_tree.R`,
  logs to `~/Library/Logs/tanksley_website_weekly.log`, and posts a macOS notification (numbers moved, achievements
  fired, "ask Claude to push").
- launchd agent `~/Library/LaunchAgents/com.petertanksley.website-weekly-check.plist` (machine-local, not in the repo).

First live run via `launchctl kickstart`, 2026-10-11: exit 0, no macOS privacy block on `~/Documents`, citations
456 → 462, h 13, i10 15, nothing fired, 3 per-paper histograms re-fetched. Also the first live run of the Scholar-only
fetcher: `scholar.json` now carries no OpenAlex block.

## 2026-10-11 — achievement-template decisions

Peter's calls on the review points above:
- **Grant wording neutral.** "Indirect Costs Unlocked." became "Funded. Now Do It."; the "university will take its
  share" body became one about slow money and punctual reporting deadlines. Every variant now fits intramural awards.
- **Two NIOSH pilots = two events.** Rendered on a test date both drew the same title and body (the variant is a hash of
  the key; 1-in-3 per field). The pick depends on the date, so bob.md says: log with `slug: dnam` / `slug: bioage`,
  dry-run, change a slug if the cards match.
- **Milestone wins.** New `suppresses:` field; `h-index-milestone` suppresses `h-index-up`, `i10-milestone` suppresses
  `i10-up`. Implemented in `fire()` after the rule loop (printing moved after the filter). Synthetic test h 13 → 15,
  i10 15 → 16: milestone only for h, `i10-up` still fires.
- **Cut `review-done`** (Bronze per review; the 10/25/50/100 milestones remain, at 16 now) and **cut `tenure`**
  (not on the tenure track; `skilltree.js` already says so on the character sheet). Celestial is now awarded by nothing.

Replay stable after all of it: 4 snapshot pairs, 6 entries, 0 added.
