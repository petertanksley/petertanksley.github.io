# fetch_scholar.R — pull Peter's citation metrics and write www/scholar.json (+ a dated snapshot).
#
# Google Scholar has no API; this reads the PUBLIC profile page. It runs LOCALLY (Scholar blocks
# datacenter IPs, and CI has no R), by hand, whenever the numbers should refresh; commit the outputs
# like www/tree.json. Expect the occasional block: the script then falls back to the previous
# snapshot's Scholar block and says so. OpenAlex (open API, by ORCID) is fetched alongside as the
# reliable cross-check and for per-article counts by DOI.
#
# Outputs (both committed):
#   www/scholar.json                          what the skill-tree page reads (declared in _quarto.yml resources)
#   5_skilltree/data/scholar/YYYY-MM-DD.json  dated snapshot; check_achievements.R diffs the newest two
#
# Usage (from repo root):  Rscript 5_skilltree/R/fetch_scholar.R [--dry-run] [--no-openalex]

suppressPackageStartupMessages({
  library(here); library(httr2); library(rvest); library(yaml); library(jsonlite); library(purrr); library(stringr)
})
if (!requireNamespace("scholar", quietly = TRUE)) install.packages("scholar", repos = "https://cloud.r-project.org")

args     <- commandArgs(trailingOnly = TRUE)
dry_run  <- "--dry-run" %in% args
no_oa    <- "--no-openalex" %in% args

SCHOLAR_ID <- "YnIBrB8AAAAJ"
ORCID      <- "0000-0002-3449-2838"
MAILTO     <- "peter_tanksley@txstate.edu"
UA         <- "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128 Safari/537.36"
OUT_JSON   <- here("www", "scholar.json")
SNAP_DIR   <- here("5_skilltree", "data", "scholar")
ARTICLES   <- here("5_skilltree", "data", "articles.yml")
today      <- format(Sys.Date(), "%Y-%m-%d")

# ---- Google Scholar ------------------------------------------------------------------------------
# The profile page carries the stats table (#gsc_rsb_st: citations / h / i10, each all-time and
# since-5y), the citations-per-year bars, and the first 20 publications. The scholar package pages
# through all publications; the raw parse is the fallback if it breaks.
scholar_page <- function() {
  r <- request(sprintf("https://scholar.google.com/citations?user=%s&hl=en&cstart=0&pagesize=100", SCHOLAR_ID)) |>
    req_headers(`User-Agent` = UA, `Accept-Language` = "en-US,en;q=0.9") |> req_perform()
  html <- resp_body_string(r)
  if (grepl("unusual traffic|/sorry/", html)) stop("Google Scholar is rate-limiting this address")
  read_html(html)
}
parse_stats <- function(h) {
  v <- h |> html_elements("#gsc_rsb_st td.gsc_rsb_std") |> html_text() |> as.integer()
  if (length(v) != 6) stop("stats table not found (page layout changed?)")
  list(citations = v[1], citations_5y = v[2], h_index = v[3], h_index_5y = v[4], i10 = v[5], i10_5y = v[6])
}
parse_history <- function(h) {
  yrs <- h |> html_elements(".gsc_g_t") |> html_text() |> as.integer()
  n   <- h |> html_elements(".gsc_g_al") |> html_text() |> as.integer()
  if (length(yrs) && length(yrs) == length(n)) map2(yrs, n, ~ list(year = .x, cites = .y)) else list()
}
parse_pubs_raw <- function(h) {
  rows <- h |> html_elements(".gsc_a_tr")
  data.frame(title = rows |> html_element(".gsc_a_at") |> html_text(),
             year  = rows |> html_element(".gsc_a_y") |> html_text() |> as.integer(),
             cites = rows |> html_element(".gsc_a_c") |> html_text() |> str_remove("\\*") |> as.integer(),
             stringsAsFactors = FALSE)
}
fetch_scholar <- function() {
  h <- scholar_page()
  stats <- parse_stats(h); hist <- parse_history(h)
  pubs <- tryCatch(
    { p <- scholar::get_publications(SCHOLAR_ID, flush = TRUE); data.frame(title = p$title, year = p$year, cites = p$cites, stringsAsFactors = FALSE) },
    error = function(e) { message("scholar::get_publications failed (", conditionMessage(e), "); using the profile page's rows"); parse_pubs_raw(h) })
  pubs$cites[is.na(pubs$cites)] <- 0L
  list(stats = stats, history = hist, pubs = pubs)
}

# ---- OpenAlex --------------------------------------------------------------------------------------
oa_get <- function(url) request(url) |> req_url_query(mailto = MAILTO) |>
  req_headers(`User-Agent` = sprintf("tanksley-skilltree/1.0 (mailto:%s)", MAILTO)) |> req_perform() |> resp_body_json()
fetch_openalex <- function(dois) {
  a <- oa_get(sprintf("https://api.openalex.org/authors/https://orcid.org/%s", ORCID))
  by_year <- map(a$counts_by_year, ~ list(year = .x$year, cites = .x$cited_by_count, works = .x$works_count))
  per_doi <- list()
  dois <- tolower(dois[!is.na(dois) & nzchar(dois)])
  for (chunk in split(dois, ceiling(seq_along(dois) / 40))) {
    w <- oa_get(paste0("https://api.openalex.org/works?per-page=50&select=doi,cited_by_count&filter=doi:", paste(chunk, collapse = "|")))
    for (r in w$results) per_doi[[str_remove(tolower(r$doi), "^https://doi.org/")]] <- r$cited_by_count
  }
  list(summary = list(id = a$id, works = a$works_count, citations = a$cited_by_count,
                      h_index = a$summary_stats$h_index, i10 = a$summary_stats$i10_index, by_year = by_year),
       per_doi = per_doi)
}

