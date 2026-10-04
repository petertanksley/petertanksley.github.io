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

## Per-article citations on the tree
Peter's decisions: Google Scholar numbers only (he now doubts OpenAlex: Barnes 2019 showed 60 OpenAlex citations
vs 29 on Scholar, 42 of them dated 2023 and one before publication). Count in the tooltip meta line; count plus a
per-year bar chart in the side panel. The hex and the stats card are unchanged. OpenAlex is off display but still
feeds the Necromancy and percentile achievements; dropping it entirely is deferred.

- `fetch_scholar.R` keeps Scholar's `pubid` per matched paper and fetches each paper's citation history
  (`scholar::get_article_cite_history`) into `articles.<id>.scholar_by_year`. It re-fetches only papers whose count
  changed since the previous snapshot, with 2-5 s pauses; two failures in a row stop it, and those papers keep their
  previous bars. First run: 25 requests, no block.
- `build_tree.R` reads `www/scholar.json` into `node.cites = {n, by_year}` and `meta.cites` (source, as-of date).
- `skilltree.js`: `· 31 cites` in the tooltip; `citesHTML()` in the panel under the impact-factor block. One bar
  per year from publication to the as-of year, "No citations yet." for an indexed paper with zero, nothing for one
  Scholar has not indexed (e.g. tanksley_2026_correctional). Styles are `.sp-cites*` in `theme.scss`.
- The bars can sum one or two short of the headline count, because Scholar's year breakdown leaves out undated
  citations. The current year's bar is a partial year.
