# data/jcr — Journal Citation Reports exports (Clarivate, via the Texas State library)

Raw JCR exports, one per JCR year, named `jcr_<year>.csv`. Keep them exactly as the portal writes
them (preamble, footer, whatever columns it gives); `5_skilltree/R/build_journals.R` finds the
journal title, ISSN and the Journal Impact Factor column and writes `../journals.yml`.

Rule (see `logs/skilltree/plans/2026-09-19_impact-factor-badges.md`): an article from year Y reads
JCR year Y − 1. Years 2018 and 2019 can also come from the `JCRImpactFactor` CRAN package
(covers JCR 2010–2019); the builder falls back to it when a CSV is missing.

Export the same 22 journals for every year 2018–2025 (extra cells are free and let the rule change).
Titles as Clarivate spells them:

| JCR title | JCR years the tree currently needs |
|-----------|------------------------------------|
| Aggression and Violent Behavior | 2018 |
| American Journal of Criminal Justice | 2024 |
| American Journal of Public Health | 2025 |
| Behavior Genetics | 2022 |
| Child Development | 2024 |
| Clinical Epigenetics | 2023 |
| Clinical Psychological Science | 2022, 2023 |
| Current Opinion in Psychology | 2018 |
| Frontiers in Sociology | 2018 |
| International Journal of Environmental Research and Public Health | 2021 |
| Journal of Criminal Justice | 2025 |
| Journal of Developmental and Life-Course Criminology | 2020 |
| Journal of Experimental Criminology | 2019 |
| Journal of Occupational and Environmental Medicine | 2024, 2025 |
| Journal of Personality and Social Psychology | 2023 |
| Journal of Research in Crime and Delinquency | 2025 |
| Lancet Regional Health - Americas | 2024, 2025 |
| Nature | 2025 |
| Nature Human Behaviour | 2022 |
| PLoS ONE | 2022 |
| Psychological Science | 2021 |
| Social Science Research | 2021 |

## Update process

Google Scholar and the `scholar` package cannot supply impact factors; this folder is the only source.

1. **New paper, journal already here:** nothing to do in this folder. A paper from year Y wants JCR Y−1,
   which Clarivate releases the June *after* Y−1, so a paper published early in the year reads the
   nearest year (flagged on the panel) until the annual refresh.
2. **New paper, new journal:** in JCR, search the one journal, export the current year to
   `jcr_<year>_<slug>.csv` here, run `build_journals.R` then `build_tree.R`. If the builder reports no
   rows for the venue, add the CV spelling to `ALIASES` in `build_journals.R`.
3. **Annual refresh (June/July):** export all journals for the new JCR year as one `jcr_<year>.csv`,
   rebuild both, commit. Tracked in `bob.md`.

The builders report unmatched venues, stray titles and every nearest-year fallback, so nothing goes
stale silently.

Preprint servers (bioRxiv, medRxiv) have no JIF and are not in JCR; the builder writes them a record
with no `jif`. `articles.yml` spells several venues differently ("Nature Human Behavior", "Frontiers
of Sociology", "&" for "and", a leading "The"); the builder carries an alias map, so do not rename
anything on the CV for this.

**Status 2026-09-19:** all eight years exported by Peter; every needed journal-year has a JIF except two
genuine gaps (Current Opinion in Psychology and Frontiers in Sociology were emerging-sources journals in
JCR 2018 and had no JIF; the builder uses the nearest available year and flags it). The files also carry
"International Journal of Environmental Research" (Springer, 1735-6865), selected by mistake; it is not
IJERPH (MDPI, 1660-4601) and the builder ignores it. Layout: one preamble line, blank, header
(`Journal name, JCR Abbreviation, Publisher, ISSN, eISSN, Category, Edition, Total Citations, <year> JIF,
JIF Quartile, <year> JCI, % of Citable OA`), one row per journal x category (JIF repeats), trailing comma,
two footer lines. The OA cell is written `"53.07"%` (quote then percent), which trips strict CSV readers.

List generated 2026-09-19 from `articles.yml`; regenerate when a paper lands in a new venue.
