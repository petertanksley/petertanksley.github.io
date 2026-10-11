# fetch_scholar.R — pull Peter's citation metrics and write www/scholar.json (+ a dated snapshot).
#
# Google Scholar has no API; this reads the PUBLIC profile page. It runs LOCALLY (Scholar blocks
# datacenter IPs, and CI has no R), by hand, whenever the numbers should refresh; commit the outputs
# like www/tree.json. Expect the occasional block: the script then falls back to the previous
# snapshot's Scholar block and says so. Scholar only: OpenAlex was dropped 2026-10-10 (Peter), along with
# the percentile achievement it fed; Necromancy reads Scholar's per-paper histogram instead.
#
# Outputs (both committed):
#   www/scholar.json                          what the skill-tree page reads (declared in _quarto.yml resources)
#   5_skilltree/data/scholar/YYYY-MM-DD.json  dated snapshot; check_achievements.R diffs the newest two
#
# Usage (from repo root):  Rscript 5_skilltree/R/fetch_scholar.R [--dry-run]

suppressPackageStartupMessages({
  library(here); library(httr2); library(rvest); library(yaml); library(jsonlite); library(purrr); library(stringr)
})
if (!requireNamespace("scholar", quietly = TRUE)) install.packages("scholar", repos = "https://cloud.r-project.org")

args     <- commandArgs(trailingOnly = TRUE)
dry_run  <- "--dry-run" %in% args

SCHOLAR_ID <- "YnIBrB8AAAAJ"
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
             pubid = rows |> html_element(".gsc_a_at") |> html_attr("href") |> str_extract("(?<=:)[^:&]+$"),
             year  = rows |> html_element(".gsc_a_y") |> html_text() |> as.integer(),
             cites = rows |> html_element(".gsc_a_c") |> html_text() |> str_remove("\\*") |> as.integer(),
             stringsAsFactors = FALSE)
}
fetch_scholar <- function() {
  h <- scholar_page()
  stats <- parse_stats(h); hist <- parse_history(h)
  pubs <- tryCatch(
    { p <- scholar::get_publications(SCHOLAR_ID, flush = TRUE); data.frame(title = p$title, pubid = p$pubid, year = p$year, cites = p$cites, stringsAsFactors = FALSE) },
    error = function(e) { message("scholar::get_publications failed (", conditionMessage(e), "); using the profile page's rows"); parse_pubs_raw(h) })
  pubs$cites[is.na(pubs$cites)] <- 0L
  list(stats = stats, history = hist, pubs = pubs)
}

# ---- match Scholar rows to articles.yml --------------------------------------------------------------
norm <- function(x) x |> str_to_lower() |> stringi::stri_trans_general("Latin-ASCII") |> str_replace_all("[^a-z0-9 ]", " ") |> str_squish()
match_articles <- function(arts, pubs) {
  pn <- norm(pubs$title); used <- rep(FALSE, nrow(pubs))
  out <- list(); pubid <- list(); unmatched_art <- character()
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
    if (length(hit)) { used[hit[1]] <- TRUE; out[[a$id]] <- pubs$cites[hit[1]]; pubid[[a$id]] <- pubs$pubid[hit[1]] }
    else unmatched_art <- c(unmatched_art, a$id)
  }
  list(cites = out, pubid = pubid, unmatched_articles = unmatched_art, unmatched_scholar = pubs$title[!used])
}

# ---- run -------------------------------------------------------------------------------------------
arts <- read_yaml(ARTICLES); ids <- map_chr(arts, "id")
prev_files <- sort(list.files(SNAP_DIR, pattern = "^\\d{4}-\\d{2}-\\d{2}\\.json$", full.names = TRUE))
prev <- if (length(prev_files)) read_json(tail(prev_files, 1)) else NULL

