# 2026-10-06 — Two-page CV, clone fast-forward, repo rename, CV gap audit

**Two-page CV.** Built a grant-oriented two-page CV for a Texas State research accelerator application (Peter
is research support staff on the proposal). Source `2_cv/tanksley_cv_2page.qmd` + `2_cv/_cv2_header.typ`.
Rendered by hand with `quarto render 2_cv/tanksley_cv_2page.qmd --to typst`; the PDF lands beside the source
and is gitignored. Font is Helvetica Neue (local), so the file is deliberately excluded from the website render
list in `_quarto.yml`. A copy was saved to `~/Desktop/Tanksley_CV_2page.pdf`. Selected publications are
hand-picked (11 items) and must be updated by hand when `articles.yml` changes; the count line currently reads
"28 peer-reviewed articles (one in press) and 2 preprints".

**Publication count verified.** 28 articles (one in press at AJPH) and 2 preprints, checked against ORCID,
OpenAlex and Crossref. Matches `articles.yml` / `_publications.qmd` on the remote.

**Clone sync.** The local clone had been 81 commits behind GitHub since June. Fast-forwarded today; a stale
2-line uncommitted bob.md edit was discarded as superseded. Commit `184aeca` (two-page CV sources, `_quarto.yml`
exclusion, bob.md note) was pushed. CI "Render and Publish" and the Pages deployment both succeeded. Live site
confirmed to not serve the two-page CV (404) while the full CV serves (200).

**Repo rename.** GitHub repo is now `petertanksley/petertanksley.github.io`; the old `PROJ_tanksley_website`
URL redirects. Local git remote URL updated to the new name. Local folder name intentionally left as
`PROJ_tanksley_website` (Peter declined renaming). bob.md `repo:` already carried the new name.

**CV gap audit (June snapshot vs. remote).** The June-era CV in the stale clone was missing the AJPH
correctional officer paper (in press), Schwaba et al. Nature 2026 (online first), McAllister et al. JOEM 2026
"Inflammation on the Frontlines", and the NIDA R01 funding entry (PI; Co-PI Seth Watts; $505,783; under
review). All are present on the remote; nothing to add to `articles.yml`.

**ICPSR 2024 training entries, resolved.** The entries (Experiments in Social Science Research; Interactive
Visualization/Shiny) were in the June CV and dropped out in commit 1b7c6ce (2026-06-19, a formatting-only commit
that rewrapped the Advanced Training block). Peter confirmed 2026-10-06 that he does not want ICPSR listed, so the
omission stands in both the full CV and the two-page CV. Do not restore it.

**bob.md.** `target:` frontmatter held a prose description rather than a date; nulled (Objectives already
carries the statement). Two-page CV Notes line trimmed to standing facts; repo-rename line added; Start Here
rewritten.
