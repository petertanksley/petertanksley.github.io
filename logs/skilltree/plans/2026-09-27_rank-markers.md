**Status:** APPROVED 2026-09-27 (Peter). Plan file: ~/.claude/plans/vivid-sprouting-flamingo.md

# Career rank markers on the skill tree ("class change" evolutions)

## Context

The origin hex lost its achievements numeral today (every achievement is Peter's, so a count there marks
nothing). What the tree still lacks is a marker of **career progression**, sketched in the 2026-09-18
"Future work" note. Peter's decisions today:

- Three markers on the year rings: **2019** (starting class, Doctoral Student), **2020** (→ Postdoc),
  **2024** (→ Research Scientist).
- Click opens an **evolution screen** in the side panel: previous class sticker → arrow → new class
  sticker (Pokémon evolution / Fire Emblem promotion). 2019 shows the single starting class.
- Art: **Peter's pixel-art likeness geared up per class**, same character as the origin sticker
  `www/hex/puzzled.png`, via the existing `4_stickers/` Gemini (bananarama) pipeline.
- Copy: **system-message deadpan**, class names only, **no level numbers**. The character sheet's
  hand-written "Research Scientist · Level 2" line stays as is.
- Peter will **raise the Gemini spend cap** before the art step (logs put spend at ≈ $19 of $20).

Dates from the CV (years only): PhD 2020 (UC), postdoc 2020–2024 (Population Research Center, UT
Austin, Harden Lab), Research Scientist 2024– (ALERRT Center, Texas State). Rings resolve to years.

Data key is **`ranks`**, never `career`: "career-level" already means achievements with no article
(`CAREER <- "__career__"` in `build_tree.R`, `ORIGIN_ACH` in the JS).

Verified geometry (from `www/tree.json`): origin (1302.4, 1142.4), canvas 2781 × 2285, `DX` 104,
`DY` 90.07, `W` 100, `H` 115.47. Labels: 2019 ring 2 at (1302.4, 962.3); 2020 ring 3 at (1250.4, 872.2);
2024 ring 7 at (1250.4, 511.9). The right-hand top-edge neighbour of each is free today (ring 7's only
top-edge hex, `willems_2024_self`, is at x 938). The 09-18 worry about the 2026 label near the canvas
top does not apply: these markers sit at y 512–962. On-screen scale ≈ 0.43 px/unit desktop, 0.26 on a
phone (SVG `min-width: 720px`).

## Design

### 1. Data: `5_skilltree/data/ranks.yml` (new, hand-written, ordered)

Order defines the chain: entry *i* evolves from entry *i − 1*, so no from/to fields are stored.

```yaml
# ranks.yml — Peter's class at each rank change, drawn as gold markers on the skill tree's year rings.
# ORDER MATTERS: each entry evolves from the one above. `year` = the ring the marker sits on; the first
# entry is the starting class. Read by build_tree.R -> tree.json meta.ranks. Art: 4_stickers/ranks.yaml.
- id: student
  title: Doctoral Student
  org: School of Criminal Justice, University of Cincinnati
  years: "to 2020"                 # the degree began before the tree does
  year: 2019
  sticker: rank_student            # www/hex/rank_student.png, 480x554
  headline: "Starting class: Doctoral Student."
  line: "Cincinnati. Real winter. The dissertation is the tutorial level, and nobody gets to skip it."
- id: postdoc
  title: Postdoc
  org: Population Research Center, University of Texas at Austin
  years: "2020–2024"
  year: 2020
  sticker: rank_postdoc
  headline: "Class change: Postdoc."
  line: "Home to Austin for genomics in the Harden Lab. Learned to say methylation without pausing. The Constitution stat on the character sheet was earned here."
- id: scientist
  title: Research Scientist
  org: ALERRT Center, Texas State University
  years: "2024–present"
  year: 2024
  sticker: rank_scientist
  headline: "Class change: Research Scientist."
  line: "One exit south on I-35. New subject: the people who run toward the trouble. A colleague bought him a monogrammed lab coat as a joke. He wears it."
```

Copy is a draft for Peter to edit in the YAML (voice per CLAUDE.md: dry, one idea per sentence, no
credential harping; career is fair game). R validates: unique ids, years strictly ascending and within
`FIRST_YEAR..year_of(n_ring)`, `sticker` present; warns if the first year ≠ `FIRST_YEAR`.

### 2. R: `5_skilltree/R/build_tree.R` (R thinks, JS draws)