# ---- match Scholar rows to articles.yml --------------------------------------------------------------
norm <- function(x) x |> str_to_lower() |> stringi::stri_trans_general("Latin-ASCII") |> str_replace_all("[^a-z0-9 ]", " ") |> str_squish()
match_articles <- function(arts, pubs) {
  pn <- norm(pubs$title); used <- rep(FALSE, nrow(pubs))
  out <- list(); unmatched_art <- character()
  for (a in arts) {
    an <- norm(a$title)
    hit <- which(!used & pn == an)
    if (!length(hit)) {                                    # fuzzy: word-set overlap (Jaccard), year within 1
      # Scholar titles drift: an inserted word, "UK" for "United Kingdom", a trailing ": PT Tanksley et al."
      # Edit distance punishes all of those; shared-word overlap does not.
      aw <- unique(str_split_1(an, " "))
      jac <- map_dbl(pn, function(t) { tw <- unique(str_split_1(t, " ")); length(intersect(aw, tw)) / length(union(aw, tw)) })
      ok <- !used & jac >= 0.6 & (is.na(pubs$year) | abs(pubs$year - a$year) <= 1) & !str_detect(pn, "^(correction|corrigendum)")
      if (any(ok)) hit <- which(ok)[which.max(jac[ok])]
    }
    if (length(hit)) { used[hit[1]] <- TRUE; out[[a$id]] <- pubs$cites[hit[1]] } else unmatched_art <- c(unmatched_art, a$id)
  }
  list(cites = out, unmatched_articles = unmatched_art, unmatched_scholar = pubs$title[!used])
}

# ---- run -------------------------------------------------------------------------------------------
arts <- read_yaml(ARTICLES); ids <- map_chr(arts, "id")
prev_files <- sort(list.files(SNAP_DIR, pattern = "^\\d{4}-\\d{2}-\\d{2}\\.json$", full.names = TRUE))
prev <- if (length(prev_files)) read_json(tail(prev_files, 1)) else NULL

sch <- tryCatch(fetch_scholar(), error = function(e) {
  warning("Google Scholar fetch FAILED: ", conditionMessage(e), if (!is.null(prev)) "; keeping the previous snapshot's Scholar block" else "", call. = FALSE)
  NULL
})
oa <- if (no_oa) NULL else tryCatch(fetch_openalex(map_chr(arts, ~ .x$doi %||% NA_character_)),
                                    error = function(e) { warning("OpenAlex fetch failed: ", conditionMessage(e), call. = FALSE); NULL })

m <- if (!is.null(sch)) match_articles(arts, sch$pubs) else NULL
articles <- set_names(map(arts, function(a) {
  s  <- if (!is.null(m)) m$cites[[a$id]] else if (!is.null(prev)) prev$articles[[a$id]]$scholar else NULL
  o  <- if (!is.null(oa) && !is.null(a$doi)) oa$per_doi[[tolower(a$doi)]] else NULL
  list(scholar = s, openalex = o)
}), ids)

out <- list(
  meta = list(fetched = format(Sys.time(), "%Y-%m-%d %H:%M"), scholar_id = SCHOLAR_ID, orcid = ORCID,
              sources = list(scholar = if (!is.null(sch)) "live" else if (!is.null(prev)) paste("snapshot", prev$meta$fetched) else "unavailable",
                             openalex = if (!is.null(oa)) "live" else "unavailable")),
  scholar  = if (!is.null(sch)) c(sch$stats, list(by_year = sch$history)) else prev$scholar,
  openalex = if (!is.null(oa)) oa$summary else prev$openalex,
  articles = articles
)

# ---- report ----------------------------------------------------------------------------------------
fmt <- function(x) if (is.null(x)) "-" else format(x)
cat(sprintf("Google Scholar (%s): %s citations (%s since 5y), h %s (%s), i10 %s (%s)\n", out$meta$sources$scholar,
            fmt(out$scholar$citations), fmt(out$scholar$citations_5y), fmt(out$scholar$h_index), fmt(out$scholar$h_index_5y), fmt(out$scholar$i10), fmt(out$scholar$i10_5y)))
cat(sprintf("OpenAlex (%s): %s works, %s citations, h %s, i10 %s\n", out$meta$sources$openalex,
            fmt(out$openalex$works), fmt(out$openalex$citations), fmt(out$openalex$h_index), fmt(out$openalex$i10)))
if (!is.null(m)) {
  cat(sprintf("matched %d of %d articles to Scholar rows\n", length(m$cites), length(arts)))
  if (length(m$unmatched_articles)) cat("  articles with no Scholar row:", paste(m$unmatched_articles, collapse = ", "), "\n")
  if (length(m$unmatched_scholar))  cat("  Scholar rows not in articles.yml:\n", paste0("   - ", substr(m$unmatched_scholar, 1, 90), "\n"), sep = "")
}
cat(sprintf("%-34s %8s %8s\n", "id", "scholar", "openalex"))
for (id in ids) cat(sprintf("%-34s %8s %8s\n", id, fmt(articles[[id]]$scholar), fmt(articles[[id]]$openalex)))

if (dry_run) { cat("\n--dry-run: nothing written\n"); quit(save = "no") }
if (is.null(out$scholar) && is.null(out$openalex)) stop("nothing fetched and no snapshot to fall back on; not writing")
dir.create(SNAP_DIR, showWarnings = FALSE, recursive = TRUE)
js <- toJSON(out, auto_unbox = TRUE, pretty = TRUE, null = "null", na = "null")
writeLines(js, OUT_JSON); writeLines(js, file.path(SNAP_DIR, paste0(today, ".json")))
cat(sprintf("\nwrote %s and %s\n", OUT_JSON, file.path(SNAP_DIR, paste0(today, ".json"))))
