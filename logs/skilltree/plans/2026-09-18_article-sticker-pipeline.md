# Per-article hex sticker pipeline for the skill tree

**Status:** COMPLETED (2026-09-18) · Project: `PROJ_tanksley_website` · Copy to `logs/skilltree/plans/2026-09-18_article-sticker-pipeline.md` on approval.

## Context

The skill tree (`5_skilltree/`) has 30 article nodes and every one shows the `blank_dark.png` placeholder; per-article stickers were deferred 2026-09-07. Each article already carries the two facts the art should encode: three **area ratings** (`biosocial / criminology / responders`, 0–3) and a **`builds_on` lineage** (9 edges across 7 articles). Peter wants a *rule-driven* pipeline: a standard visual vocabulary per domain, composition by rating, and lineage that reads as inheritance plus rank ("rises to a new level of the skill"). Then a paid test on the mortality chain.

Decisions taken 2026-09-18:
- Domain motifs **reuse the phase-sticker vocabulary** (criminology = magnifying glass, parchment, red string; biosocial = flask, DNA helix, honeybee; responders = firefighter helmet, candles).
- **Level = depth in the `builds_on` chain** (root 1, child 2, grandchild 3+, capped at 3). Role and effort do not affect level.
- **Inheritance = parent's finished sticker attached as a reference image** plus text ("the same object as in image 1, now …"). Generation is therefore staged by depth.
- **Test set = `tanksley_2025_mortality` → `tanksley_2026_clarifying` → `tanksley_2026_correctional`** (all responders 3/0/0-ish; correctional has two parents). ≈ $0.63 at n = 3.

Existing machinery reused unchanged: `bananarama` (hadley, pinned) via `ellmer` + `GEMINI_API_KEY` in `~/.Renviron`; `4_stickers/frame_hex.R::frame_hex()`; `5_skilltree/tools/rate_articles/helpers.R::read_articles/write_articles/set_nullable`; `5_skilltree/R/build_tree.R` (already downsizes any `sticker:` named PNG from `www/hex/` into `www/hex/sm/`, falls back to blank if missing).

## Design

### 1. Vocabulary file — `4_stickers/motifs.yml` (new, committed, Peter-editable)

Holds every piece of prose the composer stitches, so tuning is a YAML edit, not a code edit.

```yaml
style: >            # article-specific addendum to the shared bananarama style block
  One clean symbolic subject, centered, filling the frame, nothing tangential.
  Plain dark stone wall behind, softly out of focus, candlelit. No people, no animals.
areas:
  responders:
    object: a single firefighter's helmet, dark leather with a completely blank brass front plate
    surface: a plain stone ledge
    accent: a simple wax candle            # the area's mark when it is secondary
  criminology:
    object: a single brass magnifying glass with a dark wooden handle lying on one sheet of blank aged parchment, pinned at a corner by a small brass pin
    surface: a plain dark wooden table
    accent: one length of red string
  biosocial:
    object: a single round glass laboratory flask with one softly luminous warm-gold DNA double helix rising from its neck like vapor
    surface: a plain dark table
    accent: a single honeybee
levels:             # rank vocabulary, applied to whichever object is primary
  1: "{object} resting on {surface}, plain and unlit, no glow, one short unlit candle stub beside it."
  2: "{object} on {surface}, now with a soft warm glow, one tall lit candle beside it, and the faint OUTLINE of a regular hexagon etched into the surface beneath it."
  3: "{object} hovering just above {surface}, radiant, inside one fully glowing OUTLINE of a regular hexagon, small embers drifting upward, two lit candles."
secondary:
  strong: "{accent} rests directly on the {primary_noun}."        # secondary rating >= 2
  faint:  "In the background, small and out of focus, {accent}."  # secondary rating == 1
lineage:
  one:  "This is the SAME {primary_noun} shown in {ref1}, drawn again by the same hand in exactly the same pixel style and palette, seen from the same angle, now advanced to a higher rank:"
  two:  "This is the SAME {primary_noun} shown in {ref1} and {ref2}, drawn again by the same hand in exactly the same pixel style and palette, now advanced to a higher rank:"
```

### 2. Composer — `4_stickers/compose_articles.R` (new)

`Rscript 4_stickers/compose_articles.R [--ids id1,id2] [--dry-run]` from repo root. R only (house rule).

