# Session log — 2026-09-18: per-article sticker pipeline, tested on the mortality chain

Plan: `logs/skilltree/plans/2026-09-18_article-sticker-pipeline.md` (approved and completed same day).

## Decisions (Peter, 2026-09-18)

- Domain motifs **reuse the phase-sticker vocabulary**: responders = helmet + candles, criminology =
  magnifying glass + parchment + red string, biosocial = flask + helix + honeybee.
- **Level = depth in `builds_on`** (root 1, child 2, grandchild 3, capped). Role and effort do not
  affect rank.
- **Inheritance = the parent's framed final attached as a reference image** plus a "same object,
  higher rank" opener. Hence tiered generation.
- Test set: `tanksley_2025_mortality` → `tanksley_2026_clarifying` → `tanksley_2026_correctional`.

## What was built

| File | Role |
|------|------|
| `4_stickers/motifs.yml` | Vocabulary: per-area `noun/object/surface/accent`, `levels` 1–3, `secondary` strong/faint, `lineage` one/two openers, an article-only `style` addendum. |
| `4_stickers/compose_articles.R` | `articles.yml` + `motifs.yml` → `4_stickers/articles.yaml`. Readiness gate: an article is emitted only when every parent already has a final in `www/hex/`. `--dry-run`, `--ids`. |
| `4_stickers/articles.yaml` | Generated bananarama config (committed, derived). Shared style block copied from `bananarama.yaml`. |
| `4_stickers/preview_candidates.R` | Contact sheet: parents + candidates framed at 554, plus a 92 px row → `4_stickers/articles/_preview/<id>_contact.png`. |
| `4_stickers/pick_sticker.R` | `frame_hex(height = 554)` → `www/hex/<id>.png`; sets `sticker: <id>` through the rating app's `helpers.R`; runs `build_tree.R`. |
| `.gitignore` | `4_stickers/articles/` (candidates + previews). |
| `5_skilltree/R/build_tree.R:45` | Stale comment fixed (finals are 480×554, not 1200 px). |

Composition rules as implemented: primary = highest area rating (ties: responders > criminology >
biosocial); secondary = next area if ≥ 1 (`strong` at 2–3 puts the accent on the object, `faint` at 1
puts it small in the background); up to two parent refs (the deepest). Articles that already have a
sticker are excluded from `articles.yaml` so a wiped candidate folder can never silently re-bill.

## The run ($0.61, 9 images, seed 5891, `gemini-3.1-flash-image-preview`)

| Tier | Article | Level | Prompt gist | Pick | Why |
|------|---------|-------|-------------|------|-----|
| 1 | mortality | 1 | helmet on ledge, dim, one unlit stub | 3 | full brim inside the clip, brightest plate |
| 2 | clarifying | 2 | same helmet (ref: mortality), soft glow, tall lit candle, etched hexagon | 2 | strongest glow; the etched hexagon is invisible at 92 px in all three |
| 3 | correctional | 3 | same helmet (refs: clarifying, mortality), hovering, radiant, inside a glowing hexagon outline, embers, two candles, faint red string (criminology 1) | 1 | whole hexagon stays inside the frame; 2 and 3 clip its apex |

Inheritance held: the model kept the helmet's shape, plate, and viewing angle across all three tiers
from the reference image alone. The rank progression reads at 92 px as dim → glowing → framed in
light. Verified in the rendered page (served over http, deep link `#tanksley_2026_correctional`):
node flipped with art, both parents showing their stickers under the shade, lineage edges lit.

## Vocabulary lessons (already folded into `motifs.yml` / CLAUDE.md)

- **Rank must be light, not detail.** The etched hexagon under the level-2 helmet is a nice touch at
  554 px and gone at 92 px. Glow intensity and candle count carry the rank; keep it that way.
- The biosocial object glows by definition (luminous helix), so level 1 cannot say "no glow of its
  own". Level 1 now says the scene is dim and the surface bare.
