# build_journals.R — read the Journal Citation Reports exports in 5_skilltree/data/jcr/ and write
# 5_skilltree/data/journals.yml: one record per venue string in articles.yml, carrying the Clarivate
# Journal Impact Factor (JIF) and best quartile by JCR year.
#
# The JIF is proprietary: there is no free API and no free historic series (scholar::get_impactfactor
# was removed in 1.0.0; Scimago's 2-year cites/doc runs far below JIF for high-JIF journals — see
# logs/skilltree/plans/2026-09-19_impact-factor-badges.md). So the source is the JCR web portal via
# the Texas State library: filter to the journals, export one CSV per JCR year, drop it here as
# data/jcr/jcr_<year>*.csv. Every file in that folder is read; the JCR year comes from the
# "<year> JIF" column header, so several files per year are fine.
#
# Matching: venue strings are normalised (lower-case, "&" -> "and", leading "The" and punctuation
# dropped) and compared with the JCR "Journal name". Two venues are spelled differently on the CV
# and need ALIASES below. Anything in the exports that matches no venue is reported and ignored
# (Peter's 2026-09-19 exports carry "International Journal of Environmental Research", a Springer
# journal picked by mistake for IJERPH).
#
# Run from the site repo root:  Rscript 5_skilltree/R/build_journals.R
# Then:                          Rscript 5_skilltree/R/build_tree.R   (reads journals.yml)

suppressPackageStartupMessages({ library(here); library(yaml); library(purrr) })

JCR_DIR   <- here("5_skilltree", "data", "jcr")
ARTICLES  <- here("5_skilltree", "data", "articles.yml")
OUT       <- here("5_skilltree", "data", "journals.yml")
PREPRINTS <- c("BioRxiv", "MedRxiv")            # venues that are not journals; get a record with no jif
ALIASES   <- c(                                  # articles.yml venue -> JCR journal name
  "Nature Human Behavior" = "Nature Human Behaviour",
  "Frontiers of Sociology" = "Frontiers in Sociology"
)

norm <- function(s) {
  s <- tolower(s); s <- gsub("&", " and ", s, fixed = TRUE); s <- sub("^\\s*the\\s+", "", s)
  gsub("[^a-z0-9]", "", s)
}

# ---- read the exports ---------------------------------------------------------------------------
# Layout: one preamble line, a blank, the header, one row per journal x category (the JIF repeats),
# a trailing comma on every row, two footer lines. The OA cell is written "53.07"% (quote, then
# percent), which breaks strict CSV parsing; move the % inside the quotes before reading.
read_jcr <- function(f) {
  l <- readLines(f, warn = FALSE, encoding = "UTF-8"); l <- sub("^﻿", "", l)
  h <- grep("^Journal name,", l); if (length(h) != 1) stop(basename(f), ": header line not found")
  year <- as.integer(sub(".*\\b(\\d{4}) JIF\\b.*", "\\1", l[h]))
  body <- l[h:length(l)]; body <- body[nzchar(trimws(body)) & !grepl("^(Copyright|By exporting)", body)]
  body <- gsub('"%', '%"', body, fixed = TRUE)
  body <- sub(',\\s*$', '', body)                                  # trailing comma on every data row -> read.table would take col 1 as row names
  d <- read.csv(text = body, check.names = FALSE, stringsAsFactors = FALSE, na.strings = c("N/A", ""))
  jif_col <- grep(" JIF$", names(d), value = TRUE)
  data.frame(year = year, title = d[["Journal name"]], issn = d[["ISSN"]], eissn = d[["eISSN"]],
             publisher = d[["Publisher"]], jif = suppressWarnings(as.numeric(d[[jif_col]])),
             quartile = d[["JIF Quartile"]], file = basename(f), stringsAsFactors = FALSE)
}
files <- sort(list.files(JCR_DIR, pattern = "^jcr_.*\\.csv$", full.names = TRUE))
if (!length(files)) stop("no jcr_*.csv exports in ", JCR_DIR)
jcr <- do.call(rbind, lapply(files, read_jcr))
jcr$key <- norm(jcr$title)
retrieved <- format(max(file.mtime(files)), "%Y-%m-%d")