# ---- career counts (2026-10-03) --------------------------------------------------------------------
# Cumulative counts for the career ladders in achievements.yml. articles = CV-numbered articles in articles.yml
# (published + in press; preprints carry no cv_number). reviews = rows of the /bob review card's ## Archive table, one
# per submitted round. Only counts go into the (public) snapshot.
career_cfg <- read_yaml(here("5_skilltree", "data", "career.yml"))
count_reviews <- function() {
  f <- path.expand(career_cfg$review_archive %||% "")
  if (!nzchar(f) || !file.exists(f)) {
    warning("review archive not found (", f, "); keeping the previous snapshot's review count", call. = FALSE)
    return(prev$career$reviews)
  }
  L <- readLines(f, warn = FALSE)
  start <- which(str_detect(L, "^## Archive")); if (!length(start)) { warning("no ## Archive in ", f, call. = FALSE); return(prev$career$reviews) }
  end <- c(which(str_detect(L, "^## ")), length(L) + 1); end <- min(end[end > start[1]])
  arch <- L[seq(start[1], end - 1)]
  rows <- arch[str_detect(arch, "^\\|") & !str_detect(arch, "^\\|\\s*ID\\s*\\|") & !str_detect(arch, "^\\|[-\\s|]+$")]
  length(rows)                                            # one table row per submitted round
}
career <- list(articles = sum(map_lgl(arts, ~ !is.null(.x$cv_number))), reviews = count_reviews())

sch <- tryCatch(fetch_scholar(), error = function(e) {
  warning("Google Scholar fetch FAILED: ", conditionMessage(e), if (!is.null(prev)) "; keeping the previous snapshot's Scholar block" else "", call. = FALSE)
  NULL
})

m <- if (!is.null(sch)) match_articles(arts, sch$pubs) else NULL

# ---- per-article citations by year (2026-10-04) ------------------------------------------------------
# Scholar's own per-paper histogram (one request per paper), for the bar chart in the skill-tree panel. Only papers
# whose count moved since the previous snapshot are re-fetched; the rest reuse it, so a routine refresh costs a
# handful of requests. Paced, and two failures in a row stop the run (Scholar is blocking): those papers keep the
# previous snapshot's bars. Uncited papers get {} without a request. Since 2026-10-10 this also feeds Necromancy
# (check_achievements.R), so a histogram must never go stale silently: scholar_by_year_n records the paper's count
# when its histogram was fetched, and a paper whose count has moved past that is re-fetched on the next run even if
# the count did not move since the previous snapshot (i.e. after a run where the fetch failed).
prev_sby <- function(id) if (!is.null(prev)) prev$articles[[id]]$scholar_by_year else NULL
prev_sby_n <- function(id) if (!is.null(prev)) prev$articles[[id]]$scholar_by_year_n %||% prev$articles[[id]]$scholar else NULL
scholar_by_year <- list(); scholar_by_year_n <- list()
if (!is.null(m)) {
  fails <- 0L; fetched <- 0L
  for (id in names(m$cites)) {
    n <- m$cites[[id]]; old <- prev_sby(id)
    if (is.na(n) || n == 0) { scholar_by_year[[id]] <- setNames(list(), character()); scholar_by_year_n[[id]] <- 0L; next }
    if (!is.null(old) && identical(as.integer(n), as.integer(prev_sby_n(id)))) { scholar_by_year[[id]] <- old; scholar_by_year_n[[id]] <- as.integer(n); next }
    if (fails >= 2 || is.na(m$pubid[[id]] %||% NA)) { scholar_by_year[[id]] <- old; scholar_by_year_n[[id]] <- prev_sby_n(id); next }
    Sys.sleep(runif(1, 2, 5))
    h <- tryCatch(scholar::get_article_cite_history(SCHOLAR_ID, m$pubid[[id]]), error = function(e) NULL)
    if (is.null(h)) { fails <- fails + 1L; scholar_by_year[[id]] <- old; scholar_by_year_n[[id]] <- prev_sby_n(id); next }
    fails <- 0L; fetched <- fetched + 1L
    scholar_by_year[[id]] <- as.list(setNames(as.integer(h$cites), h$year)); scholar_by_year_n[[id]] <- as.integer(n)
  }
  cat(sprintf("per-article history: %d fetched from Scholar%s\n", fetched,
              if (fails >= 2) "; STOPPED after repeated failures, the rest keep the previous snapshot's bars" else ""))
}
# lineage (2026-09-20): for a paper that builds on none of Peter's earlier work, the number of papers downstream of it
# (children, grandchildren ...); 0 for anything that itself has a builds_on. Static data from articles.yml, carried
# in the snapshot so check_achievements.R can diff it like any other metric (the "Founder" rule).
kids <- map(set_names(ids), function(id) ids[map_lgl(arts, ~ id %in% (.x$builds_on %||% character()))])
descendants <- function(id, seen = character()) { k <- setdiff(kids[[id]], seen); if (!length(k)) return(character())
  unique(c(k, unlist(lapply(k, descendants, seen = c(seen, k))))) }
