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