- The lineage opener references the parent by its path placeholder, which bananarama rewrites as
  "`../www/hex/<id>` (shown in image 1)". Ugly in the prompt, harmless in the result.
- bananarama downsizes reference finals 480×554 → 444×512 on its own; no prep needed.

## Gotchas

- `by_id[only]` keeps names, so `map()` over it produced a YAML *mapping* under `images:`; bananarama
  needs a *sequence*. `unname()` before `as.yaml`.
- `paste0("parent: ", character(0))` returns `"parent: "`, not `character(0)`. Use `recycle0 = TRUE`
  or the contact sheet grows a phantom tile.
- The skill-tree page loads `tree.json` with `fetch()`, which fails on `file://`. Headless-Chrome checks
  must go through a local http server (`python3 -m http.server` in `docs/`).

## Not done / next

- Uncommitted. Peter reviews the three picks (swap with `pick_sticker.R <id> <n>`), then commit + push.
- Remaining 27 articles: 24 roots are ready now; `mcallister_2025_markers`, `raffington_2023_associations`
  (tier 2) and `mcallister_2026_inflammation`, `desteiguer_2025_stability` (tier 3) follow. The criminology
  and biosocial objects have not been generated yet; review their `motifs.yml` text before the batch.
- Rating app still does not show or edit `sticker`; not needed while the pipeline sets it.

## Afternoon: shade deepened, helmet replaced by a tri-service coin

**Shade.** Peter wanted unselected art harder to see and the selected node to pop harder. `theme.scss`
`.hex-shade`: resting 0.58 → 0.74, in-press/preprint 0.74 → 0.84, muted 0.82 → 0.90, hover 0.30 → 0.45,
lit stays 0; `st-light` keyframe start updated to match.

**Motif.** Peter: a fire helmet for "first responders" is off target for a corpus that is mostly law
enforcement. Options weighed: blank shield badge, beacon lamp, watchman's lantern, empty boots, radio.
Peter brought a Gemini tri-service disc (Maltese cross / star-shield / Star of Life); rejected as-is
(two banned star shapes, three glyphs at 92 px, flat vector style, primary palette) but the concept
became a **bronze challenge coin** with three wedges: fire-service Maltese cross, blank shield, rod and
serpent, no stars. A $0.20 level-1 test (`4_stickers/test_coin.yaml`, outputs in `articles/_tests/`)
proved it in-style. Peter then edited candidate 1 in Gemini for a recognisable cross; that image,
cropped out of its hex frame, is now **`4_stickers/motif_refs/coin.png`** (committed; `refs/` stays
gitignored personal photos) and is cited inline from `motifs.yml` as `[motif_refs/coin]`.

**Reference dominance, and the fix.** With the reference attached, the first tier-1 run zoomed into
the coin face and dropped the ledge and candle (`articles/_tests/mortality-coin-zoom/`). The object
text now says the coin is "seen whole and small… no more than half the height of the picture" and
frames the reference as "the design on its face is exactly the design shown in…". Re-roll behaved.
Lesson for `motifs.yml`: a reference image anchors the *object*; the scene text has to outrank it
explicitly or the level cues vanish.

**Coin chain.** Helmet candidates, finals and previews moved to
`4_stickers/articles/archive-helmet-2026-09-18/` (nothing deleted). Picks: mortality 1 (full rim,
ledge, dead stub at left edge), clarifying 2 (strongest glow, lit candle), correctional 1 (whole
hexagon inside the clip, red string visible). Inheritance held across all three; at level 3 the
glowing hexagon nearly coincides with the sticker edge, which reads as a lit border at 92 px — a
happy accident worth keeping.

**Spend today:** helmet chain $0.61 + coin test $0.20 + zoomed tier 1 $0.20 + coin chain $0.61 = **$1.62**.

**Committed and pushed** at the end of the day as `d0a5596` (see the final section).

## Evening: mixed domains, handcuffs, the tie rule

