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

## Later the same session (appended by Bob, 2026-10-04)

**Stats card: citations-per-year bars** (b8fb51b, 6661e23). Google Scholar profile-style histogram from Scholar's own
profile series (`scholar.by_year`, not a sum over papers), first/last year on the axis, the current year marked as
partial ("so far"), hover labels with the count. Code in `skilltree.js` near the stats card builder (`yearBars()`).

**Hex brightness tracks Scholar citations** (6661e23). Two stages on one eased scale, level = (cites / max) ^ CITE_EASE:
below CITE_FULL the resting shade fades out (`--cite-k`), so a paper at CITE_FULL shows its art at original brightness;
above it an SVG filter brightens the art up to CITE_BOOST on the most-cited paper (SVG filter because Safari ignores
CSS `brightness()` on SVG). Constants: CITE_FULL 25 (= paper-cited Gold rung), CITE_BOOST 1.3, CITE_EASE 1.5. Linear
spread looked too even; Peter wanted "a slow ramp up". His verdict: "run with that for now". Possible later tweak:
CITE_BOOST 1.4.

**Projects page: anatomogramdata** (f1182a5). R data package entry (human body-map polygons from the EBI Expression
Atlas anatomogram sources) with docs and source links. Peter may add a line on why he built it.

**Gotchas relearned.** Every `skilltree.js` edit needs the `?v=` cache-buster bumped in `skilltree.qmd` (at
`2026-10-04l` by session end; fc001c9 was a cache-bust-only fix). `bob-push-gate.py` blocks a combined
`git commit && git push` when bob.md is still uncommitted at check time; commit, then push, as separate commands.

**Achievements review status.** Peter reviewed the 7 live ledger entries after the refresh. The full template bank
(18 rules, 122 variants, most never fired) is still unreviewed; review page at
https://claude.ai/artifact/83gcPoCxpgN6HuPdvQmLra.
