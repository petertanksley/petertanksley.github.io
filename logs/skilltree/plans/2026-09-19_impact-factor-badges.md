# Impact-factor badges on the skill tree — scoping plan

**Status:** COMPLETED 2026-09-19 (bands 5/10/25, pips at the top vertex, CV unchanged). Implementation log:
`../2026-09-19_impact-factor-pips.md`. Deviation: the Scimago cross-check column was dropped (not on CRAN, and a
second, lower number beside the JIF would confuse).

## Goal

Mark articles published in high-impact venues (Nature, Nature Human Behaviour, Lancet Regional
Health – Americas, AJPH, and whichever others clear the bar) with a small notation visible on every
hex at rest, and explain the notation, with the actual number, on the article's detail panel when
selected. The impact factor used is the one in force when the paper appeared, which means pulling
historic values, not just current ones.

## What exists (read 2026-09-19)

- `5_skilltree/data/articles.yml` carries `venue` (the verbatim CV string) but nothing about the
  journal itself. 24 distinct venues across 30 articles; two are preprint servers.
- `build_tree.R` validates, lays out, and writes `www/tree.json`; every node already carries
  `venue`, `status`, `role`, `featured`. "R thinks, JS draws" is the standing rule.
- `www/skilltree.js` draws each node as `<image>` + `hex-shade` + `hex-ring`. The ring's stroke width
  encodes role, its dash encodes status, its colour is the area mix. All three visual channels on the
  ring are spoken for, so the badge needs a new element, not a ring restyle.