**Mixed-domain rule** (composer + `motifs.yml`): a tie between the top two areas draws ONE fused object
from `motifs$pairs` (keyed `area+area`, alphabetical) with no accent; otherwise the primary object
carries the secondary's accent, "strong" (on the object) at 2–3, "faint" (background) at 1. Only
biosocial+criminology ties exist (5 articles); all three pairs are written anyway.

**Criminology object → handcuffs** (Peter: the magnifying glass said "detective"). Written as
hand-forged iron darbies; the model drew modern cuffs, accepted. Accent = one small iron key.

**Tie rule** (Peter): an honest two-way tie is always 2/2, never 3/3 or 1/1. Enforced three ways:
`helpers.R::normalize_tie()` on save in the rating app, a hard validation stop in `build_tree.R`, and
the `articles.yml` header. Re-ranked: `langevin_2022_life` 3/3/0 → 2/2/0 (only violator; layout
unchanged since direction and purity are scale-free, only the panel dots move).

**Test ($0.40), both real roots, both kept:** `barnes_2024_risk` (cuffs, pick 2) and
`tanksley_2023_history` (fused flask-and-cuffs, pick 1 — cuffs locked round the flask neck, helix
rising through). Tree now carries 5 article stickers. Spend today: **$2.02**.

**Winner archive.** `pick_sticker.R` now copies the chosen candidate's unframed square, bytes verbatim
under its true extension, to `4_stickers/finals_src/<id>.<ext>` (committed) so finals can be reframed
on any machine. Losers stay gitignored in `4_stickers/articles/`. Backfilled the five picks (~2.3 MB).
First attempt re-encoded to PNG and doubled the size; Gemini squares are JPEG in `.png` clothing.

## Night: the full batch

Peter chose roots at n = 2, children at n = 3, to stay inside the $10 Gemini budget (AI Studio showed
$3.91 spent at 13:55, against $4.86 in the logs; the gap is billing lag or bananarama over-estimating).
`compose_articles.R --n` added for that.

- 21 roots at n = 2: $2.83. Picks recorded in `articles.yml`; near-twins at the fixed seed, as expected.
  Two surprises kept: the 3/2 "key rests on the flask" became a key floating INSIDE the flask
  (`tanksley_2019_genome`, `motz_2019_every`); 3/1 faint accents worked (key on the wall behind
  `tanksley_2024_polygenic`, bee behind `tanksley_2020_identifying`). Level-1 candles came out lit in
  most; cosmetic, not re-rolled.
- Tier 2 (`mcallister_2025_markers` 2, `raffington_2023_associations` 1): $0.41.
- Tier 3 (`mcallister_2026_inflammation` 1, `desteiguer_2025_stability` 1): $0.41. Level-3 hexagon
  frame lands inside the clip on candidate 1 both times; candidates 2-3 clipped the apex.
- **30 of 30 nodes stickered.** `www/hex/` 11 MB (finals), `www/hex/sm/` 1.9 MB (what ships),
  `4_stickers/finals_src/` 13 MB (winning squares, committed).

**Spend today $6.06; project total by the logs ≈ $8.90 of $10.** Check AI Studio before any re-rolls.

Observation for later: the 12 pure-biosocial roots are visually near-identical (same object, same
level, same seed). If that reads as monotonous on the tree, a per-article seed (hash of the id) in
`compose_articles.R` would add variety for the price of regenerating them.

## Late: variety — variant slots, per-article seeds, tailored motifs (NOT yet generated)

Peter: the 30 stickers are near-identical within a domain. Fix designed and wired, no spend:
- `motifs.yml`: each anchor object has a `{variant}` slot (flask: what rises from the neck; cuffs: what
  they lock around; coin: what it leans against) and 8 named variants per area; pairs take `variant_from`.