- **Constants** (after L52): `RANK_W <- 0.38 * W` (38 units, a bead on the ring, not a tile),
  `RANK_GAP <- 8`, `YEAR_LABEL_HALF_W <- 35` (4 digits at 26 px mono + 8 px halo, halved),
  `RANK_CLEAR <- W/2 + RANK_W/2 + 4` (73: same-row centre distance below which a marker touches a hex).
- **Read + validate** `ranks.yml` after the articles block (~L86). Missing file → message, `ranks <- list()`;
  the tree must still build.
- **`rank_pos(k)`** after `year_label_pos` (L158): candidates `label_x ± (35 + 8 + 19) = label_x ± 62`
  at `y = label_y`. A flank is clear when no placed node on the same row (`|node.y − label_y| < 1`) has
  `|node.x − cand| < RANK_CLEAR`. Order: right, then left, else above (`label_y − 0.55·H`) with a loud
  `warning()` and `side = "above"`. Only the same row can collide (rows ±90 away reach 32 units toward the
  label row; the marker reaches 22). Today all three resolve **right**: 2019 → (1364.4, 962.3),
  2020 → (1312.4, 872.2), 2024 → (1312.4, 511.9). The ring guide passes through the marker centre, so it
  reads as a bead on the ring.
- **Stickers** (L163–171): `rank_stickers <- map_chr(ranks, "sticker")`; loop over
  `unique(c(sticker_name, ORIGIN_STICKER, rank_stickers))` so `www/hex/sm/rank_*.png` (220 px) exist;
  after the `blank_dark` block, `rank_src <- ifelse(file.exists(sm), rank_stickers, "blank_dark")` so
  the markers ship before the art does.
- **`meta$ranks`** (in `tree$meta`, L260–281): per entry
  `{key: "rank-<year>", id, year, ring, title, org, years, headline, line, x, y, w, h, side,
  sticker_src, from: {id, title, sticker_src} | null}`.
- **Console summary** (after L300): `ranks: 3 markers  2019=right (1364.4,962.3) …; art: …` and
  `missing art -> blank_dark: …` when applicable.

### 3. JS: `www/skilltree.js`

Model on the origin node (own group, own tooltip, lift to `gTop`, custom panel), not on article nodes.

- **State** (by `originG`, L103–106): `let rankPinned = null, rankHome = null; const rankToggles = {};`
- **`unpin()`** (L113–141): third block, copy of the origin block, on `rankPinned`/`rankHome` (return to
  home on `animationend`/700 ms unless re-pinned). Note the three near-identical blocks as debt in the log.
- **Layer**: between `svg.appendChild(gBridge)` (L508) and `gL` (L511): `const gR = svgEl('g', {class:'ranks'}, svg); rankHome = gR;`
  Markers sit above tiles and welds, below labels (they never overlap a label).
- **Per marker** `rk` in `m.ranks || []`: `g.rank-node[tabindex=0][role=button][data-id=rk.key]
  [aria-label="<year>. <headline> From <from.title>. Opens the class-change screen."]` containing, in
  order: `<image>` of `sticker_src` at `(x − w/2, y − h/2, w, h)`; `path.hex-shade` (`hexPath` × 0.99);
  `path.rank-ring` (× 0.96); `circle.rank-hit` `r = 0.42·hex_w` (42 units = 18 px desktop, 11 px phone,
  `fill: transparent`) as the tap target. It overlaps the year text (no handlers) and never a placed hex.
- **Tooltip** (reuse `tip`, `placeTipAt`, `placeTipByNode`): `tt-title` = headline, `tt-meta` =
  `"<year> · <from.title> → <title> · click to inspect"`, `--node` gold `#D9A441`.
- **Toggle** (mirror `toggleOrigin` L400–409): if `rankPinned === g` → `unpin()`; else `unpin(); rankPinned = g;
  g.classList.remove('unflipping'); gTop.appendChild(g); g.classList.add('pinned','flipping','lit'); tip.hidden = true; openRank(rk, g);`
  Register in `rankToggles[rk.key]`; bind click and Enter/Space.
- **Panel** `openRank(rk, g)` + `rankHTML(rk)` (by `openSheet`, L263–271); sets `--node` gold,
  `fitAroundPanel(true)`, `lastFocus = g`, `replaceState('#' + rk.key)`:
  ```
  <div class="sp-eyebrow">System message · 2020</div>
  <h2 class="sp-title">Class change: Postdoc.</h2>
  <div class="sp-meta">Postdoc · Population Research Center, University of Texas at Austin · 2020–2024</div>
  <div class="sp-evo[ single]">
    <figure class="sp-evo-hex from"><img src=from.sticker_src alt=from.title><figcaption>Doctoral Student</figcaption></figure>
    <span class="sp-evo-arrow" aria-hidden="true">→</span>
    <figure class="sp-evo-hex to"><img src=sticker_src alt=title><figcaption>Postdoc</figcaption></figure>
  </div>
  <p class="sp-blurb">…line…</p>
  <a class="sp-link" href="#me">Character sheet →</a>
  ```
  Plain `<img>` of the 220 px `sm` art at ~128 px (the 480 px finals are not copied into `docs/`). The
  `#me` link works for free through `hashchange` → `openFromHash` → `toggleOrigin` → `unpin()`.
