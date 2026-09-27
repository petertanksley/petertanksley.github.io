# 2026-09-27 — h-index and i10 milestone ladders (Committee Box)

Closes open decision 3 from `2026-09-19_achievements-rules.md`. Peter: "Add the h-index and i10 milestone ladders."

## What changed

- `data/achievements.yml`: two new `ladder` rules alongside the existing `step` jokes, which are untouched.
  - `h-index-milestone` on `scholar.h_index`: 15 Silver / 20 Gold / 25 Platinum / 30 Legendary.
  - `i10-milestone` on `scholar.i10`: 20 Silver / 30 Gold / 50 Platinum / 100 Legendary (100 added beyond the
    09-19 proposal so the ladder has a top rung, in keeping with the other ladders).
  - Both hand out a **Committee Box**, the first career-level box type after the Appendix Box. Three title / body
    variants each; joke rewards not used here because the box is the point.
- `ACHIEVEMENTS.md`: tier table row and box-type list updated.
- `bob.md`: h/i10 ladders struck from the backlog line.

## Verification

- Real dry run (09-18 → 09-20): the same 4 entries as before, nothing new. Values at adoption are h 12, i10 15,
  both below the first rung, so no first-run flood.
- `--replay`: ledger rebuilt, `git diff` on `achievements_log.yml` empty.
- Synthetic pair (h 14 → 21, i10 19 → 30, via `--dir`/`--ledger` in the scratchpad): h fired once at Gold (the
  highest rung reached, skipping Silver, as ladders should), i10 fired Gold.

## Not done

Nothing committed; Peter to review wording and commit. Remaining proposals from 09-19: stretched total-citation
ladder, manual achievements file for talks / grants / awards.

## Addendum, same session: paper-cited variants 3 → 6

Peter, after asking whether achievements repeat: duplicate *firings* are blocked by the ledger key; duplicate
*wording* is not, because the variant pick is a hash of the key over three options (the two "It Grew Legs."
entries on 09-20 are the evidence). `paper-cited` fires most often, so it now has six titles and six bodies.
Synthetic test (every paper 0 → 10 on one date): all six titles and bodies used, spread 7 / 7 / 5 / 4 / 4 / 3.
Replay left the ledger unchanged. Known edge: a Scholar count that drops below a rung and re-crosses it would
fire that rung again under a new date; the checker does not consult the ledger for rungs already earned.

## Addendum, same session: replay preserves existing entries

Peter: "old achievements won't get changed, right?" They would have, under `--replay`: the ledger was derived state,
and a changed variant count shifts the hash pick, a moved rung retroactively un-earns. Now `--replay` keeps every key
already in the ledger verbatim (including entries today's rules no longer fire, kept in their date's block), and only
renders keys it has never seen. `--replay --fresh` restores the old discard-and-rebuild for a deliberate rewrite.
Tests: real replay 4 kept / 0 added, ledger byte-identical; synthetic 30-entry ledger with one tampered title and one
orphan key replayed to 31 entries with both intact; `--fresh` reverted the title and dropped the orphan. Register and
rules-file header updated to match.

## Addendum, same session: first refresh since the ladders; origin bucket bug

`refresh.R` run 2026-09-27: 447 → 451 citations, h-index 12 → 13, i10 15. One achievement fired, `h-index-up`
(joke reward, no box). `build_tree.R` then reported "0 career-level on the origin" with that entry in the ledger:
`split()` keyed career-level entries by `""`, and R's `[[""]]` never matches a name, so the origin's bucket had been
NULL since the feature shipped on 09-20 and no career-level entry had existed to show it. Keyed by a `CAREER`
sentinel now; tree.json carries the entry, the origin hex draws the numeral, the panel renders a null tier as
"none". Verified over a local HTTP server (Chrome will not `fetch` tree.json from `file://`, which reads as
"Could not load the tree data" and is not a data problem).

## Addendum, same session: homepage card shattered by the first paper-less entry

Peter, after the push: "The achievement got screwed up." The homepage card for `h-index-up` rendered as three
separate blocks with the body squeezed into the mark column. `achievement-home.ejs` had the paper-byline
conditional on its own line; with no paper it emitted a blank line, pandoc closed the raw-HTML block, and the rest
of the card became paragraphs. Same trap as the news photo earlier today, latent since 09-20 because every featured
entry until now had a paper. Inlined the conditional there and, pre-emptively, the two in `achievements-listing.ejs`
(which survived only because `<p>`/`<a>` restart pandoc HTML blocks where `<span>` does not). Convention added to
CLAUDE.md. Verified: zero `<p>` inside the card, achievements page 5 articles / 4 bylines / 4 hex links.
