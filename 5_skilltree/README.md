# 5_skilltree — the publication skill tree generator

R thinks, JS draws. `data/articles.yml` is the source of truth (30 articles, all rated by Peter).

```bash
# from the site repo root
Rscript 5_skilltree/R/extract_cv.R     # refresh bibliographic fields from 2_cv/tanksley_cv.qmd (keeps ratings)
Rscript 5_skilltree/R/build_tree.R     # validate, lay out the hex rings, write www/tree.json + www/hex/sm/
Rscript -e 'shiny::runApp("5_skilltree/tools/rate_articles", launch.browser = TRUE)'   # rate/edit articles
quarto preview                          # skilltree.qmd renders with the rest of the site
```

```bash
Rscript 5_skilltree/R/build_journals.R          # data/jcr/*.csv (JCR exports) -> data/journals.yml (impact factors by JCR year)
Rscript 5_skilltree/R/render_cv_pubs.R          # write 2_cv/_publications.qmd — the CV's publication block
Rscript 5_skilltree/R/add_article.R <DOI>       # CrossRef → new YAML entry (add --dry-run to preview)
```

`www/tree.json`, `www/hex/sm/` and `2_cv/_publications.qmd` are **committed** so CI can render
without R, like `_hexband.qmd`. **Adding a paper:** `add_article.R <DOI>` → fix Title Case / middle
initial in the YAML → rate it in the app → `build_tree.R` + `render_cv_pubs.R` → commit. The
extractor is now a migration tool only (it reads the generated include).

Impact-factor pips read `data/journals.yml`, generated from the raw JCR exports in `data/jcr/` (see its README);
rerun `build_journals.R` then `build_tree.R` after adding an export.

Conventions live in the repo `CLAUDE.md` (Skill tree section). Plan and history:
`logs/skilltree/`. Built 2026-09-07/09 in the (now archived) `PROJ_skill_tree` repo.