- **Wiring**: add `.rank-node` to the document-click allowlist (L542); `openFromHash` (L546–559) gets
  `if (rankToggles[want]) { …toggle unless already pinned…; scrollIntoView; return; }` before the node lookup.
- **Legend** (L531–538): when `m.ranks.length`, before "Builds on":
  `item('<svg class="lg-hex lg-rank" viewBox="0 0 20 23"><path d="'+hexPath(10,11.5,11,12.7)+'" fill="none" stroke-width="2.5" stroke-linejoin="round"/></svg>', 'Class change')`
  (gold via CSS; `var()` is invalid in presentation attributes).
- **Cache-buster**: `skilltree.qmd` `?v=2026-09-20b` → `?v=2026-09-27a`.

### 4. SCSS: `theme.scss`

Inside `.skilltree` next to `.origin-node` (L544–553):
```scss
// career-rank markers (2026-09-27): 38-unit bead beside the year label where Peter's class changed
// (meta.ranks; geometry from build_tree.R). Same idiom as .node: art hinted under a shade, revealed by the
// flip. 3.4*100/38 lands the lit marker at the same on-screen size as a lit article or origin.
.rank-node {
  --lit: calc(3.4 * 100 / 38); --shade: 0.8;
  cursor: pointer; outline: none; transform-box: fill-box; transform-origin: center; transition: transform 420ms ease;
  .rank-hit  { fill: transparent; }
  .hex-shade { fill: var(--st-bg); opacity: var(--shade); pointer-events: none; transition: opacity 420ms; }
  .rank-ring { fill: none; stroke: var(--st-gold); stroke-width: 4; opacity: 0.9; stroke-linejoin: round; transition: stroke-width 160ms, opacity 160ms; }
  &:hover, &:focus-visible { .rank-ring { stroke-width: 7; opacity: 1; } .hex-shade { opacity: 0.45; } }
  // strokes ride the 8.9x transform: 1.15 reads as ~10 units lit, like an article's 3 at 3.4x
  &.lit { transform: scale(var(--lit)); .hex-shade { opacity: 0; } .rank-ring { stroke-width: 1.15; opacity: 1; animation: st-pulse-rank 1.6s ease-in-out infinite; } }
  &.flipping   { animation: st-flip 560ms ease-in-out 1 both; }   &.flipping .hex-shade   { animation: st-light 560ms steps(1, end) 1 both; }
  &.unflipping { animation: st-unflip 560ms ease-in-out 1 both; } &.unflipping .hex-shade { animation: st-unlight 560ms steps(1, end) 1 both; }
}
```
`st-flip`/`st-unflip`/`st-light`/`st-unlight` already read `--lit`/`--shade`. New keyframe
`st-pulse-rank { 0%,100% { stroke-width: 1.15 } 50% { stroke-width: 1.7 } }` (`st-pulse` would be 27–40
units at 8.9×). Reduced motion (L623–629): add `.rank-node` to `transition: none`, `.rank-node.lit
{ transform: none }`, and its flipping/unflipping/shade/ring to `animation: none`.

Panel (in `aside.skilltree-panel`, after `.sp-sheet`):
```scss
// class-change screen (2026-09-27): previous rank, arrow, new rank. Drawer content ~352px, 360px-phone
// sheet ~312px: two 128px hexes + arrow + gaps ≈ 300 fits both
.sp-evo { display: flex; align-items: center; justify-content: center; gap: 0.6rem; margin: 0.4rem 0 1rem; padding: 0.9rem 0.5rem;
          background: #1C1B22; border: 1px solid var(--sp-rule); border-radius: 4px;
  .sp-evo-hex { flex: 0 1 128px; margin: 0; display: flex; flex-direction: column; align-items: center; gap: 0.35rem;
    img { width: 100%; height: auto; display: block; }
    figcaption { font-family: $font-family-monospace; font-size: 0.7rem; letter-spacing: 0.04em; text-transform: uppercase; color: var(--sp-soft); text-align: center; }
    &.to figcaption { color: var(--sp-gold); } }
  .sp-evo-arrow { flex: none; font-size: 1.7rem; line-height: 1; color: var(--sp-gold); }
  &.single .sp-evo-hex { flex-basis: 160px; }
}
```
Legend: `.lg-rank path { stroke: var(--st-gold); }` beside `.lg-pips circle`.

