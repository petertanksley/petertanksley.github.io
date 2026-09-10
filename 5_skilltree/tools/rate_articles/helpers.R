# helpers.R — read/write 5_skilltree/data/articles.yml for the rating app, touching only the judgement fields.
# Sourced by app.R; also testable on its own (see test_helpers.R beside it).

suppressPackageStartupMessages({ library(yaml); library(purrr); library(stringr) })

AREAS  <- c(biosocial = "Biosocial", criminology = "Criminology", responders = "First responders")
CREDIT <- c(conceptualization = "Conceptualization",
            data = "Data (curation, investigation, resources)",
            analysis = "Analysis (formal analysis, software, visualization)",
            methods = "Methods (methodology, validation)",
            writing = "Writing (original draft, review & editing)",
            supervision = "Supervision (supervision, admin, funding)")
ROLES  <- c(lead = "Lead", contributing = "Contributing")
EFFORT <- c(`1` = "1 · light", `2` = "2 · modest", `3` = "3 · substantial", `4` = "4 · heavy", `5` = "5 · consuming")

read_articles <- function(path) {
  lines  <- readLines(path, warn = FALSE, encoding = "UTF-8")
  header <- lines[seq_len(which(str_detect(lines, "^- id:"))[1] - 1)]
  list(header = header, entries = read_yaml(path))
}

write_articles <- function(path, header, entries) {
  # read_yaml hands a one-item sequence back as a bare string; keep builds_on a sequence on disk always
  entries <- lapply(entries, function(e) { e$builds_on <- as.list(unname(unlist(e$builds_on))); e })
  body <- as.yaml(entries, indent.mapping.sequence = TRUE, line.sep = "\n",
                  handlers = list(logical = verbatim_logical))
  writeLines(c(header, body), path, useBytes = FALSE)
}

# keep a key present with a null value (e$x <- NULL would delete the key)
set_nullable <- function(e, key, value) {
  if (is.null(value) || (length(value) == 1 && (is.na(value) || identical(value, "")))) e[key] <- list(NULL)
  else e[[key]] <- value
  e
}

# apply one article's judgement fields from a plain list of inputs (all optional)
apply_judgement <- function(e, j) {
  for (k in names(AREAS))  e$areas[k]        <- list(if (is.null(j$areas[[k]]))        NULL else as.integer(j$areas[[k]]))
  for (k in names(CREDIT)) e$contribution[k] <- list(if (is.null(j$contribution[[k]])) NULL else as.integer(j$contribution[[k]]))
  e$role     <- j$role %||% e$role
  e$featured <- isTRUE(j$featured)
  e <- set_nullable(e, "effort",      if (is.null(j$effort)) NULL else as.integer(j$effort))
  e <- set_nullable(e, "effort_note", str_trim(j$effort_note %||% ""))
  e <- set_nullable(e, "blurb",       str_trim(j$blurb %||% ""))
  e$builds_on <- as.list(unname(j$builds_on %||% character(0)))
  e
}

# how complete is an entry? returns named logicals
completeness <- function(e) {
  ar <- unlist(e$areas); co <- unlist(e$contribution)
  c(areas        = length(ar) == 3 && sum(ar) > 0,
    contribution = length(co) == 6,
    effort       = !is.null(e$effort),
    blurb        = identical(e$status, "preprint") || (!is.null(e$blurb) && nzchar(e$blurb)))   # preprints carry no blurb
}

short_title <- function(t, n = 60) if (nchar(t) > n) paste0(substr(t, 1, n - 1), "…") else t