- `articles.yml`: new judgement field `motif` (a variant name OR free text). Null = inherit from the
  deepest parent, else sample from the area list by a hash of the id. Survives `extract_cv.R` and
  `add_article.R`. `compose_articles.R` also gives every article its own seed from the same hash,
  and `--redo` plans regeneration for articles that already have stickers.
- Peter tailored: the hash sample gave the personality GWAS a clock face, which "makes no sense"; he
  proposed a two-faced jester mask. All 24 roots now carry a chosen motif (table in the YAML; e.g.
  fingerprint for "every contact leaves a trace", brass bell for the inferential-testing paper, BJJ
  belt for the use-of-force vignettes, the fire helmet returns as the variant for the firefighter
  biomarker chain). Children inherit.
- Regeneration plan: move current candidates aside, roots at n = 2 then two child tiers at n = 3,
  ≈ $3.80. Waits on Peter topping up the Gemini account. Current finals stay archived in
  `finals_src/` and `www/hex/`.

## v2: the variety batch (Peter topped up $10)

v1 set archived to `4_stickers/articles/archive-v1-2026-09-18/` (candidates, finals, winning squares).
Sticker fields cleared so the tiers staged themselves from scratch.
- 24 roots at n = 2 with tailored motifs and per-article seeds: $3.24. Every one distinct, every one
  still its domain at 92 px. Standouts: jester masks (Schwaba), BJJ belt (use of force), fingerprint
  ("every contact leaves a trace"), brass bell (inferential testing), family tree (polygenic).
- Tier 2 (clarifying, markers, associations) and tier 3 (correctional, inflammation, stability) at
  n = 3: $1.22. Variants inherited down every chain; level-3 hexagon frame clean on candidate 1 each time.
- **30 of 30 re-stickered. v2 spend $4.45; project total ≈ $13.35 of $20.**
- Picks all candidate 1 or 2 as listed in `articles.yml`; winning squares in `finals_src/`.

## Evening 2: origin polish, responder re-roll blocked by the spend cap

- Selected hexes 1.8x → 3x → 3.4x; origin lit scale = 3.4 / 1.45 so it lands at the same size; origin
  lifted into the top layer while pinned (it used to enlarge underneath the ring and the 2019 label);
  reverse flip on deselect for articles and the origin (`unflipping` class, `st-unflip`/`st-unlight`,
  node stays in the top layer until `animationend`); resting shade is `--shade` per node; origin ring
  and its tooltip/sheet accent are gold `#D9A441`. Script cache-buster now `?v=2026-09-18d`.
- Responder coin template rewritten (coin BESIDE the variant, both whole, pair centred and filling the
  frame) after Peter flagged the coin hiding the belt/helmet/bollard and half-empty frames. Nine
  responder stickers cleared and archived to `archive-v2-responders-2026-09-18/`; 5 roots composed.
- **Generation hung twice for 10 min with no output.** Cause: `HTTP 429 Too Many Requests … manage
  your project spend cap` — the AI Studio project spend cap, not the balance. bananarama/ellmer retry
  429s silently with backoff, which looks like a hang. Nothing was billed for the two stalled runs.
  Gotcha: before a batch, a one-line text ping (`ellmer::chat_google_gemini()$chat("pong")`) tells
  you in two seconds whether the API will answer. Waiting on Peter to raise the cap at ai.studio/spend.

## Night 2: responders re-rolled with placement guardrails (cap raised)

