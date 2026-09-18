# Google Scholar stats on the skill tree, plus the achievements data layer

**Status:** COMPLETED (2026-09-18) · Project: `PROJ_tanksley_website` · Copy to `logs/skilltree/plans/2026-09-18_scholar-stats.md` on approval.

## Context

Peter wants his Google Scholar numbers on the site, and later Dungeon Crawler Carl-style achievement announcements when they cross thresholds (backlog item recorded in `logs/skilltree/2026-09-18_article-stickers.md`, "Future work" 2 and 3). Probes today: Google serves the public profile (`YnIBrB8AAAAJ`) to an R client from Peter's Mac (HTTP 200; 446 citations, h 12, i10 15), and OpenAlex answers by ORCID `0000-0002-3449-2838` (347 / h 10 / i10 12, `A5080880634`). Scholar is the number people compare; OpenAlex is the one that never blocks.

Decisions (Peter, 2026-09-18): fetch runs **locally** like `build_tree.R` and commits `www/scholar.json` (CI has no R and Scholar blocks datacenter IPs); the stats live in a **small card tucked into the top-right corner of the tree** (the only empty quadrant: axes point right, lower-left, upper-left); this build ships the **data layer for achievements** (dated snapshots + rules scaffold + a dry-run diff), announcements come in a second pass once Peter has written reward lines.

Reuse: `add_article.R`'s `httr2` + polite `User-Agent` pattern; `helpers.R::read_articles()`; the `.skilltree` box is already `position: relative` and `fitAroundPanel()` pads the wrap when the drawer opens, so an absolutely positioned card inside `.skilltree` stays clear of the panel for free; `--st-gold` token; `_quarto.yml` `project.resources` for JSON assets.

## Design

### 1. Fetcher — `5_skilltree/R/fetch_scholar.R` (new)

`Rscript 5_skilltree/R/fetch_scholar.R [--dry-run] [--no-openalex]` from repo root.

