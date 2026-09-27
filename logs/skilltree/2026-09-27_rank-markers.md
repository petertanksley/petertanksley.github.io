# 2026-09-27 — Career-rank markers ("class change" evolutions) on the skill tree

Plan: `plans/2026-09-27_rank-markers.md` (approved by Peter the same evening). Follows the removal of the
achievements numeral from the origin hex earlier today; Peter: "We do need something that denotes career
progression," with a Pokémon / Fire Emblem evolution moment on click.

## What changed

- **Data** `5_skilltree/data/ranks.yml` (new, ordered chain): Doctoral Student 2019 -> Postdoc 2020 -> Research
  Scientist 2024, each with title, org, years, sticker, headline, line. Key is `ranks`, never `career`
  (which already means an achievement with no article). Class names only, no level numbers (Peter's call); the
  character sheet's hand-written "Level 2" line is untouched.
- **R** `build_tree.R`: reads and validates `ranks.yml`; `rank_pos(k)` puts a 38-unit bead (`RANK_W`) on the
  right flank of the ring's year label (`label_x + 62`), left if a placed hex on that row is within 73 units,
  above with a warning as the last resort. Writes `meta.ranks[]` (key `rank-<year>`, geometry, copy, `from` =
  previous rank). Rank stickers join the downscale loop; missing art -> `blank_dark`. Today: all three `right`,
  2019 (1364.4, 962.3), 2020 (1312.4, 872.2), 2024 (1312.4, 511.9); nearest same-row hex 374 units away.
  `tree.json` otherwise byte-identical.
- **JS** `skilltree.js`: `g.ranks` layer (above tiles and welds, below labels) of `.rank-node` markers: image under
  `.hex-shade`, gold `.rank-ring`, a transparent 42-unit hit circle (the bead is ~16 px desktop, ~10 px phone).
  Tooltip, click/Enter/Space toggle mirroring the origin (lift to `gTop`, `pinned flipping lit`), a third unpin
  block, `rankHTML`/`openRank` class-change screen (`.sp-evo`: previous -> arrow -> new; `.single` for 2019;
  "Character sheet ->" rides `#me`), deep links `#rank-<year>`, legend item "Class change", document-click
  allowlist. Cache-buster `?v=2026-09-27a`.
- **SCSS**: `.rank-node` (`--lit: calc(3.4 * 100 / 38)` so it lights to article size; stroke 1.15 under the 8.9x
  transform; `st-pulse-rank`), reduced-motion coverage, `.sp-evo`, `.lg-rank`.
- **Rest look**: art under the ink shade with a gold ring, not a solid gold badge (the `.node` idiom; quieter
  beside the year labels; hover eases the shade to 0.45). With `blank_dark` underneath it reads as a hollow gold
  hex; with art it will be a dark bead. One `fill` change if Peter wants it louder.
- **Art tooling**: `4_stickers/ranks.yaml` (three prompts, tiers 2-3 commented out until the previous final
  exists; `"n": 2`, quoted because bare `n` is a YAML 1.1 boolean), `pick_rank.R` (frame, archive square, rebuild),
  `preview_candidates.R --dir <subdir> --parent <hexname>`, `.gitignore` for `4_stickers/ranks/`. Lab coat is the
  Research Scientist's, not the postdoc's: Hunter's monogrammed joke gift on hire (Peter, during plan review).
- **Docs**: CLAUDE.md skill-tree bullet, `5_skilltree/README.md`, `bob.md` (backlog line pruned; art step on This
  Week; the 09-22 trapdoor DONE line swept out, its narrative is in `logs/2026-09-22_trapdoor-scene.md`).

## Verification

Rebuilt and rendered; served `docs/` over HTTP (Chrome will not `fetch` tree.json from `file://`). Screenshots at
1400 px: rest (three beads beside 2019/2020/2024), `#rank-2020` (lit bead at article size, two-hex screen),
`#rank-2019` (single hex); 420 px `#rank-2020` (bottom sheet, both hexes visible). Script guards: `pick_rank.R`
rejects an unknown id and a missing candidate; `preview_candidates.R` accepts `--dir ranks --parent puzzled` and
still rejects an unknown article id in the default mode.

## Not done

- Art. Spend cap (~$19 of $20 by the logs' sum) must be raised by Peter first. Then: generate `rank_student`
  (~$0.14), `preview_candidates.R rank_student --dir ranks --parent puzzled`, Peter picks, `pick_rank.R`, uncomment
  `rank_postdoc`, repeat with `--parent rank_student`, then `rank_scientist` with `--parent rank_postdoc`.
- Debt: three near-identical unpin blocks (node, origin, rank) in `skilltree.js`. Refactor when a fourth appears.
- Not tested in a real browser: hover, keyboard focus order, reduced motion. Headless only.