Coin template now sizes the coin against its companion ("about the same height as {variant}, no taller
than one third of the picture", side by side, both whole, seen from a little distance). Two passes were
needed: "fills most of its width" still let the coin swallow the frame when the companion was small.
Two lessons baked into `compose_articles.R`:
- **`--reseed K`**: the per-article hash seed makes a re-roll with the same prompt reproduce the same
  composition almost pixel for pixel. Retries need a shifted seed; the seed used is in `articles.yaml`.
- **Some objects resist scale.** The model would not draw a coin-sized door; `martaindale_2026_public`
  now has "a heavy brass door knob and key plate on a block of dark wood" and reads immediately.
Picks: eleuterio 2, mortality 2, gonzalez 1, martaindale 2 (reseed 7), blair_active 1 (reseed 7),
clarifying 1, markers 2, correctional 3, inflammation 1. Nine responders redone, 30/30 stickered.
v3 spend $2.16; project total ≈ $15.50 of $20 (cap raised by Peter).
Also this evening: origin reverse flip, origin lifted to the top layer while pinned, gold origin ring.

## Night 3: Peter's four corrections ($1.42)

- `martaindale_2026_public`: reverted to the v2 door image (coin leaning on an ajar door) — Peter
  preferred it to the door-knob; the v2 candidate was restored from the archive and re-picked (no spend).
- `blair_2025_active`: bollard → "a car steering wheel standing upright on its rim" (Peter: the
  bollard read as something else entirely). Pick 3.
- `mcallister_2025_markers` is the LAW ENFORCEMENT biomarker paper, so its motif is pinned to a peaked
  police service cap as a deliberate exception to inheritance; `mcallister_2026_inflammation`
  (firefighters) is pinned to the helmet so it does not inherit the cap. Pick 1 / 2.
- Level-3 candles: the lit candle from the parents vanished behind the hexagon on the correctional
  hex. Two rewrites failed (candles at the end of the sentence were dropped outright when two parent
  refs dominated); the third worked by placing the candle clause BEFORE the hexagon clause, right
  after the object. Lesson for `motifs.yml`: with reference images attached, clause order is
  priority order. Correctional pick 1, inflammation pick 2 (both `--reseed 5`).
Project total ≈ $17 of $20.

## Future work (Peter, 2026-09-18; not started)

Three additions to the skill tree, recorded so the ideas survive. None is scheduled.

1. **Career-level markers on the year rings.** Peter's ranks over the tree's span: doctoral student
   2019–2020, postdoc 2020–2024, research scientist 2024 onward. Idea: a very small gold hex beside the
   year label where a transition happens (2020, 2024; and 2019 as the starting rank), in the origin's
   gold (`--st-gold`, `#D9A441`) so it reads as "Peter", not as a domain. Click: it enlarges like an
   article hex and shows a generated image in the hex plus a short line of text about the rank change
   (the "level up"). Art would go through the same `4_stickers/` pipeline (a small `career` set;
   one subject per hex, same pixel style). Data: a `career:` list in `tree.json` meta written by
   `build_tree.R` from a small YAML (year, title, blurb, sticker); `skilltree.js` draws and toggles
   them like nodes. Watch the top edge of the canvas: the 2026 label already sits near it.

2. **Google Scholar integration.** A stat bar or side panel on the tree page pulling citations,
   h-index, i10 (and per-article counts if cheap) from Peter's Scholar profile. Scholar has no API:
   options are the `scholar` R package (scrapes; rate-limited, brittle), a scheduled GitHub Action
   that writes `www/scholar.json` and commits it (so CI renders without R and the page stays static),
   or OpenAlex as the sturdier stand-in for per-article counts. Cache and show the fetch date.

3. **Dungeon Crawler Carl-style achievement announcements.** When a stat crosses a threshold (h-index
   +1, citations hit a round number, first citation on a new paper), the site posts an announcement
   in the DCC register: a triumphant system-message header, then the reward line as the punchline.
   Peter's example: *"Reward? Nothing. You went into academia because you thought it was fun, you
   sick, sick man. Not for the money. You get nothing."* Mechanism: the same scheduled job diffs the
   new `scholar.json` against the last one, matches rules in an `achievements.yml` (threshold,
   title, body template), and appends an entry to `news.yml` (or a dedicated feed) so it shows on the
   homepage. Voice rules from CLAUDE.md still apply (sass about the job, never about responders
   dying). Peter: DCC "fits the aesthetic we're building" and may deserve a wider role than
   announcements; decide after the first one lands.
