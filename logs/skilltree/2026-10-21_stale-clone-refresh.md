# 2026-10-21 — Stale clone: OpenAlex drop redone and discarded; by-hand refresh (472 citations)

## What happened
A `/bob personal website` lookup read this clone's `bob.md` (last_updated 2026-10-06) and reported the OpenAlex
decision as still open. Peter answered "drop it" and asked for the OpenAlex removal plus the late-October refresh.
The session did both from scratch and committed locally (2e92483, now unreachable except via reflog). The push was
rejected: the clone was **8 commits behind** `origin/main`, which already held the real OpenAlex drop (c946101,
2026-10-11, log `2026-10-10_drop-openalex.md`), the weekly launchd check, the 10-11 / 10-12 / 10-19 refreshes, the
template-bank changes, and the 10-20 navbar and Projects-page work.

The remote version was kept in full: it is the one Peter reviewed, it deletes the Raffington percentile entry at his
request (the local redo had kept it as archival), and it adds `scholar_by_year_n` so a failed histogram fetch cannot
silently swallow a Necromancy revival. Local work discarded: `git reset --hard origin/main`.

Differences in the discarded version worth knowing about, none carried over: Necromancy's silent-years count ran back
to the publication year rather than a ten-year cap (the remote keeps `max(pub + 1, Y - 10)`; harmless either way), and
the retired rule was left as a comment block in `achievements.yml` rather than deleted.

## Lesson
`git fetch` and `git status -sb` before touching this project. Commits reach `origin/main` from more than one place
(the other clone, sessions on other days), and `bob.md` on disk is only as current as the last pull. Added to Notes.

## Refresh (redone with the canonical scripts)
`Rscript 5_skilltree/R/refresh.R`, by hand, two days after the Monday check. Scholar answered live; 3 per-paper
histories refetched, no block. The `scholar` package was missing from this R 4.5 library and installed on first run.

Snapshot 2026-10-21: 472 citations (468 on 10-19), 456 since 2021, h 13, i10 15. 29 of 30 articles matched
(`tanksley_2026_correctional` still has no Scholar row). Nothing fired; ledger stays at 6.

## Card facts added today (Peter, 2026-10-21)
- AJPH entry 28: reserved DOI 10.2105/AJPH.2026.308833, not yet resolving. Not added to `articles.yml` until it does.
- Nature entry 27 publishes in an issue on 2026-10-31 (publication office email).
- `card_schema: bob/2` tag restored on the card (it was in the discarded local commit 4f88bfb).
