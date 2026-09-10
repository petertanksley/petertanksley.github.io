# petertanksley.github.io — conventions for anyone working in this repo

Status and scheduling live in `bob.md`; history in `logs/`. This file is how to work here.

## Voice (Peter, 2026-09-05)

The prose on this site is **eccentric and irreverent**, and that is deliberate. It is
Peter's personal site, not an institutional one. When writing or rewriting anything
user-facing (homepage, news, about, project blurbs, post intros):

- Say what the thing *is*, in plain words and in Peter's voice. Do not parrot the formal
  name of the article, journal, newsletter, or grant as the headline.
- Lighthearted, not jokey. Dry beats zany. A wink, not a laugh track.
- One idea per sentence; no information dumps. A news blurb is **one sentence**.
- Do not harp on credentials or numbers (author counts, impact factors, dollar figures)
  unless the number *is* the joke. Peter would rather understate.
- Confident, not hedged. No "interestingly", "it is worth noting", "I am honored to".
- **No sass about first responders dying.** Saying that Peter studies mortality is fine; jokes,
  glibness, or vivid flourishes about the deaths themselves are not. State it plainly and
  save the irreverence for the surrounding material (methods, career, R, himself).
- Worked examples, both approved:
  - Headline: "Career achievement unlocked: get published in Nature. Check."
    Blurb: "I was part of a project on the genetics of personality that took years to
    come together, and boy, did it finally land."
  - Headline: "Wrote a thing for police chiefs about which mortality numbers actually matter."
    Blurb: "Over on Tactical Science, an essay on the death statistics a chief can do
    something with, and why the answer changes at 45."

Exception: the CV (`2_cv/`) is formal and stays formal. Publication titles there and in the
`.worklist` blocks on the research/home pages are quoted exactly.

## Content rules

- High-level only. Project detail belongs on alerrt-research.org; this site points there.
- The ALERRT research unit is the **Research Ring** (never "wing").
- Do not feature the McAllister/Gonzalez firefighter biomarker papers.
- Harden Lab link is https://www.kpharden.com/.
- Real headshot appears on the About page only; the landing page uses the sticker collage.

## News feed

- Source of truth: `news.yml`. Fields: `date`, `id`, `title` (the headline), `description`
  (the one-sentence blurb; markdown links allowed and encouraged).
- Rendering: `news-listing-home.ejs` on the homepage (latest 3; links stripped; headline ->
  `news.html#<id>`) and `news-listing.ejs` on `news.qmd` (everything; links live; anchors).
  Mirrors the Research Ring site's `_media_entries.yaml` / `_render_media.R` pattern.
- Always give an entry an `id`, or the homepage headline can only link to the top of the page.
- Quarto's EJS: no `<%# %>` comments (bare SyntaxError), and the escaping convention is
  reversed from standard EJS (`<%= %>` is raw, `<%- %>` escapes).

## Hex stickers

- Style: 16-bit pixel art, sepia-warm, Dresden-universe homage with Peter's likeness and dogs,
  anachronisms welcome. **Hexagons, never hexagrams or pentagrams.** Skull stays nameless.
- **One clean symbolic subject per hex.** Stickers are read at 92px on the CV band; anything
  that needs magnifying to parse gets cut. Judge candidates *after* hex-clipping.
- Pipeline: `4_stickers/bananarama.yaml` (prompts; append, existing outputs are skipped) ->
  `frame_hex.R` (clip to 480x554 point-up hex) -> `www/hex/`. Band: `hexband.R` ->
  `_hexband.qmd` (append new names to `stickers`, rerun). Refs in `4_stickers/refs/` are
  gitignored personal photos. Full lessons: `logs/2026-09-01_sticker-generation.md`.

## Skill tree (`skilltree.qmd`, `5_skilltree/`)

- **R thinks, JS draws.** Data, validation and geometry live in `5_skilltree/R/`; `www/skilltree.js`
  only puts SVG on the page from `www/tree.json`. `5_skilltree/data/articles.yml` is the source of
  truth; `extract_cv.R` refreshes its bibliographic fields from the CV and never touches the
  judgement fields (areas, role, contribution, effort, blurb, builds_on, featured, sticker). Peter
  edits those in the Shiny app (`5_skilltree/tools/rate_articles/`), which auto-saves.
- `www/tree.json` and `www/hex/sm/` are committed build outputs: rerun `build_tree.R` after any
  YAML edit and commit the result. They are declared under `resources` in `_quarto.yml` because
  Quarto cannot see assets referenced only from JS/JSON.
- Layout: hexagonal year rings (2019 on ring 2, ring 1 empty, Peter's `puzzled` sticker at the
  origin) with three area axes, biosocial 240° / criminology 120° / first responders 0°; direction
  is the vector sum of the 0–3 area ratings; each article takes the free cell on its ring nearest
  its angle, purest first. Lineage: neighbours get a weld across the shared border above the tiles,
  longer links a curve beneath.
- Interaction: **hover highlights, click flips.** Nothing geometric changes on hover (a hover
  transform thrashes enter/leave at the hex edges). Click flips once and opens the detail panel;
  `#id` deep links. Never rotate a sticker. The resting dim is a filled `hex-shade` path, never a
  CSS `filter` on an SVG `<image>` (GPU Chrome and Safari drop the image). Verify interaction in a
  real browser, not only headless.