**Rest-state decision**: art under an ink shade with a gold ring (the `.node` idiom), not a solid gold
badge. At 16 px / 10 px the sticker is unreadable either way; what registers is a dark bead with a gold rim,
which says "Peter" the way the origin ring does, without out-shouting the year labels. Hover eases the
shade to 0.45 as a preview. If Peter wants it louder, it is one `fill` change on `.hex-shade`.

### 5. Art: `4_stickers/ranks.yaml` (new) + picking

- `.gitignore`: add `4_stickers/ranks/` (candidates are scratch, like `articles/`).
- `ranks.yaml`: copy `defaults` from `bananarama.yaml` verbatim, `n: 2`, `seed: 5891`, `output-dir: ranks/`.
  Run from repo root: `Rscript -e 'bananarama::bananarama("4_stickers/ranks.yaml")'`. Because each later
  rank cites the previous **framed final** in `www/hex/`, entries are appended one tier at a time: add
  `rank_student` → generate → pick → frame; append `rank_postdoc`; then `rank_scientist`. Existing outputs
  are skipped, so rerunning is safe. Re-rolls need a changed `seed` per entry.
- Budget: 3 × 2 × $0.07 ≈ $0.42, ≈ $0.85 with one re-roll each. **Peter raises the cap first**; ping with
  `ellmer::chat_google_gemini()$chat("pong")` before the batch (a 429 looks like a 10-minute hang).
- Prompts (house rules: scene first, beard negation up front, ≤ 4 refs, one prop per rank, head and
  shoulders with margin so nothing clips at hex corners):
  - **rank_student** (`[refs/peter]`, `[../www/hex/puzzled]`): "Close-up portrait, head and shoulders only,
    of the SAME man shown in [../www/hex/puzzled], drawn again by the same hand in exactly the same pixel
    style, palette, candlelight and viewing angle, with the face of [refs/peter]. His hair and short beard
    are plain medium brown, the same brown as a walnut shell, with no red, no orange, no ginger and no
    copper. He is a graduate student in a northern winter: a heavy grey wool coat buttoned to the chin and
    a knitted scarf, and he clutches a thick stapled manuscript to his chest with both hands, a corner of
    the pages curling. He looks tired but game. Warm candlelight on his face. Plain dark stone wall behind
    him, softly out of focus. Nothing else in the picture."
  - **rank_postdoc** (`[refs/peter]`, `[../www/hex/rank_student]`): "This is the SAME man shown in
    [../www/hex/rank_student], drawn again by the same hand in exactly the same pixel style, palette,
    candlelight and viewing angle, with the face of [refs/peter], now advanced to a higher rank:" + the
    beard sentence + "The coat and scarf are gone. He wears a plain black henley with the sleeves pushed
    up, and holds up in one hand a single round glass flask in which a small double helix glows softly.
    He looks alert and a little surprised at it." + candlelight / wall / nothing else. (No lab coat here:
    the coat is the Research Scientist's.)
  - **rank_scientist** (`[refs/peter]`, `[../www/hex/rank_postdoc]`, `[motif_refs/coin]`): same opener
    citing `rank_postdoc` + beard sentence + "He now wears a crisp white lab coat, open over the black
    henley, with a small embroidered mark on the breast pocket (a stitched shape, not letters), and holds
    up between thumb and forefinger a single heavy bronze challenge coin, no taller than a quarter of the
    picture, its face exactly the design shown in [motif_refs/coin]: three equal wedges divided by raised
    ridges, a Maltese cross, a plain blank shield, a single staff with one serpent; no stars of any kind.
    He looks steady and faintly amused." + candlelight / wall / nothing else. The lab coat is the real
    story: Hunter gave Peter a monogrammed one as a joke when he was hired as a research scientist, so the
    promotion is when the coat appears. The style prefix forbids letters, hence "stitched shape"; at 92 px
    a monogram would not read anyway.
