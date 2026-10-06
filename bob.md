---
project: Tanksley Personal Website & CV
type: web
status: active
priority: medium
path: /Users/PTT2/Documents/GitHub/PROJ_tanksley_website
deadline: null
target: null
effort_remaining: monitoring (annual JCR refresh each June/July; news/pubs as they happen)
weekly_commitment: 1h
last_updated: 2026-10-06
repo: https://github.com/petertanksley/petertanksley.github.io
blockers: null
blocking_others: null
importance: medium
phase: in-progress
sync: github
---

## Objectives

- Maintain current academic CV as a Quarto document (HTML + PDF output)
- Personal website with about page and occasional posts
- CV is the primary deliverable — must stay current for grant applications and job materials

## Start Here Next Session

- State 2026-10-06: clone in sync with GitHub, CI green, live site serves the full CV and not the two-page one.
  Publication count verified at 28 articles (one in press) + 2 preprints (log `logs/2026-10-06_two-page-cv-and-clone-sync.md`).
- Open for Peter: (1) drop OpenAlex entirely, or keep it feeding Necromancy + percentile achievements only?
  (2) review the unfired achievement templates (https://claude.ai/artifact/83gcPoCxpgN6HuPdvQmLra).
- Next Scholar refresh not before late October: `Rscript 5_skilltree/R/refresh.R`, then commit the snapshot,
  `www/scholar.json`, `5_skilltree/data/achievements_log.yml`, `www/tree.json`.
- Publications change in `5_skilltree/data/articles.yml`, never in the CV: edit → rate in the Shiny app if new →
  `build_tree.R` + `render_cv_pubs.R` → commit. Then hand-update the two-page CV's selected pubs and count line.

## This Week
- [ ] Nothing due; refresh not before late October
- [ ] Optional: one line on the Projects page saying why anatomogramdata exists

## Upcoming Milestones

- TBD: volume/issue/pages for entry 27 (Schwaba et al., Nature, doi:10.1038/s41586-026-10992-9) — set
  `citation:` in `articles.yml` (currently "online first"), rerun `render_cv_pubs.R`. Online first at last check (2026-10-03).
- TBD: DOI, then volume/pages, for entry 28 (Tanksley, Logan, & Barnes, AJPH, in press) — set `doi:`,
  `status: published`, `citation:` in `articles.yml`; the homepage and research-page `.worklist` blocks are
  hand-written and need the same edit; the two-page CV count line ("one in press") too. No DOI at last check (2026-10-03).
- June/July 2027: new JCR year — export all 22 journals into `5_skilltree/data/jcr/jcr_<year>.csv`, run
  `build_journals.R` then `build_tree.R`, commit. Clears nearest-year flags on papers published earlier that year.
- Backlog, unscheduled: achievement-template review (above); phase stickers beside the matching Research-page
  sections; achievements extras (total-citation ladder, box-reward variants, reviews from the `/bob review`
  archive; proposals in `logs/skilltree/2026-09-19_achievements-rules.md`); hex brightness ceiling 1.3 → 1.4 if
  the top papers look flat; optional wide scene on the Projects page (`logs/2026-09-22_trapdoor-scene.md`);
  fun-feature list (404 dungeon floor first) in `logs/2026-10-01_fun-ideas.md`.

## Notes

- Live at https://petertanksley.github.io; CI `.github/workflows/publish.yml` renders on push to `main`
- GitHub repo renamed to `petertanksley/petertanksley.github.io` (old `PROJ_tanksley_website` URL redirects); local
  remote updated; local folder keeps the `PROJ_tanksley_website` name by Peter's choice
- CV source `2_cv/tanksley_cv.qmd`, CSS `2_cv/tanksley_cv.css`; publication block `2_cv/_publications.qmd` is
  generated from `5_skilltree/data/articles.yml` by `render_cv_pubs.R`, never hand-edited (`add_article.R <DOI>`)
- Two-page CV (grant/biosketch use): `2_cv/tanksley_cv_2page.qmd` + `_cv2_header.typ`; hand-render with
  `quarto render 2_cv/tanksley_cv_2page.qmd --to typst` (PDF beside the source, gitignored). Excluded from the site
  render in `_quarto.yml` on purpose (Helvetica Neue, local font). 11 selected pubs and the count line are hand-maintained.
- Skill tree, stats card, impact pips, achievements: generator in `5_skilltree/`; PROJ_skill_tree repo archived
- Displayed citations are Google Scholar only; OpenAlex feeds achievements only (see `logs/skilltree/2026-10-04_refresh-lineage-wording.md`)
- Hex stickers: finals in `www/hex/` + `www/hearth.jpg`; pipeline `4_stickers/`; CV band via `4_stickers/hexband.R`
- Phase marks: coin (first responders), handcuffs (criminology); helmet and magnifying glass archived beside them
- News feed: `news.yml` → `news-listing.ejs` / `news-listing-home.ejs`; achievements are a separate stream
- Landing masthead = 4-sticker hex collage; real headshot lives on About only
- Conventions (voice, content rules, feed, stickers, JCR/pips, CI and pagedjs gotchas): `CLAUDE.md`
- History: `logs/` and `logs/skilltree/`; prune records `logs/2026-09-02_bob-prune.md`, `logs/2026-09-22_bob-prune.md`