- Muted tier (`featured: false`) is visual only. Nothing on the page explains why a node is muted;
  legend wording is "contributing author". Blurbs for muted papers get the same care as any other.
- Stickers per article go through the `4_stickers/` pipeline unchanged; until one exists a node
  shows `blank_dark.png`, which `build_tree.R` cuts from `blank.png`'s alpha.
- Styles are the `.skilltree*` block at the end of `theme.scss`: a self-contained dark panel with
  `--st-*` tokens. Area colours come from `AREA_COL` in `build_tree.R` via `tree.json`; do not
  hardcode them in the qmd or SCSS.
- **The page is dark end to end** (2026-09-10): navbar, title, tree and footer all sit on `$ink`, the
  title block is centred over the figure, and the tree has no card edge. Mechanism: the page's
  `include-in-header` adds `page-dark` to `<html>` before first paint (no paper flash) and the
  `html.page-dark` block in `theme.scss` restyles the chrome. Reusable: any page can opt in the same
  way. Keep the name "Skill tree"; Peter decided the same day not to rename it to something literal.
- **Foreshadowing:** the Research page ends on a dark `.tree-card` (raw HTML in `research.qmd`,
  styles in `theme.scss`) so the visitor has seen the ink palette before the page flips. It is the
  only in-site link to the tree besides the navbar; keep it if the Research page is restructured.
- **Easter egg (2026-09-10):** clicking Peter's hex at the origin (or visiting `#me`) flips it and
  opens a joke RPG character sheet in the detail panel: Level 2 Research Scientist, Class: None,
  Race: Homeschooled, etc. The lines live in the `SHEET` object at the top of the panel section of
  `www/skilltree.js`, not in the YAML; edit them there. Keep it deadpan and in Peter's voice; do not
  advertise it in the legend.
- **Panel behaviour (2026-09-10):** a pinned hex grows to `--lit` (1.8) and is lifted into the SVG's
  top layer so welds and labels pass under it; `fitAroundPanel()` pads the wrap so the tree rescales
  clear of the drawer (1 s ease); the panel's Lineage section lists builds-on / built-on-by rows that
  open the connected article in place. Roles are lead and contributing only; co-lead was removed.
- **The CV's publication list is generated** (2026-09-09): `2_cv/_publications.qmd` is written by
  `5_skilltree/R/render_cv_pubs.R` from the same YAML and included by the CV. Never edit the
  publication block in `tanksley_cv.qmd` or the include by hand. Strings print verbatim from the
  YAML (`authors_cv` is the exact author line the CV shows), so fix wording in the YAML.
- **Adding a paper:** `Rscript 5_skilltree/R/add_article.R <DOI>` (CrossRef → new YAML entry; expect
  to fix Title Case and add Peter's middle initial), rate it in the Shiny app, then
  `build_tree.R` and `render_cv_pubs.R`, then commit YAML + `tree.json` + `_publications.qmd`. The
  home/research `.worklist` blocks are still hand-written.
- Preprints carry no blurb (Peter, 2026-09-09): the panel shows none, the app does not require one.

## Build gotchas

- **Cache-busted script src hides the file from Quarto.** `skilltree.qmd` loads
  `www/skilltree.js?v=...` so browsers refetch after an edit. The query string stops Quarto's
  resource discovery from matching the file, so `docs/www/skilltree.js` silently stops updating.
  `www/skilltree.js` is therefore listed under `project.resources` in `_quarto.yml`; keep it there.
  Bump the `?v=` value whenever the JS changes (2026-09-10).

- CV publication entries must be fenced divs (`::: {.pub-item}`), never raw single-line
  `<div>`; pandoc leaves those open and truncates the TOC. (Generated now; the generator emits them.)
- Raw HTML blocks go in ```` ```{=html} ```` fences or Quarto wraps each line in `<p>`.
- `row` as a class name collides with Bootstrap's grid.
- Headless Chrome screenshots at narrow widths overflow body text on every page; viewport
  quirk, not a layout bug.
- CI (`.github/workflows/publish.yml`) renders on push to `main`, including the pagedjs CV
  PDF, using the runner's preinstalled Chrome. Locally, `quarto render 2_cv/tanksley_cv.qmd` builds
  only the HTML; add `--to pdf` to rebuild the PDF.
- The pagedjs PDF is a standalone HTML render **without the site theme**, and Quarto's
  `when-format="html"` conditional is TRUE for it (pandoc's target is html). Anything screen-only in
  the CV must be hidden with a rule scoped to `.pagedjs_page` in `tanksley_cv.css`, as the hex band
  now is (it printed as seven broken-image alt texts on the PDF's last page from 2026-09-02 to 09-09).
- A `position: fixed` overlay written inside page content can never rise above the fixed-top navbar
  (z 1030): Quarto's content column is its own stacking context (`z-index: 998; opacity: .999`), so
  z-index inside it is capped. Portal the element to `<body>` from JS instead (the skill tree does
  this for its panel and tooltip).