- Constants at top: `SCHOLAR_ID <- "YnIBrB8AAAAJ"`, `ORCID <- "0000-0002-3449-2838"`, `MAILTO`.
- **Scholar via the `scholar` package** (CRAN 1.0.0; install if missing, the way `build_tree.R` assumes `magick`): `get_profile()` → total citations, h-index, i10; `get_citation_history()` → citations per year; `get_publications()` → title, year, cites, pubid (handles Scholar's paging). Wrapped in `tryCatch`; on failure (block/captcha/HTML change) fall back to a raw `httr2` + `rvest` read of `#gsc_rsb_st` (the probe that worked today), and if that fails too, keep the previous snapshot's Scholar block and warn loudly.
- **OpenAlex cross-check** via `httr2`: `authors/https://orcid.org/<ORCID>` → works_count, cited_by_count, h_index, i10_index, counts_by_year. Reliable, cheap, always present.
- **Per-article matching** (for the JSON, not displayed yet): normalise titles (lowercase, strip punctuation/diacritics, collapse spaces) and match Scholar rows to `articles.yml` ids by exact normalised title, then by `adist()` ≤ 8 with the same year; unmatched rows listed in the console. Also OpenAlex per-work `cited_by_count` by DOI for the 28 articles with a DOI (one filtered request, `filter=doi:...|...`).
- **Outputs:**
  - `www/scholar.json` (committed, ~5 KB): `{ meta: {fetched, scholar_id, orcid, sources}, scholar: {citations, citations_5y, h_index, h_index_5y, i10, i10_5y, by_year: [{year, cites}]}, openalex: {works, citations, h_index, i10, by_year}, articles: {<id>: {scholar: n, openalex: n}} }`.
  - Snapshot `5_skilltree/data/scholar/YYYY-MM-DD.json` (same content; committed; one per fetch day, overwritten on same-day reruns). This is the history the achievements diff reads.
- `--dry-run` prints the summary table and the unmatched titles, writes nothing.
- Header comment documents: Scholar has no API, this is scraping a public page, run it by hand and commit; expect occasional blocks; never run from CI.

### 2. Stats card — `www/skilltree.js` + `theme.scss` + `skilltree.qmd`

- JS: load `www/scholar.json` alongside `tree.json` (`Promise.allSettled`; the tree must draw even if the stats file is missing or stale). Render into a new `<div class="st-stats">` appended to `#skilltree` (inside the `position: relative` box, so it moves with the tree when the drawer pads the wrap):
  ```
  GOOGLE SCHOLAR                 (eyebrow, mono, gold)
  446        12         15
  citations  h-index    i10
  as of Sep 18, 2026 · profile →   (soft, links to the Scholar page)
  ```
  Numbers are the all-time Scholar figures; a `title` tooltip on each shows the since-2021 figure and the OpenAlex figure. No sparkline this pass.
- SCSS: `.skilltree .st-stats { position: absolute; top: 0.6rem; right: 0.6rem; }`, dark card on `--st-panel` with a 1px `--st-rule` border and a 3px `--st-gold` left rule (rhymes with the panel's `--node` left border), mono numbers ~1.4rem, labels 0.7rem `--st-soft`. Below 720px (the tree scrolls sideways there) switch to `position: static` and render above the tree so it never overlaps hexes. `pointer-events` only on the link.
- `skilltree.qmd`: bump `?v=` to `2026-09-18e`.
- `_quarto.yml`: add `www/scholar.json` to `project.resources` (JS-fetched assets are invisible to Quarto).

### 3. Achievements scaffold (data layer only)

- `5_skilltree/data/achievements.yml` (new): rule schema plus a few starter rules with placeholder reward lines for Peter to rewrite:
  ```yaml
  # metric: scholar.citations | scholar.h_index | scholar.i10 | articles.<id>.scholar
  # trigger: step (any increase) | round (crosses a multiple of `every`) | threshold (crosses `at`)
  - id: h-index-up      metric: scholar.h_index  trigger: step
    title: "Level up: h-index {new}"
    reward: "Reward? Nothing. You went into academia because you thought it was fun, you sick, sick man. Not for the money. You get nothing."
  - id: citations-round metric: scholar.citations trigger: round every: 100
    title: "{new} citations. Achievement unlocked: people read the appendix."
    reward: "..."
  ```
- `5_skilltree/R/check_achievements.R` (new): loads the two newest snapshots in `data/scholar/`, evaluates every rule, prints what would fire with the rendered title and reward. **No writing to `news.yml` in this build**; the `--post` flag that appends a news entry in the DCC voice is the next pass, once Peter has written the lines. With one snapshot it prints "no previous snapshot; nothing to compare" and exits 0.

### 4. Housekeeping

- `CLAUDE.md` skill-tree section: three lines on `fetch_scholar.R` (local only, commit the JSON, expect blocks), the snapshot folder, and the achievements scaffold.
- `bob.md`: move "Google Scholar stat bar" from backlog to done; leave "DCC announcements" in backlog with the note that the data layer exists.
- Log: `logs/skilltree/2026-09-18_scholar-stats.md`.

Out of scope: per-article counts in the flip panel (data is in the JSON; one JS line later), homepage placement, a scheduled Action, posting announcements.

## Execution order

1. Install `scholar`; write `fetch_scholar.R`; `--dry-run` to see the tables and unmatched titles.
2. Real run → `www/scholar.json` + first snapshot. Inspect the JSON.
3. `achievements.yml` + `check_achievements.R`; run it (expects "no previous snapshot").
4. JS card + SCSS + resources + cache-buster; `quarto render skilltree.qmd`; serve `docs/` on 8765; screenshot with the drawer closed and open.
5. CLAUDE.md, bob.md, log. Commit only on Peter's word.

**External-service note:** the fetch is GET requests to Google Scholar (public profile page) and OpenAlex (open API) carrying only Peter's public Scholar id and ORCID. Approving the plan authorises those fetches and the CRAN install of `scholar`.

## Verification

- `fetch_scholar.R --dry-run` prints Scholar (all/5y), OpenAlex, and per-article matches; unmatched Scholar rows listed (expect the CV's non-article items).
- `www/scholar.json` validates (`jq .scholar.h_index` = 12 today) and `5_skilltree/data/scholar/2026-09-18.json` exists and is identical.
- `check_achievements.R` exits 0 with the "no previous snapshot" message; then a synthetic second snapshot (copy with h_index+1, in the scratchpad, pointed at via `--dir`) makes the `h-index-up` rule print its title and reward.
- Rendered page: card in the top-right, numbers match the JSON, link opens the Scholar profile; with a node pinned and the drawer open, the card is fully visible left of the panel; at 700px width the card sits above the tree.
- Tree still draws when `scholar.json` is renamed away (card simply absent, console note only).
- `git status` shows only the intended files; no commit without Peter's say-so.