- **Preview + pick**: `preview_candidates.R` hard-stops on a non-article id and reads `articles/` only;
  `pick_sticker.R` edits `articles.yml`. Smallest change: give `preview_candidates.R` optional flags
  `--dir <subdir>` (default `articles`) and `--parent <hexname>` (final shown on the left), dropping the
  hard stop; add `4_stickers/pick_rank.R <id> <n>` (~25 lines, template `pick_sticker.R`):
  `frame_hex("4_stickers/ranks/<id>-<n>.png", "www/hex/<id>.png", height = 554)`, assert 480 × 554 PNG,
  copy the square verbatim to `finals_src/<id>.<true ext>`, run `build_tree.R` unless `--no-build`. No
  YAML edit needed; `ranks.yml` names the sticker statically. Judge at 92 px (contact-sheet row) and
  ~128 px (panel size). Note `rank_*` provenance in `finals_src/README.md`.

### 6. Docs

- `CLAUDE.md` skill-tree section: bullet on career ranks (`ranks.yml` ordered chain → `meta.ranks` with
  flank placement → `.rank-node` + `.sp-evo`; deep links `#rank-<year>`; `ranks` ≠ career-level
  achievements; art via `ranks.yaml` + `pick_rank.R`; sheet's Level line stays hand-written). Hex stickers
  section: mention `ranks.yaml` / `pick_rank.R`.
- `5_skilltree/README.md`: `ranks.yml` as a second input to `build_tree.R`.
- `bob.md` L54: drop "career-rank gold markers on the year rings"; if picks are pending, add to This Week.
- `logs/skilltree/plans/2026-09-27_rank-markers.md` (this plan) and `logs/skilltree/2026-09-27_rank-markers.md`
  (What changed / Verification / Not done; record placement numbers, rest-look decision, `--lit` arithmetic,
  picks and spend, the unpin-block debt).

## Order of work

1. `ranks.yml` → `build_tree.R` → run; check console and `meta.ranks` (chain student → postdoc → scientist).
2. JS + SCSS + cache-buster → render `skilltree.qmd` → serve `docs/` over HTTP → screenshots (markers on
   `blank_dark` placeholders).
3. `ranks.yaml`, `pick_rank.R`, `preview_candidates.R` flags, `.gitignore`. **Pause: Peter raises the cap.**
   Generate `rank_student` → contact sheet → Peter picks → frame → rebuild; repeat for postdoc, scientist.
4. Docs, log, commit. Push only on Peter's say-so.

## Verification

1. `Rscript 5_skilltree/R/build_tree.R`: summary lists three markers, all `right`, at the coordinates
   above; before art exists it says `missing art -> blank_dark` and still succeeds.
2. Overlap check over `tree.json`: for each rank, every node with `|y − rk.y| < 1` has `|x − rk.x| ≥ 73`
   (today's minimum: 2024 vs `willems_2024_self`, 374).
3. `quarto render skilltree.qmd`; confirm `docs/www/skilltree.js` updated (the `?v=` gotcha) and
   `docs/www/hex/sm/rank_*.png` present.
4. Serve `docs/` (`python3 -m http.server`; Chrome will not `fetch` tree.json from `file://`). Headless
   screenshots at 1400 and 420 px of `skilltree.html`, `#rank-2020` (lit marker ≈ 147 px, two-hex screen in
   the drawer / bottom sheet), `#rank-2019` (single hex).
5. Interaction: hover tooltip; click flips and opens; pinning an article releases a marker and vice versa;
   Esc and outside-click release; marker returns to `g.ranks`; "Character sheet →" opens the sheet.
6. Keyboard: Tab reaches the markers, Enter/Space toggle, focus returns on close.
7. Reduced motion (Chrome `--force-prefers-reduced-motion`): no flip, no pulse, panel opens; marker stays
   unscaled (consistent with the origin).
8. `tree.json` diff: only `meta.ranks` added and `meta.generated` changed; rings 8–9 and the 2026 label
   untouched. Existing article pin/unpin, origin sheet, `#me`, achievements numerals unchanged.
9. Art: each final 480 × 554 PNG; beard brown; no hexagon drawn in the scene; face consistent across three.

## Risks and judgement calls

- **Tap target** is 10 px on phones; the transparent 42-unit hit circle is the mitigation.
- **8.9× transform** is the largest on the page (articles 3.4×, origin 2.3×). Keyframes are parametric; if
  the flip reads as a pop, lower `--lit` to `calc(2.4 * 100 / 38)` rather than adding keyframes.
- **Fallback "above"** only fires when both flanks are taken or the label is over a hex; unreachable today.
  A future 2024 paper on ring 7's q=2/q=4 flips the marker to the other side automatically.
- **Likeness drift** (ginger beard, zoom onto the cited prop) is the real art risk; mitigations are in the
  prompts. Budget one re-roll per rank.
- **Three unpin blocks** (node, origin, rank) is accumulating debt; log it, do not refactor now.
