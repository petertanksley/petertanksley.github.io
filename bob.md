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
last_updated: 2026-09-22
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

- Nothing in flight. Last content push `975d795` (achievements) is live; working tree clean as of 2026-09-22.
- If a few weeks have passed: `Rscript 5_skilltree/R/refresh.R`, then commit the snapshot, `www/scholar.json`,
  `5_skilltree/data/achievements_log.yml` and `www/tree.json`.
- Check Crossref for entry 27 (Nature) volume/pages and entry 28 (AJPH) DOI before touching `articles.yml`.
- Publications change in `5_skilltree/data/articles.yml`, never in the CV: edit → rate in the Shiny app if new →
  `build_tree.R` + `render_cv_pubs.R` → commit. A new venue also needs its JCR year in `5_skilltree/data/jcr/`
  and `build_journals.R` rerun.
- Backlog is listed under Upcoming Milestones; none of it is scheduled.

## This Week
- DONE 2026-09-22: trapdoor scene (Holes homage, three rolls, $0.61) at the foot of the landing page; see `logs/2026-09-22_trapdoor-scene.md`. Uncommitted.

- [ ] Periodic stats refresh (`Rscript 5_skilltree/R/refresh.R` → commit snapshot, `www/scholar.json`,
  `5_skilltree/data/achievements_log.yml`, `www/tree.json`) — only if not run in the last few weeks
- Otherwise monitoring only; nothing scheduled

## Upcoming Milestones

- TBD: volume/issue/pages for entry 27 (Schwaba et al., Nature, doi:10.1038/s41586-026-10992-9) — set
  `citation:` in `articles.yml` (currently "online first"), rerun `render_cv_pubs.R`. Still online first at
  last check (2026-09-19).
- TBD: DOI, then volume/pages, for entry 28 (Tanksley, Logan, & Barnes, AJPH, in press) — set `doi:`,
  `status: published`, `citation:` in `articles.yml`; the homepage and research-page `.worklist` blocks are
  hand-written and need the same edit. No DOI at last check (2026-09-19).
- June/July 2027: new JCR year — export all 22 journals into `5_skilltree/data/jcr/jcr_<year>.csv`, run
  `build_journals.R` then `build_tree.R`, commit. Clears nearest-year flags on papers published earlier that year.
- Backlog, unscheduled: career-rank gold markers on the year rings ("Future work" in
  `logs/skilltree/2026-09-18_article-stickers.md`); phase stickers beside the matching Research-page sections;
  achievements extras (total-citation ladder, h/i10 ladders, manual talks/grants/awards, box-reward variants —
  proposals in `logs/skilltree/2026-09-19_achievements-rules.md`).

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