- `--st-gold` (#D9A441) is the accent already used for Peter's origin ring and the Scholar card.
- The panel (`panelHTML`) has a `.sp-meta` line (year · venue · citation · status) and section
  headers (`.sp-h`). The tooltip (`tooltipHTML`) has a `.tt-meta` line.
- `fetch_scholar.R` already talks to OpenAlex by DOI and writes `www/scholar.json`; a journal-metrics
  fetcher can reuse its `oa_get` helper.

## Design

### 1. Data: `5_skilltree/data/journals.yml` (generated from JCR exports, not hand-typed)

One record per venue string, keyed exactly as `articles.yml` spells it (so nothing on the CV has to
be renamed to make the join work). Fields:

```yaml
- venue: Nature                      # exact match to articles.yml venue
  issn: 0028-0836
  jif:                               # Clarivate JIF by JCR year
    2018: 43.070                     # from the JCRImpactFactor package (covers JCR 2010-2019)
    2019: 42.778
    2024: ~                          # from data/jcr/<year>.csv, exported from JCR via the TXST library
    2025: ~
  scimago:                           # cross-check only: sjrdata, citations_doc_2years + quartile
    2024: {cites_doc_2y: 18.53, quartile: Q1}
  jif_source: JCRImpactFactor 1.0.0 (2010-2019); JCR export via TXST library (2020-2025)
  notes: ~
```

**Sourcing, tested 2026-09-19** (details in the session log):

| Source | Coverage | Use |
|--------|----------|-----|
| `scholar` 1.0.0 | `get_impactfactor()` removed (NEWS); `get_journalrank()` fetches Scimago live, HTTP 403 today, current year only | none |
| `JCRImpactFactor` 1.0.0 (CRAN) | real Clarivate JIF, JCR years 2010-2019, exact-title lookup, offline | fills 2018-2019 |
| JCR full-list CSV export via TXST library | real JIF, one file per JCR year | all eight years 2018-2025 exported 2026-09-19, in `data/jcr/` |
| `sjrdata` (GitHub ikashnitsky/sjrdata, updated 2026-06) | Scimago 1999-2025: SJR, quartile, `citations_doc_2years`; 19/24 venues match by normalised title | cross-check column; fallback if no JCR access |
| `openalexR` / OpenAlex `sources` | `2yr_mean_citedness`, current year only | not used |
| `wosr` / Clarivate APIs | real JIF any year | needs a JCR API subscription; not available |

Why not Scimago alone: its two-year cites/doc runs far below JIF for high-JIF journals (JCR 2019,
Nature 42.8 vs 11.6; NHB 12.3 vs 5.6; AJPH 6.5 vs 2.7) because Scopus counts differently and every
document sits in the denominator. AJPH would never badge. Quartile does not discriminate either:
22 of 24 venues are Q1. If JCR access turns out not to exist, fall back to Scimago end to end, set
the bands on its scale, and label the panel "Scimago 2-year cites per document", never "impact factor".

Build step: `5_skilltree/R/build_journals.R` reads `data/jcr/*.csv` + `JCRImpactFactor` + `sjrdata`,
matches on normalised title (with an explicit `aliases:` map for "Nature Human Behavior",
"Frontiers of Sociology", the leading "The" on IJERPH), and writes `journals.yml`. Preprint servers
get a record with no `jif` so the validator does not nag about them.

### 2. Rule: which year's impact factor

For an article with `year: Y`, use the JCR year `Y - 1` (the JIF that was public when the paper
appeared; JCR year N is released mid N+1). If that year has no JIF (emerging-sources journals before
JCR 2022), fall back to the **nearest** available year, never "latest", and say so in the panel. Constants in `build_tree.R`: `JIF_LAG <- 1`. The whole series stays in the YAML so the rule
can change without re-collecting.

Today's example: the AJPH paper is `year: 2026`, so it reads JCR 2025 (released June 2026).

### 3. Tiers: how many pips

Proposal: three bands, mirroring the tree's existing 0–3 vocabulary, drawn as 1–3 gold pips.

| Pips | JIF at publication |
|------|--------------------|
| 3    | ≥ 25               |
| 2    | 10 to < 25         |
| 1    | 5 to < 10          |
| none | < 5, or no data    |

Bands are named constants (`IMPACT_TIERS`) in `build_tree.R` and are written into `tree.json`
under `meta.impact`, so the legend and panel read the same definitions and the caption can never
lie about the cutoffs. **The bands are a placeholder until the table is filled**; a single cutoff
(one pip, ≥ 5 say) is the fallback if tiers feel like credential-flexing. Peter decides.

Approximate current JIFs from memory, **unverified, for band-setting only**; the real values come
from JCR:

| Venue                          | Rough JIF | Would land in |
|--------------------------------|-----------|---------------|
| Nature                         | ~50       | 3 pips        |
| Nature Human Behaviour         | ~20–30    | 2 pips        |
| AJPH                           | ~10–12    | 2 pips        |
| Psychological Science          | ~10       | 2 pips        |
| Lancet Regional Health – Americas | ~7     | 1 pip         |
| JPSP                           | ~7–8      | 1 pip         |
| Current Opinion in Psychology  | ~6–7      | 1 pip         |
| Clinical Psychological Science | ~5–7      | 1 pip         |
| Child Development              | ~5–6      | 1 pip         |
| Aggression & Violent Behavior  | ~4–5      | borderline    |
| Journal of Criminal Justice    | ~4–6      | borderline    |
| everything else                | < 4       | none          |

Note the historic rule bites here: several of these were lower in 2019–2021 than now.

### 4. Build: `build_tree.R`

- Read `journals.yml`; join to each article on `venue`; warn (not fail) for any non-preprint venue
  with no record, and for any record whose needed JCR year is empty.
- Per node, add `impact: { jif, jcr_year, tier, source, fallback }` (nulls where unknown).
- Add `meta.impact: { tiers: [...], lag: 1, label: "High-impact venue", note: "..." }`.
- Print a summary line: how many nodes per tier, which venues are missing data.

### 5. Draw: `skilltree.js` + `theme.scss`

- **At rest:** a row of 1–3 small gold pips (`<circle>` or tiny hexes, ~9 viewBox units on a 100-unit
  hex) just inside the hex's top vertex, appended **after** `hex-shade` so they stay visible when the
  tile is dimmed. No transform, no filter, nothing on hover, sticker untouched. On `muted` nodes they
  follow the ring's reduced opacity. Class `hex-pips`, colour `var(--st-gold)`.
- **Legend:** one new item, three pips + "High-impact venue", built from `meta.impact` like the rest.
- **Tooltip:** append `· JIF 50.5` to `.tt-meta` when present (short, no explanation).
- **Panel:** a "Venue" block under `.sp-meta`: journal name, pips, "Impact factor 50.5 (JCR 2025)",
  and one line from `meta.impact.note` defining the bands and naming the source. Fallback year
  gets "(latest available)" appended.
- Bump `?v=` in `skilltree.qmd`. Verify in a real browser at rest, hover, pinned, muted, and on the
  deep link, per the standing interaction rule.

### 6. Out of scope, deliberately

- **CV:** the CV stays formal and unchanged. Adding a bracketed IF per entry is a separate decision;
  `render_cv_pubs.R` could take a flag later.
- **Rating app:** journal metrics are bibliographic, not judgement fields; the app does not touch them.
- **Venue spelling:** `articles.yml` has "Nature Human Behavior" and "Frontiers of Sociology"
  (official: "Behaviour", "Frontiers in Sociology"). Those strings print on the CV; correcting them
  is Peter's call and independent of this work. `journals.yml` matches whatever is there.

## Open decisions (defaults if Peter says nothing)

1. **Tiers vs single cutoff.** Default: three bands as above.
2. **Year rule.** Default: JCR year = publication year − 1, fallback to latest.
3. **Source.** Default: six JCR full-list CSV exports (2020-2025) from the library portal into
   `data/jcr/`; `JCRImpactFactor` covers 2018-2019; `build_journals.R` does the rest. Does TXST have JCR?
   If not, Scimago end to end, labelled as a proxy, and AJPH loses its badge.
4. **Pip placement.** Default: top vertex. Alternative: bottom edge, or a single gem that grows by tier.
5. **CV.** Default: no.

## Files touched

| File | Change |
|------|--------|
| `5_skilltree/data/jcr/<year>.csv` | new; JCR full-list exports, committed |
| `5_skilltree/R/build_journals.R` | new; JCR CSVs + JCRImpactFactor + sjrdata → `journals.yml` |
| `5_skilltree/data/journals.yml` | generated; venue → ISSN, JIF by JCR year, Scimago cross-check, source |
| `5_skilltree/R/build_tree.R` | join, tier constants, per-node `impact`, `meta.impact`, validation |
| `www/tree.json` | regenerated, committed |
| `www/skilltree.js` | pips on nodes, legend item, tooltip suffix, panel Venue block |
| `theme.scss` | `.hex-pips`, `.sp-venue` styles |
| `skilltree.qmd` | bump `?v=` |
| `CLAUDE.md`, `5_skilltree/README.md` | document the new data file and rule |

## Effort

| Piece | Estimate |
|-------|----------|
| Six JCR CSV exports from the library portal | ~15 min of Peter's time |
| `build_journals.R` (matching, aliases, YAML) | ~1 h |
| R: join, tiers, JSON | ~1 h |
| JS + SCSS + browser check | ~1.5 h |
| Docs, commit | ~0.5 h |

## Verification

- `Rscript 5_skilltree/R/build_tree.R` runs clean; summary line lists tier counts and missing venues.
- `tree.json` nodes carry `impact`; `meta.impact.tiers` matches the R constants.
- Real browser: pips visible at rest and dimmed on muted tiles, unchanged on hover, legible when
  pinned at `--lit` scale; legend item present; panel shows number, JCR year, source, band note.
- Preprints and sub-threshold venues show no pips and no Venue block.
- `quarto render skilltree.qmd` succeeds; `docs/www/tree.json` updated (resources rule).
