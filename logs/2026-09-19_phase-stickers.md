# 2026-09-19 — Fresh phase stickers: coin and handcuffs

**Why.** The first-responder phase mark was a fire helmet, off target for a mostly law-enforcement corpus,
and the criminology mark was a magnifying glass that said "detective". The article stickers had already
moved to a tri-service challenge coin and iron handcuffs (2026-09-18), so the phase marks lagged the
vocabulary. First idea was to reuse the mortality paper's coin sticker as the phase mark; Peter saw it
in place on the Research page, homepage and CV band and rejected it: phase marks should be their own
canonical objects, drawn alone, not an article's instance. Reverted, then generated fresh.

**Generation.** Two round-3 prompts appended to `4_stickers/bananarama.yaml`, run with
`bananarama::bananarama("4_stickers/")` (existing names skipped, so only the new ones cost).

| Prompt | Result | Cost |
|--------|--------|------|
| `responders-coin` | reference dominance: all three zoomed into the coin face, no rim, ledge or wall | $0.20 |
| `responders-coin2` | scene-first wording ("seen whole and small, no taller than half the picture", ledge and wall described before the coin, `[motif_refs/coin]` framed as "the design on its face"); all three whole coins with candle stub | $0.20 |
| `criminology-cuffs` | three usable; closed cuffs, three-link chain, key beside | $0.20 |

Judged framed at 554 and at 92 px (contact sheets built with `frame_hex()` in the session scratchpad).
Round-3 picks were `responders-coin2-2` and `criminology-cuffs-2`; superseded below on brightness.

**Rounds 3b and 3c: brightness.** Peter saw coin2-2 and cuffs-2 in place and found both too dark to read
beside the flask. Round 3b (`responders-coin3`, `criminology-cuffs2`, $0.41) added a lit candle in frame and
described the scene as bright; it overshot to pale limestone and cream. Round 3c (`responders-coin4`,
`criminology-cuffs3`, $0.41) attached the flask's own unframed square, identified as `bananarama/genomics-2`
by image diff and copied to `motif_refs/flask_lighting.jpg`, as a lighting and palette reference, with the
text "dark warm wall in soft shadow, the object brightly lit, medium sepia, neither pale nor gloomy". All
six landed on the flask's palette. Final picks: `responders-coin4-2` and `criminology-cuffs3-1`.

**Files.** `www/hex/responders.png` and `www/hex/criminology.png` replaced (framed at 554, site
convention); old finals kept as `responders_helmet.png` and `criminology_glass.png`; winning squares
in `4_stickers/finals_src/responders.jpg` and `criminology.jpg`. Alt text updated in `research.qmd`,
`_hexband.qmd`, `4_stickers/hexband.R`, and the collage `aria-label` in `index.qmd`. Genomics unchanged.

**Lesson, again.** A reference image anchors the object and will eat the scene. Write the scene first,
size the object against the frame, and cite the reference only for the design on its face. This is the
third time (coin test, tier-1 zoom, phase coin); it is now in CLAUDE.md's sticker section.

Spend today: $1.42 (four rolls of two prompts, three candidates each; one roll lost to reference
dominance, one to overexposure).
