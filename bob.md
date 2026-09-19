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
last_updated: 2026-09-19
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

- Nothing urgent. Skill tree (Research ▸ Skill tree) and the YAML-generated CV publication list are
  live as of 2026-09-09; add news items to `news.yml` as they happen.
- Publications now change in `5_skilltree/data/articles.yml`, never in the CV directly: edit → rate
  in the Shiny app if new → `Rscript 5_skilltree/R/build_tree.R` + `render_cv_pubs.R` → commit. A paper in a
  new venue also needs its JCR year exported into `5_skilltree/data/jcr/` and `build_journals.R` rerun.
- Check Crossref for volume/pages on the Nature paper (entry 27) before touching the YAML.

## This Week

- DONE 2026-09-18: per-article sticker pipeline built; all 30 articles stickered twice (v1 uniform,
  v2 with tailored per-article motifs + per-article seeds, responders re-rolled with placement
  guardrails); selected hexes 3.4x with reverse flip, gold origin ring — see
  `logs/skilltree/2026-09-18_article-stickers.md`. Committed and pushed as `d0a5596`; CI publishes.
- DONE 2026-09-19: fresh phase stickers for first responders (coin) and criminology (handcuffs), $1.42 over four rolls;
  Research page, homepage collage and CV band updated; helmet and magnifying glass archived beside them.
  See `logs/2026-09-19_phase-stickers.md`.
- DONE 2026-09-18 (evening): Google Scholar stats card on the tree (`fetch_scholar.R`, local, commit the
  JSON) + achievements data layer (`achievements.yml`, `check_achievements.R`, dry-run only) — see
  `logs/skilltree/2026-09-18_scholar-stats.md`. Committed as `dcb8cd1`.
- DONE 2026-09-19: impact-factor pips on the skill tree (bands 5/10/25 on the JCR year before publication;
  data from Peter's JCR exports in `5_skilltree/data/jcr/`) — see `logs/skilltree/2026-09-19_impact-factor-pips.md`.
  Checked in the browser by Peter; committed and pushed as `06c971c`, CI publishes.
- [ ] Peter writes the reward lines in `5_skilltree/data/achievements.yml` (three PLACEHOLDERs); then
  wire `check_achievements.R --post` to append DCC-voice entries to `news.yml`.
- [ ] Refresh the stats now and then: `Rscript 5_skilltree/R/fetch_scholar.R` → commit.
- [ ] Each June/July when Clarivate releases the new JCR year: export all 22 journals for that year from JCR
  into `5_skilltree/data/jcr/jcr_<year>.csv`, run `build_journals.R` then `build_tree.R`, commit. Clears the
  nearest-year flags on papers published earlier that year. New venue: same, one journal, one year.
- [ ] Backlog (not scheduled): career-rank gold markers on the year rings — see "Future work" in
  `logs/skilltree/2026-09-18_article-stickers.md`.
- [ ] Optional: phase stickers beside the matching Research-page sections
- [ ] Optional: a news item announcing the skill tree

## Upcoming Milestones

- TBD: volume/issue/pages for entry 27 (Schwaba et al., Nature, doi:10.1038/s41586-026-10992-9)
  when assigned — set `citation:` in `articles.yml` (currently "online first"), rerun `render_cv_pubs.R`;
  none as of 2026-09-19 (still online first)
- TBD: DOI (then volume/pages) for entry 28 (Tanksley, Logan, & Barnes, AJPH, in press) — set `doi:`,
  `status: published`, `citation:` in `articles.yml`; the homepage and research-page `.worklist`
  blocks are still hand-written and need the same edit; still in production, no DOI as of 2026-09-19

## Notes

- Live at https://petertanksley.github.io
- CI: `.github/workflows/publish.yml` — uses the runner's preinstalled Chrome
  (PUPPETEER_SKIP_DOWNLOAD / PUPPETEER_EXECUTABLE_PATH), install retries kept, 20-min job
  cap, superseded runs auto-cancelled
- CV source: `2_cv/tanksley_cv.qmd`; CSS: `2_cv/tanksley_cv.css`
- Hex stickers: finals in `www/hex/` (7 art + blank) + anchor `www/hearth.jpg`; pipeline in
  `4_stickers/`; style guide and prompt lessons in `logs/2026-09-01_sticker-generation.md`;
  round-2 picks and the "one clean subject" rule in `logs/2026-09-05_round2-stickers-and-news-feed.md`
- News feed: `news.yml` (add entries here; headline = what the thing is, blurb = one irreverent
  sentence with markdown links) → `news-listing.ejs` (news page, links) + `news-listing-home.ejs`
  (homepage, links stripped, headline → `news.html#id`); homepage shows latest 3; navbar entry between Projects and Left-hand Thoughts. Quarto's EJS rejects `<%# %>` comments.
- Landing page masthead = 4-sticker hex collage (`.hexcollage`); real headshot lives on About only
- CV hex band: `4_stickers/hexband.R` → `_hexband.qmd` (included by the CV). New stickers:
  append to `stickers` in the script and rerun. Design notes in
  `logs/2026-09-02_hex-band-and-cv-fixes.md`
- CV publication block is generated (`2_cv/_publications.qmd`, never hand-edited); the fenced-div
  rule it follows is documented in CLAUDE.md
- Conventions (voice, content rules, feed, stickers, gotchas): `CLAUDE.md` (added 2026-09-05)
- History: `logs/` (prune record: `logs/2026-09-02_bob-prune.md`)
- Skill tree integrated 2026-09-09 (Research ▸ Skill tree; generator in `5_skilltree/`, PROJ_skill_tree repo archived) — see logs/skilltree/
- CV publications generated from `5_skilltree/data/articles.yml` since 2026-09-09 (`render_cv_pubs.R` → `2_cv/_publications.qmd`); add papers with `add_article.R <DOI>` — see logs/skilltree/2026-09-09_cv-from-yaml.md
- CV PDF: screen-only elements must be hidden with a `.pagedjs_page`-scoped rule in `tanksley_cv.css` (hex band fix 2026-09-09); `quarto render 2_cv/tanksley_cv.qmd --to pdf` to rebuild the PDF locally
