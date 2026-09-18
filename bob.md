---
project: Tanksley Personal Website & CV
type: web
status: active
priority: medium
path: /Users/PTT2/Documents/GitHub/PROJ_tanksley_website
deadline: null
target: Personal academic website with CV, about page, and blog
effort_remaining: ~0.5h (review + commit the sticker batch; otherwise monitoring)
weekly_commitment: 1h
last_updated: 2026-09-18
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
  in the Shiny app if new → `Rscript 5_skilltree/R/build_tree.R` + `render_cv_pubs.R` → commit.
- Check Crossref for volume/pages on the Nature paper (entry 27) before touching the YAML.

## This Week

- DONE 2026-09-18: per-article sticker pipeline built; all 30 articles stickered twice (v1 uniform,
  v2 with tailored per-article motifs + per-article seeds, responders re-rolled with placement
  guardrails); selected hexes 3.4x with reverse flip, gold origin ring — see
  `logs/skilltree/2026-09-18_article-stickers.md`. Committed and pushed as `d0a5596`; CI publishes.
- [ ] Decide whether the responders phase sticker (`www/hex/responders.png`, fire helmet) on the
  Research page and CV band should become the coin too (~$0.20).
- [ ] Optional: phase stickers beside the matching Research-page sections
- [ ] Optional: a news item announcing the skill tree

## Upcoming Milestones

- TBD: volume/issue/pages for entry 27 (Schwaba et al., Nature, doi:10.1038/s41586-026-10992-9)
  when assigned — set `citation:` in `articles.yml` (currently "online first"), rerun `render_cv_pubs.R`;
  none as of 2026-09-09
- TBD: DOI (then volume/pages) for entry 28 (Tanksley, Logan, & Barnes, AJPH, in press) — set `doi:`,
  `status: published`, `citation:` in `articles.yml`; the homepage and research-page `.worklist`
  blocks are still hand-written and need the same edit

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
