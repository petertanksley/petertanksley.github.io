# 2026-09-19 — Impact-factor pips on the skill tree

**Goal.** Mark high-impact venues on every hex at rest and explain the mark, with the number, on the
article's panel. Peter's examples: Nature, Nature Human Behaviour, Lancet Regional Health – Americas, AJPH.
Plan: `plans/2026-09-19_impact-factor-badges.md` (APPROVED same day: bands 5/10/25, pips at the top
vertex, CV unchanged).

## Data: where impact factors come from

The JIF is Clarivate's. Tested on this machine before deciding:

| Source | Finding |
|--------|---------|
| `scholar` 1.0.0 | `get_impactfactor()` removed (NEWS). `get_journalrank()` fetches Scimago live; HTTP 403 today; current year only. |
| `JCRImpactFactor` (CRAN) | real JIF, offline, but JCR 2010–2019 only. |
| `sjrdata` (GitHub) | Scimago 1999–2025 incl. `citations_doc_2years`; 19/24 venues match. But the metric runs far below JIF for high-JIF journals (JCR 2019: Nature 42.8 vs 11.6, NHB 12.3 vs 5.6, AJPH 6.5 vs 2.7) and 22/24 venues are Q1, so it neither matches the number people mean nor discriminates. |
| OpenAlex `sources` | `2yr_mean_citedness`, current only (NHB 14.2). |
| Clarivate APIs | need a JCR API subscription. |

Decision: raw JCR exports from the web portal via the TXST library, one CSV per JCR year, committed
under `5_skilltree/data/jcr/`. Peter exported 2018–2025 in about fifteen minutes (three journals
missed on the first pass; 2021/2023/2025 re-exported). A Springer journal, "International Journal of
Environmental Research", was selected by mistake for IJERPH in every file; harmless, the builder
ignores unmatched titles. Two genuine gaps: Frontiers in Sociology and Current Opinion in Psychology
were ESCI in 2018 and had no JIF; the tree reads the nearest year (2022 and 2019) and says so.

The Scimago cross-check column proposed in the plan was dropped: `sjrdata` is not on CRAN and the
number would only confuse next to the JIF. Deviation from plan, deliberate.

## Build

- `5_skilltree/R/build_journals.R` (new): reads every `data/jcr/jcr_*.csv` (year from the `<year> JIF`
  header; layout notes in `data/jcr/README.md`), collapses journal × category rows (JIF repeats; keep
  best quartile), matches venues on normalised title (`&`→and, leading "The" and punctuation dropped)
  plus two `ALIASES` ("Nature Human Behavior", "Frontiers of Sociology"), writes `data/journals.yml`.
  Gotchas hit: a trailing comma on every data row makes `read.table` take column 1 as row names; the
  OA cell is written `"53.07"%`; a `NULL` year in the JIF list misaligns `names()` and `unlist()` (use
  `map_dbl` with an explicit NA).
- `build_tree.R`: `JIF_LAG <- 1`, `IMPACT_TIERS <- c(5, 10, 25)`, `IMPACT_LABEL`; `impact_of()` picks
  the JCR year `year - JIF_LAG`, else the nearest available (ties to the earlier year) and flags it;
  per node `impact {jif, jcr_year, requested_year, nearest, tier, quartile}`; `meta.impact {tiers, lag,
  label, note, source}` so legend and panel read the same definitions. Validation warns (does not
  fail) for a non-preprint venue with no JIF data. Summary line prints tier counts and fallbacks.
- `www/skilltree.js`: pips as `<g class="hex-pips">` of 1–3 circles (r = 5 % of hex width, pitch 2.5 r,
  3.4 r below the top vertex) appended after `hex-ring`, so above the shade; legend item built from
  `meta.impact`; tooltip meta gets `●● JIF 10.2`; panel gets a `.sp-venue` block (number, JCR year or
  nearest-year sentence, pips + label) and the one-line note, for every node with a JIF. aria-label
  carries the label and number. `?v=2026-09-19a`.
- `theme.scss`: `--st-gold` moved from `.skilltree` to `.skilltree-wrap` so the legend sees it;
  `.hex-pips circle` gold with an ink stroke, 0.6 opacity on muted nodes; `.sp-venue*` and a gold
  `.pips` rule in the tooltip (the panel is portaled to `<body>`, so it carries its own `--sp-gold`).

## Result

28 of 30 nodes carry a JIF (the two preprints do not). Pips: 3 × 2 (Nature 56.1, NHB 29.9), 2 × 1
(Psychological Science 10.2), 1 × 4 (LRHA 9.1 and 7.6, AJPH 7.8, JPSP 6.4). Clinical Psychological
Science misses three times at 4.8; Peter held the bottom band at 5 rather than badge eleven papers.
Verified in headless Chrome over a local server (fetch of `tree.json` is blocked on `file://`): at
rest, legend, and pinned for Nature, AJPH and the Frontiers fallback. Real-browser hover check still
owed by Peter, per the standing rule.

## Notes for later

- The year rule does real work: NHB reads its 2022 peak (29.9, three pips); the current figure is 17.5.
- New venue: export its JCR year(s) into `data/jcr/`, rerun `build_journals.R` then `build_tree.R`.
- Refreshing all years is one export per year; the builder accepts several files per year.
