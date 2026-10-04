---
project: Tanksley Personal Website & CV
type: web
status: active
priority: medium
path: /Users/PTT2/Documents/GitHub/PROJ_tanksley_website
deadline: null
target: Personal academic website with CV, about page, and blog
effort_remaining: monitoring (annual JCR refresh each June/July; news/pubs as they happen)
weekly_commitment: 1h
last_updated: 2026-10-04
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

- State 2026-10-04: refresh done (Scholar 456, h 13, i10 15; 7 ledger entries); per-article Scholar citations,
  stats-card year bars and citation-driven hex brightness all live (log `logs/skilltree/2026-10-04_refresh-lineage-wording.md`).
- Open for Peter: (1) drop OpenAlex entirely, or keep it feeding Necromancy + percentile achievements only?
  (2) review the unfired achievement templates (page: https://claude.ai/artifact/83gcPoCxpgN6HuPdvQmLra).
- Next refresh a few weeks after 10-04: `Rscript 5_skilltree/R/refresh.R`, then commit the snapshot,
  `www/scholar.json`, `5_skilltree/data/achievements_log.yml`, `www/tree.json`.
- Publications change in `5_skilltree/data/articles.yml`, never in the CV: edit → rate in the Shiny app if new →
  `build_tree.R` + `render_cv_pubs.R` → commit. New venue: add its JCR year in `5_skilltree/data/jcr/`, rerun `build_journals.R`.

## This Week
- [ ] Nothing due; refresh not before late October
- [ ] Optional: one line on the Projects page saying why anatomogramdata exists

## Upcoming Milestones

- TBD: volume/issue/pages for entry 27 (Schwaba et al., Nature, doi:10.1038/s41586-026-10992-9) — set
  `citation:` in `articles.yml` (currently "online first"), rerun `render_cv_pubs.R`. Online first at last check (2026-10-03).
- TBD: DOI, then volume/pages, for entry 28 (Tanksley, Logan, & Barnes, AJPH, in press) — set `doi:`,
  `status: published`, `citation:` in `articles.yml`; the homepage and research-page `.worklist` blocks are
  hand-written and need the same edit. No DOI at last check (2026-10-03).
- June/July 2027: new JCR year — export all 22 journals into `5_skilltree/data/jcr/jcr_<year>.csv`, run
  `build_journals.R` then `build_tree.R`, commit. Clears nearest-year flags on papers published earlier that year.
- Backlog, unscheduled: achievement-template review (above); phase stickers beside the matching Research-page
  sections; achievements extras (total-citation ladder, box-reward variants, reviews from the `/bob review`
  archive; proposals in `logs/skilltree/2026-09-19_achievements-rules.md`); hex brightness ceiling 1.3 → 1.4 if
  the top papers look flat; optional wide scene on the Projects page (`logs/2026-09-22_trapdoor-scene.md`);
  fun-feature list (404 dungeon floor first) in `logs/2026-10-01_fun-ideas.md`.

## Notes

- Live at https://petertanksley.github.io; CI `.github/workflows/publish.yml` renders on push to `main`
- CV source `2_cv/tanksley_cv.qmd`, CSS `2_cv/tanksley_cv.css`; publication block `2_cv/_publications.qmd` is
  generated from `5_skilltree/data/articles.yml` by `render_cv_pubs.R`, never hand-edited (`add_article.R <DOI>`)
- Skill tree, stats card, impact pips, achievements: generator in `5_skilltree/`; PROJ_skill_tree repo archived
- Displayed citations are Google Scholar only; OpenAlex feeds achievements only (see `logs/skilltree/2026-10-04_refresh-lineage-wording.md`)
- Hex stickers: finals in `www/hex/` + `www/hearth.jpg`; pipeline `4_stickers/`; CV band via `4_stickers/hexband.R`
- Phase marks: coin (first responders), handcuffs (criminology); helmet and magnifying glass archived beside them
- News feed: `news.yml` → `news-listing.ejs` / `news-listing-home.ejs`; achievements are a separate stream
- Landing masthead = 4-sticker hex collage; real headshot lives on About only
- Conventions (voice, content rules, feed, stickers, JCR/pips, CI and pagedjs gotchas): `CLAUDE.md`
- History: `logs/` and `logs/skilltree/`; prune records `logs/2026-09-02_bob-prune.md`, `logs/2026-09-22_bob-prune.md`