1. Read `5_skilltree/data/articles.yml` via `helpers.R`, read `motifs.yml`.
2. For each article: **primary** = max area (ties broken in fixed order responders → criminology → biosocial, matching `build_tree.R`'s dominant); **secondary** = next area if rating ≥ 1 (`strong` if ≥ 2, `faint` if 1; skip if 0). **Level** = 1 + max(level of parents), recursive, capped at 3.
3. **Readiness gate:** an article is emitted only if it has no parents **or every parent already has `sticker:` set and `www/hex/<parent>.png` exists**. This is what stages generation by depth; rerunning after each pick step naturally emits the next tier. Articles skipped are listed with the parents they wait on.
4. Prompt = `[lineage sentence if any]` + `levels[L]` filled with the primary object/surface + secondary sentence. Parent refs are written as `[../www/hex/<parent_id>]` (bananarama's `find_image_file()` joins that onto the YAML's directory; ids are `[a-z0-9_-]` so the unescaped regex in `resolve_placeholders()` is safe). Max two parent refs (pick the two deepest).
5. Write `4_stickers/articles.yaml` (committed, derived) with `defaults.style` = the shared block copied from `bananarama.yaml` + `motifs.style`, `aspect-ratio: "1:1"`, `n: 3`, `seed: 5891`, `output-dir: articles/`, one `images:` entry per ready article with `name: <article id>`. Entries for articles that already have a `sticker:` are kept but bananarama skips their existing outputs anyway.
6. `--dry-run` prints the assembled prompts and the readiness table, writes nothing.

### 3. Preview — `4_stickers/preview_candidates.R` (new)

`Rscript 4_stickers/preview_candidates.R <id>`: frames each `4_stickers/articles/<id>-<n>.png` with `frame_hex(height = 554)` to the scratchpad, plus a 92 px copy, and montages them (magick `image_append`) into `<id>_contact.png`. Enforces the house rule "judge candidates framed, not square." Also frames the parent sticker beside them when lineage exists so inheritance can be judged side by side.

### 4. Pick — `4_stickers/pick_sticker.R` (new)

`Rscript 4_stickers/pick_sticker.R <id> <n> [--no-build]`: `frame_hex("4_stickers/articles/<id>-<n>.png", "www/hex/<id>.png", height = 554)`; set `sticker: <id>` in `articles.yml` via `read_articles`/`set_nullable`/`write_articles` (preserves header and field order, the same path the rating app uses); then `Rscript 5_skilltree/R/build_tree.R` unless `--no-build`. Sticker name = article id, so `www/hex/` stays flat and greppable.

### 5. Wiring and housekeeping

- `.gitignore`: add `4_stickers/articles/` (candidates), keep `articles.yaml` tracked.
- `5_skilltree/R/build_tree.R:45`: fix stale comment (finals are 480×554, not 1200 px). No logic change.
- `CLAUDE.md` "Hex stickers": add the article pipeline in three lines (compose → generate → preview → pick; sticker name = id; motifs.yml is the vocabulary; article stickers do **not** join the CV hex band, which stays the seven thematic marks).
- `bob.md` This Week: replace the deferred sticker line with the pipeline status after the test.
- Log: `logs/skilltree/2026-09-18_article-stickers.md` (decisions, prompts as run, candidate verdicts, spend).

Out of scope now: rating-app sticker field, CV band changes, muted/preprint node styling, the remaining 27 articles (this is the test; batch follows once the vocabulary is tuned).

## Execution order (test run)

1. Write `motifs.yml`, `compose_articles.R`, `preview_candidates.R`, `pick_sticker.R`; `.gitignore`; comment fix.
2. `compose_articles.R --dry-run --ids tanksley_2025_mortality,tanksley_2026_clarifying,tanksley_2026_correctional` → confirm only `mortality` is ready (level 1) and the prompt reads right.
3. **Tier 1:** compose → `Rscript -e 'bananarama::bananarama("4_stickers/articles.yaml")'` (3 images, ≈ $0.21) → preview → Peter picks → `pick_sticker.R tanksley_2025_mortality <n>`.
4. **Tier 2:** rerun compose (clarifying now ready, level 2, ref = mortality) → generate → preview → pick.
5. **Tier 3:** rerun compose (correctional ready, level 3, refs = clarifying + mortality) → generate → preview → pick.
6. `build_tree.R`, `quarto render skilltree.qmd`, check in browser.

**External-service note:** each bananarama run sends prompt text and the parent sticker PNGs (no personal reference photos are used by article prompts) to Google's Gemini API and spends ≈ $0.07/image. Approving this plan authorizes the three tier runs above (≈ $0.63 total). Anything beyond the test set gets asked separately.

## Verification

- Dry run prints three prompts; readiness table shows the staging (1 ready, 2 waiting) before any spend.
- After each tier: `ls 4_stickers/articles/<id>-{1,2,3}.png`; contact sheet viewed (copied to scratchpad, then `Read`); `pick_sticker.R` produces a 480×554 RGBA PNG (`magick::image_info`) and `grep -n "sticker: <id>" articles.yml` hits.
- After `build_tree.R`: `www/hex/sm/<id>.png` exists at 220 px; `jq '.nodes[] | select(.id=="<id>") | .sticker_src' www/tree.json` points at it; no "not found; using blank" warning.
- Inheritance check by eye: mortality, clarifying, correctional side by side in the contact sheet read as one helmet at three ranks.
- `quarto render skilltree.qmd` succeeds; headless-Chrome screenshot of `skilltree.html#tanksley_2026_correctional` shows the flipped node with art, lineage edges lit.
- `git status` shows only intended files: new scripts, `motifs.yml`, `articles.yaml`, three finals in `www/hex/`, three in `www/hex/sm/`, `tree.json`, `articles.yml`, `.gitignore`, `CLAUDE.md`, `bob.md`, log. No commit or push without Peter's say-so.