# one row per journal x year: the JIF is identical across a journal's categories; keep the best quartile
best_q <- function(q) { q <- q[!is.na(q)]; if (!length(q)) NA_character_ else sort(q)[1] }
jy <- split(jcr, list(jcr$key, jcr$year), drop = TRUE)
jy <- do.call(rbind, lapply(jy, function(g) data.frame(
  key = g$key[1], year = g$year[1], title = g$title[1], issn = g$issn[1], eissn = g$eissn[1], publisher = g$publisher[1],
  jif = g$jif[1], quartile = best_q(g$quartile), stringsAsFactors = FALSE)))
jy <- jy[order(jy$key, jy$year), ]

# ---- match to venues ----------------------------------------------------------------------------
arts   <- read_yaml(ARTICLES)
venues <- unique(map_chr(arts, "venue"))
matched_keys <- character()
records <- lapply(venues, function(v) {
  if (v %in% PREPRINTS) return(list(venue = v, journal = FALSE, note = "preprint server; no impact factor"))
  key <- norm(if (v %in% names(ALIASES)) ALIASES[[v]] else v)
  rows <- jy[jy$key == key, ]
  if (!nrow(rows)) { warning("no JCR rows for venue '", v, "' (looked for '", key, "')", call. = FALSE); return(list(venue = v, journal = TRUE, jif = NULL, note = "not found in the JCR exports")) }
  matched_keys <<- c(matched_keys, key)
  yrs <- as.character(rows$year); jif <- as.list(rows$jif); q <- as.list(rows$quartile)
  list(venue = v, journal = TRUE, jcr_title = rows$title[nrow(rows)], issn = rows$issn[nrow(rows)], eissn = rows$eissn[nrow(rows)],
       publisher = rows$publisher[nrow(rows)],
       jif = setNames(lapply(jif, function(x) if (is.na(x)) NULL else x), yrs),
       quartile = setNames(lapply(q, function(x) if (is.na(x)) NULL else x), yrs),
       source = sprintf("Journal Citation Reports (Clarivate) via the Texas State library; exports in 5_skilltree/data/jcr/, retrieved %s", retrieved))
})
records <- records[order(map_chr(records, "venue"))]
stray <- unique(jy$title[!jy$key %in% matched_keys])

# ---- write --------------------------------------------------------------------------------------
header <- c(
  "# data/journals.yml — GENERATED by 5_skilltree/R/build_journals.R from the JCR exports in data/jcr/; do not edit by hand.",
  "# One record per venue string in articles.yml. jif / quartile are keyed by JCR year (Clarivate Journal Impact",
  "# Factor and best category quartile). A missing year means the journal had no JIF that year (emerging-sources",
  "# journals before JCR 2022) or was not in the export. build_tree.R reads the JCR year before the article's year.",
  sprintf("# Built %s from %d file(s): %s", format(Sys.time(), "%Y-%m-%d %H:%M"), length(files), paste(basename(files), collapse = ", ")),
  ""
)
writeLines(c(header, as.yaml(records, indent.mapping.sequence = TRUE)), OUT)

n_j <- sum(map_lgl(records, ~ isTRUE(.x$journal) && length(.x$jif) > 0))
cat(sprintf("%s: %d venues; %d journals with JIF data, %d preprint servers, %d unmatched\n", OUT, length(records), n_j,
            sum(!map_lgl(records, "journal")), length(records) - n_j - sum(!map_lgl(records, "journal"))))
cat(sprintf("JCR years read: %s\n", paste(sort(unique(jcr$year)), collapse = ", ")))
if (length(stray)) cat("ignored (in the exports, not a venue):", paste(stray, collapse = "; "), "\n")
for (r in records) if (isTRUE(r$journal) && length(r$jif))
  cat(sprintf("  %-72s %s\n", r$venue, paste(sprintf("%s=%s", names(r$jif), map_chr(r$jif, ~ if (is.null(.x)) "NA" else format(.x))), collapse = " ")))
