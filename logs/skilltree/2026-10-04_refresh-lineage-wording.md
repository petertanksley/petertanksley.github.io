# 2026-10-04 — lineage wording fix and citation refresh

## Lineage wording on mortality papers
Peter reviewed the five live achievements. Two problems:
- The `paper-lineage` rule had no mortality-safe wording, unlike Necromancy. Its variants ("Patient Zero.",
  "This Is Your Fault Now.", "Roots get no light and all of the blame") could land on a paper about officers who died.
- `tanksley_2025_mortality` and `gonzalez_2025_relationships` had drawn the identical "It Grew Legs." variant, so
  the same text appeared twice on the achievements page.

Fix: a `by_tag: mortality` block on `paper-lineage` in `achievements.yml` (titles "Load-Bearing.", "Groundwork.",
"Built Upon."). `check_achievements.R --replay --fresh` re-rendered the ledger. The diff was checked: only the
mortality paper's entry changed (now "Groundwork."); the other four were byte-identical. The `tags` comment in
`articles.yml` now says the tag covers both Necromancy and lineage.

## Refresh
First `refresh.R` run since the 10-03 achievements build failed: `object 'career' not found`. The career-counts
block in `fetch_scholar.R` had been pasted inside `match_articles()`, so `career` was function-local and the
snapshot write could not see it. Moved the block to top level after `prev` is read (it needs `arts` and `prev`).

Snapshot 2026-10-04: Scholar 456 (from 451), h 13, i10 15, OpenAlex 349. Career: 28 articles, 16 reviews.
Fired: Bronze Reviewer 2 Box (16 reviews), Silver Bibliography Box (28 articles). Ledger now holds 7 entries.