lineage <- map_int(set_names(ids), ~ if (length(arts[[match(.x, ids)]]$builds_on)) 0L else length(descendants(.x)))
articles <- set_names(map(arts, function(a) {
  s  <- if (!is.null(m)) m$cites[[a$id]] else if (!is.null(prev)) prev$articles[[a$id]]$scholar else NULL
  # {} (never cited) is data and differs from null (not matched to a Scholar row): a paper never cited in three
  # years is dormant too, and its first citation raises it
  sby   <- if (!is.null(m)) scholar_by_year[[a$id]] else prev_sby(a$id)
  sby_n <- if (!is.null(m)) scholar_by_year_n[[a$id]] else if (!is.null(prev)) prev$articles[[a$id]]$scholar_by_year_n else NULL
  list(scholar = s, scholar_by_year = sby, scholar_by_year_n = sby_n, lineage = lineage[[a$id]])
}), ids)

out <- list(
  meta = list(fetched = format(Sys.time(), "%Y-%m-%d %H:%M"), scholar_id = SCHOLAR_ID,
              sources = list(scholar = if (!is.null(sch)) "live" else if (!is.null(prev)) paste("snapshot", prev$meta$fetched) else "unavailable")),
  scholar  = if (!is.null(sch)) c(sch$stats, list(by_year = sch$history)) else prev$scholar,
  articles = articles,
  career   = career
)

# ---- report ----------------------------------------------------------------------------------------
fmt <- function(x) if (is.null(x)) "-" else format(x)
cat(sprintf("Google Scholar (%s): %s citations (%s since 5y), h %s (%s), i10 %s (%s)\n", out$meta$sources$scholar,
            fmt(out$scholar$citations), fmt(out$scholar$citations_5y), fmt(out$scholar$h_index), fmt(out$scholar$h_index_5y), fmt(out$scholar$i10), fmt(out$scholar$i10_5y)))
if (!is.null(m)) {
  cat(sprintf("matched %d of %d articles to Scholar rows\n", length(m$cites), length(arts)))
  if (length(m$unmatched_articles)) cat("  articles with no Scholar row:", paste(m$unmatched_articles, collapse = ", "), "\n")
  if (length(m$unmatched_scholar))  cat("  Scholar rows not in articles.yml:\n", paste0("   - ", substr(m$unmatched_scholar, 1, 90), "\n"), sep = "")
}
cat(sprintf("%-34s %8s\n", "id", "scholar"))
for (id in ids) cat(sprintf("%-34s %8s\n", id, fmt(articles[[id]]$scholar)))

cat(sprintf("career: %s articles, %s reviews\n", fmt(career$articles), fmt(career$reviews)))
if (dry_run) { cat("\n--dry-run: nothing written\n"); quit(save = "no") }
if (is.null(out$scholar)) stop("nothing fetched and no snapshot to fall back on; not writing")
dir.create(SNAP_DIR, showWarnings = FALSE, recursive = TRUE)
js <- toJSON(out, auto_unbox = TRUE, pretty = TRUE, null = "null", na = "null")
writeLines(js, OUT_JSON); writeLines(js, file.path(SNAP_DIR, paste0(today, ".json")))
cat(sprintf("\nwrote %s and %s\n", OUT_JSON, file.path(SNAP_DIR, paste0(today, ".json"))))
