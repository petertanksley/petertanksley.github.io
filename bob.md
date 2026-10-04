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

- Refresh ran 2026-10-04 (Scholar 456, h 13, i10 15); review Bronze + article Silver fired. Mortality-safe lineage
  wording added and the ledger re-rendered; log `logs/skilltree/2026-10-04_refresh-lineage-wording.md`.
- Per-article citations live 2026-10-04: Google Scholar only (count in tooltip; count + per-year bars in the panel).
  Stats card has Scholar-style citations-per-year bars (10-04).
  OpenAlex stays off display but still feeds Necromancy + percentile achievements; whether to drop it entirely is open.
- Crossref still empty for entry 27 (Nature) volume/pages and entry 28 (AJPH) DOI (checked 2026-10-03).
- If a few weeks have passed since 10-04: `Rscript 5_skilltree/R/refresh.R`, then commit the snapshot,
  `www/scholar.json`, `5_skilltree/data/achievements_log.yml` and `www/tree.json`.
- Publications change in `5_skilltree/data/articles.yml`, never in the CV: edit → rate in the Shiny app if new →
  `build_tree.R` + `render_cv_pubs.R` → commit. A new venue also needs its JCR year in `5_skilltree/data/jcr/`
  and `build_journals.R` rerun.

## This Week
- [ ] Stats refresh check — not due (last run 2026-10-04); run `refresh.R` only once a few weeks have passed
- Otherwise monitoring only; nothing scheduled

## Upcoming Milestones

- TBD: volume/issue/pages for entry 27 (Schwaba et al., Nature, doi:10.1038/s41586-026-10992-9) — set
  `citation:` in `articles.yml` (currently "online first"), rerun `render_cv_pubs.R`. Still online first at
  last check (2026-10-03).
- TBD: DOI, then volume/pages, for entry 28 (Tanksley, Logan, & Barnes, AJPH, in press) — set `doi:`,
  `status: published`, `citation:` in `articles.yml`; the homepage and research-page `.worklist` blocks are
  hand-written and need the same edit. No DOI at last check (2026-10-03).
- June/July 2027: new JCR year — export all 22 journals into `5_skilltree/data/jcr/jcr_<year>.csv`, run
  `build_journals.R` then `build_tree.R`, commit. Clears nearest-year flags on papers published earlier that year.
- Backlog, unscheduled: phase stickers beside the matching Research-page sections;
  achievements extras (total-citation ladder, box-reward variants; h/i10 ladders done 09-27, Necromancy + manual
  events built 10-03; reviews from the `/bob review` archive later — proposals in `logs/skilltree/2026-09-19_achievements-rules.md`); Peter to review the full achievement
  template bank in `achievements.yml` (the 7 live entries were reviewed 10-04; unfired variants still unread); optional wide scene on the Projects page
  (`logs/2026-09-22_trapdoor-scene.md`); fun-feature list (404 dungeon floor first) in
  `logs/2026-10-01_fun-ideas.md`.

## Notes

- Live at https://petertanksley.github.io; CI `.github/workflows/publish.yml` renders on push to `main`
- CV source `2_cv/tanksley_cv.qmd`, CSS `2_cv/tanksley_cv.css`; publication block `2_cv/_publications.qmd` is
  generated from `5_skilltree/data/articles.yml` by `render_cv_pubs.R`, never hand-edited (`add_article.R <DOI>`)
- Skill tree, stats card, impact pips, achievements: generator in `5_skilltree/`; PROJ_skill_tree repo archived
- Hex stickers: finals in `www/hex/` + `www/hearth.jpg`; pipeline `4_stickers/`; CV band via `4_stickers/hexband.R`
- Phase marks: coin (first responders), handcuffs (criminology); helmet and magnifying glass archived beside them
- News feed: `news.yml` → `news-listing.ejs` / `news-listing-home.ejs`; achievements are a separate stream
- Landing masthead = 4-sticker hex collage; real headshot lives on About only
- Conventions (voice, content rules, feed, stickers, JCR/pips, CI and pagedjs gotchas): `CLAUDE.md`
- History: `logs/` and `logs/skilltree/`; prune records `logs/2026-09-02_bob-prune.md`, `logs/2026-09-22_bob-prune.md`
