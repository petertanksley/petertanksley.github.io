# Plan: achievements on the site (numeral, page, landing card, panel)

**Status:** COMPLETED 2026-09-20 (Peter: gold numeral; career achievements on the origin hex; achievements stay
separate from the news stream, homepage shows the single latest; page under the Research menu).

## Approach

The ledger `5_skilltree/data/achievements_log.yml` is the only source. Every surface reads it, none reads the rules.

1. **Checker** (`check_achievements.R`): write a `key` (`<id>-<date>`) per entry for anchors; add `--replay`, which
   rebuilds the ledger from every consecutive snapshot pair, so a wording edit in the rules is one rerun away.
2. **Builder** (`build_tree.R`): read the ledger; per node `achievements {n, best, items[]}`; career entries (no
   `article`) go on `meta.origin.achievements`; `meta.achievements {label, page}` for legend and links.
3. **Tree** (`www/skilltree.js`, `theme.scss`): a gold roman numeral on the lower-left edge, mirroring the pips on
   the upper-right; same on the origin at its scale. Panel gains an Achievements section (tier chip + title, each
   linking to `achievements.html#<key>`); the character sheet gains the same for career achievements; the stats
   card gains a fourth figure; the legend gains the numeral. Bump `?v=`.
4. **Page** (`achievements.qmd` + `achievements-listing.ejs`): dark end to end like the tree; a Quarto listing
   over the ledger; entries as system messages (header, title, body, Reward line) grouped by snapshot date.
5. **Landing** (`index.qmd` + `achievement-home.ejs`): a second listing, max-items 1, rendered as a single dark
   system-message card under News, linking to the page. `news.yml` untouched.
6. **Nav** (`_quarto.yml`): Achievements after Skill tree.
7. **Refresh wrapper** (`5_skilltree/R/refresh.R`): fetch → check `--log` → build_tree, in order.
8. Run the refresh for real (first fire, flood logged on purpose), render, verify in headless Chrome, commit.
9. Docs: CLAUDE.md achievements section, bob.md, session log.

## Verification

- `Rscript` each script from the repo root without error; ledger entries carry `key`, `article` where relevant.
- `quarto render`; achievements page and homepage card render from the ledger; nav entry present.
- Headless Chrome over a local server: numerals at rest on the tree and origin; panel section; sheet section;
  stats card; achievements page; homepage card.
- `--replay` reproduces the ledger byte-for-byte.
