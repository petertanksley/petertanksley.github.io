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
