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
