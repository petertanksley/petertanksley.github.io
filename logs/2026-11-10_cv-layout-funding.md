# 2026-11-10 — CV layout pass and funding update

Done while assembling an application package; the CV needed a current PDF.

**Funding content**
- NIDA R01 now reads "Unfunded" (reviewed, not discussed; NIDA notice 2026-11-06).
- Both NSF proposals (2024 PAC, 2025 DRMS) now carry "Role: Co-PI (PI: M. Hunter Martaindale)", confirmed from the
  submitted budget justifications.
- The two NIOSH HELD pilots are **not** on the site CV. The standing rule (no CV line until the agreements are signed)
  was checked with Peter today and kept. The application copy of the CV does list them as "Approved, agreement pending".

**Layout (`2_cv/tanksley_cv.css`, `2_cv/tanksley_cv.qmd`)**
- All right-hand years use `.cvdate`: upright, floated into a 6em gutter (`.cv-indent p:has(.cvdate)` reserves it), so
  titles and funder lines wrap short of the year. Inline `style="float: right"` spans are gone.
- Software section is a two-column grid (`.cv-software`), Data Science Projects leading the second column.
- Bullets hang: wrapped lines align with the first line's text.
- Print header carries a link to the site beside the email.
- Page breaks: `.cv-indent` and `.cv-software` never split. Headings carry an invisible reserve so Chrome's printer
  keeps them with their content (it ignores `break-after: avoid` here); the reserve is switched off inside
  `.pagedjs_page`, where pagedjs handles it.

**Local PDF without Node.** Copy `2_cv/`, `_extensions/` and `_hexband.qmd` to a scratch folder, drop the hexband
include line, `quarto render tanksley_cv.qmd --to html`, then headless Chrome `--print-to-pdf --no-pdf-header-footer`.
Close to the pagedjs build but not identical in page breaks.

**Not verified locally:** the pagedjs (CI) PDF with the new CSS. Check the live PDF after the push.

**Second push, same day.** The first live pagedjs PDF left "Publications" and "Academic Articles" alone at the foot
of page 1: pagedjs does not carry `break-after: avoid` through the nested section wrappers either, and the first
version of the reserve was switched off inside `.pagedjs_page`. The reserve is now real padding on the heading with an
equal negative margin, applied in both builds, larger where a heading is followed directly by a subsection
(`h2:has(+ section)`, `h3:has(+ section)`). Verified in the Chrome build only; pagedjs could not be run locally (no
Node; the browser polyfill would not paginate to completion in headless Chrome).

**Live PDF check (same day, after the second push).** Downloaded the live `tanksley_cv.pdf` (10 pages, modified
09:56 CST, two minutes after d3c3bb3). Last text block on every page is an entry, never a bare heading or year label;
page 1 closes on Research Concentrations with its content. The stranded "Publications" / "Academic Articles" problem is
gone in the pagedjs build. Checked by text-block position only, not by eye; CI run status not confirmed (`gh` absent).

**Scholar refresh and soft-block bug (same day).** Manual refresh: 480 -> 481 citations, 0 rules fired. The first run
wrote empty `scholar_by_year` for the five papers whose count moved: Scholar answered the per-paper chart request
without a chart, and `fetch_scholar.R` only guarded `is.null(h)`, so `{}` overwrote the good bars and `scholar_by_year_n`
was stamped current (Necromancy would never have retried). Fix: zero rows for a cited paper now counts as a failed
fetch (keeps previous bars and n, two strikes stop the run), and a stored empty histogram is no longer reused. Re-run
fetched nothing (Scholar still blocking the chart), so the five keep their 11-02 bars with new totals and a stale `n`;
the next weekly run retries them. Bad snapshot kept in scratchpad, not committed.
