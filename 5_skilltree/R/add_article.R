# add_article.R — add a publication to articles.yml from its DOI, via CrossRef.
#
#   Rscript 5_skilltree/R/add_article.R 10.1016/j.lana.2025.101270            # append
#   Rscript 5_skilltree/R/add_article.R 10.1016/j.lana.2025.101270 --dry-run  # print the entry, write nothing
#
# Fills the bibliographic fields (title, year, venue, doi, citation, authors, authors_cv with the
# first author inverted and Peter in bold, position, count) and leaves every judgement field null for
# the rating app. Then: rate it, `Rscript 5_skilltree/R/build_tree.R`, `render_cv_pubs.R`, commit.
# What CrossRef gets wrong, every time, and you fix in the YAML before rendering: titles arrive in
# Title Case (the CV uses sentence case), author names lack middle initials ("Peter Tanksley", not
# "Peter T. Tanksley"), and a paper that is online-first has no volume yet (set citation: online first).

suppressPackageStartupMessages({ library(here); library(httr2); library(yaml); library(purrr); library(stringr) })
source(here("5_skilltree", "tools", "rate_articles", "helpers.R"))

args <- commandArgs(trailingOnly = TRUE)
dry  <- "--dry-run" %in% args; args <- setdiff(args, "--dry-run")
if (length(args) != 1) stop("usage: Rscript 5_skilltree/R/add_article.R <DOI> [--dry-run]")
doi <- str_replace(str_trim(args[1]), "^https?://(dx\\.)?doi\\.org/", "")

msg <- request(paste0("https://api.crossref.org/works/", doi)) |>
  req_headers(`User-Agent` = "tanksley-skilltree/1.0 (mailto:peter_tanksley@txstate.edu)") |>
  req_perform() |> resp_body_json() |> pluck("message")

# ---- names ----------------------------------------------------------------------------------
# CrossRef gives given/family; the CV prints "Given Family" except the first author, "Family, Given",
# and Peter bold wherever he sits. Initials keep their periods ("J.C.", "M. Hunter").
natural  <- function(a) str_squish(paste(a$given %||% "", a$family %||% ""))
inverted <- function(a) str_squish(paste0(a$family %||% "", ", ", a$given %||% ""))
is_peter <- function(a) str_detect(a$family %||% "", "Tanksley")
au <- msg$author %||% list()
if (!length(au)) stop("CrossRef has no author list for ", doi)
nat <- map_chr(au, natural)
cv_names <- c(inverted(au[[1]]), if (length(au) > 1) map_chr(au[-1], natural))
cv_names[map_lgl(au, is_peter)] <- paste0("**", cv_names[map_lgl(au, is_peter)], "**")
authors_cv <- if (length(cv_names) == 1) paste0(cv_names, ".") else
  paste0(paste(head(cv_names, -1), collapse = ", "), ", & ", tail(cv_names, 1), ".")

# ---- bibliographic fields -------------------------------------------------------------------
title <- str_squish(str_replace_all(msg$title[[1]], "<[^>]+>", ""))
title <- str_replace(title, "\\.$", "")
year  <- (msg$`published-print`$`date-parts`[[1]][[1]] %||% msg$`published-online`$`date-parts`[[1]][[1]] %||% msg$issued$`date-parts`[[1]][[1]])
venue <- msg$`container-title`[[1]] %||% NA
vol <- msg$volume %||% NULL; iss <- msg$issue %||% NULL; pg <- msg$page %||% NULL
citation <- if (!is.null(vol)) paste0(vol, if (!is.null(iss)) sprintf(" (%s)", iss), if (!is.null(pg)) paste0(", ", pg)) else NULL
if (!is.null(citation) && is.null(pg) && !is.null(msg$`article-number`)) citation <- paste0(citation, ", ", msg$`article-number`)

d <- read_articles(here("5_skilltree", "data", "articles.yml"))
dup <- any(map_lgl(d$entries, ~ identical(.x$doi, doi)))
if (dup && !dry) stop("DOI already in articles.yml: ", doi)
if (dup) message("note: DOI already in articles.yml — dry run continues so you can compare the shape")
cv_number <- max(map_int(d$entries, ~ .x$cv_number %||% 0L)) + 1L
first_last <- str_extract(au[[1]]$family, "[A-Za-z\\-]+$")
words <- str_split(str_to_lower(str_replace_all(title, "[^A-Za-z0-9 ]", " ")), "\\s+")[[1]]
words <- words[nzchar(words) & !words %in% c("a", "an", "the", "of", "in", "on", "to", "and", "for", "from", "with", "do", "is", "are", "using", "among", "between", "what", "who", "how", "at", "by")]
id <- paste(str_to_lower(first_last), year, words[1], sep = "_")

entry <- list(
  id = id, title = title, year = as.integer(year), venue = venue, doi = doi, url = NULL,
  citation = citation, cv_number = cv_number, authors = as.list(nat), authors_cv = authors_cv, et_al = FALSE,
  authors_n = length(au), author_position = which(map_lgl(au, is_peter))[1],
  status = "published",                       # set in_press by hand if CrossRef has no volume yet
  role = if (identical(which(map_lgl(au, is_peter))[1], 1L)) "lead" else "contributing",
  areas = set_names(rep(list(NULL), 3), AREAS |> names()), builds_on = list(), tier = NULL, featured = TRUE,
  contribution = set_names(rep(list(NULL), 6), names(CREDIT)), effort = NULL, effort_note = NULL, blurb = NULL, sticker = NULL, motif = NULL)
if (is.na(entry$author_position)) warning("Peter not found in the CrossRef author list — check the entry")

cat(as.yaml(list(entry), indent.mapping.sequence = TRUE, handlers = list(logical = verbatim_logical)))
if (dry) { cat("-- dry run: nothing written --\n"); quit(status = 0) }
d$entries <- c(list(entry), d$entries)           # newest first, like the CV
write_articles(here("5_skilltree", "data", "articles.yml"), d$header, d$entries)
cat(sprintf("added %s as CV #%d. Next: rate it in the app, then build_tree.R and render_cv_pubs.R.\n", id, cv_number))
