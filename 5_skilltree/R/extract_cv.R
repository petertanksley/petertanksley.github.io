# extract_cv.R — scaffold 5_skilltree/data/articles.yml from the CV.
#
# Reads the `::: {.pub-item}` blocks (numbered academic articles) and the `::: {.cv-indent}`
# blocks under "Preprints" in 2_cv/tanksley_cv.qmd, and writes one YAML
# entry per article. Safe to rerun: EXTRACTED fields are refreshed from the CV every time,
# JUDGEMENT fields (branch, role, contribution, effort, blurb, builds_on, sticker, featured, tier,
# id) are kept from the existing YAML if there is one. First run fills judgement fields with
# documented defaults/guesses that Peter reviews.
#
# Run from the site repo root:  Rscript 5_skilltree/R/extract_cv.R

suppressPackageStartupMessages({
  library(here)
  library(stringr)
  library(purrr)
  library(yaml)
})

# ---- locate inputs --------------------------------------------------------------------------
# Once the CV includes the generated 2_cv/_publications.qmd, that file IS the publication block and
# this script is a migration / back-compat tool: parse the include when it exists, else the CV itself.
pub_include <- here("2_cv", "_publications.qmd")
cv_path  <- if (file.exists(pub_include)) pub_include else here("2_cv", "tanksley_cv.qmd")
out_path <- here("5_skilltree", "data", "articles.yml")
if (!file.exists(cv_path)) stop("CV not found at ", cv_path, " — run from the site repo root")

cv <- readLines(cv_path, warn = FALSE, encoding = "UTF-8")

# ---- slice the Publications section (whole file when reading the include) --------------------
pub_start <- which(str_detect(cv, "^## \\[Publications\\]"))
pub_end   <- which(str_detect(cv, "^## \\[Presentations\\]"))
pubs <- if (length(pub_start) == 1 && length(pub_end) == 1 && pub_end > pub_start) cv[pub_start:(pub_end - 1)] else cv
preprint_hdr <- which(str_detect(pubs, "^### \\[Preprints\\]"))

# ---- helpers --------------------------------------------------------------------------------
ME <- "Tanksley"

# The CV writes the first author inverted ("Surname, Given") and the rest natural. Normalise
# the first author, then split on ", " / " & " / ", & " into one token per author.
parse_authors <- function(s) {
  s <- str_replace(str_trim(s), "\\.$", "")
  s <- str_replace_all(s, "\\*\\*", "")                       # drop bold markers
  et_al <- str_detect(s, ",?\\s*et al\\.?$")
  s <- str_replace(s, ",?\\s*et al\\.?$", "")
  # invert leading "Surname, Given" → "Given Surname". The CV inverts the first author on articles
  # but not consistently on preprints ("Deniz Fraemke, Lena Paulus, ..."), so only invert when the
  # second token looks like a given name: one word, or carrying an initial ("Peter T.", "M. Hunter").
  m <- str_match(s, "^([^,&]+), ([^,&]+?)(?=(, |$| &))")
  if (!is.na(m[1, 1])) {
    given <- m[1, 3]
    looks_given <- !str_detect(given, "\\s") || str_detect(given, "(^|\\s)[A-Z]\\.?[A-Z]?\\.(\\s|$)|\\b[A-Z]\\.$")
    if (looks_given) s <- str_replace(s, fixed(m[1, 1]), paste(given, m[1, 2]))
  }
  toks <- str_split(s, ",\\s*&\\s*|,\\s*|\\s+&\\s+")[[1]]
  toks <- str_trim(toks); toks <- toks[toks != ""]
  pos  <- which(str_detect(toks, ME))
  list(authors = toks,
       n = if (et_al) NA_integer_ else length(toks),
       position = if (length(pos)) pos[1] else NA_integer_,
       et_al = et_al)
}

# One `::: {.pub-item}` line → list of extracted fields. `year` comes from the enclosing heading.
parse_article <- function(line, year) {
  cv_number <- as.integer(str_match(line, "^(\\d+)\\.\\s")[, 2])
  body      <- str_replace(line, "^\\d+\\.\\s+", "")
  parts     <- str_split_fixed(body, "<br>", 2)
  au        <- parse_authors(parts[1])
  authors_cv <- str_trim(parts[1])                         # verbatim, bold markers and all: the CV prints this
  rest      <- parts[2]
  # title: curly or straight quotes; the CV once had a reversed opening quote, so accept either
  title     <- str_match(rest, "^[“”\"](.+?)[.?!]?[“”\"]")[, 2]
  after     <- str_replace(rest, "^[“”\"].+?[“”\"]\\s*", "")
  link      <- str_match(after, "^\\[\\*(.+?)\\*\\]\\((\\S+?)\\)(\\{[^}]*\\})?")
  if (!is.na(link[1, 1])) {
    venue <- link[1, 2]; href <- link[1, 3]
    tail  <- str_trim(str_replace(after, fixed(link[1, 1]), ""))
  } else {
    venue <- str_match(after, "^\\*(.+?)\\*")[, 2]; href <- NA_character_
    tail  <- str_trim(str_replace(after, "^\\*.+?\\*\\s*", ""))
  }
  tail <- str_replace(tail, "\\.$", "")
  tail <- str_replace(tail, "^[,;\\s]+", "")                     # the CV writes "], 52, 101270." → "52, 101270"
  tail <- str_replace_all(tail, "^\\((.*)\\)$", "\\1")          # "(in press)" → "in press"
  status <- if (str_detect(tail, "in press")) "in_press" else "published"
  doi <- if (!is.na(href) && str_detect(href, "doi\\.org/")) str_replace(href, "^.*doi\\.org/", "") else NA_character_
  url <- if (!is.na(href) && is.na(doi)) href else NA_character_
  list(cv_number = cv_number, title = title, year = year, venue = venue, doi = doi, url = url,
       citation = if (nzchar(tail)) tail else NA_character_, status = status,
       authors = au$authors, authors_cv = authors_cv, et_al = au$et_al,
       authors_n = au$n, author_position = au$position)
}

# Preprint block: 2–3 lines inside `::: {.cv-indent}`; authors end with a backslash line break.
parse_preprint <- function(lines) {
  txt   <- str_squish(paste(str_replace(lines, "\\\\$", ""), collapse = " "))
  parts <- str_split_fixed(txt, "(?<=al\\.)\\s+|(?<=\\.)\\s+(?=[“\"])", 2)
  au    <- parse_authors(parts[1])
  authors_cv <- str_trim(parts[1])
  rest  <- parts[2]
  title <- str_match(rest, "^[“”\"](.+?)[.?!]?[“”\"]")[, 2]
  link  <- str_match(rest, "\\[\\*(.+?)\\*\\]\\((\\S+?)\\)")
  href  <- link[1, 3]
  doi   <- if (!is.na(href) && str_detect(href, "doi\\.org/")) str_replace(href, "^.*doi\\.org/", "") else NA_character_
  year  <- as.integer(str_match(doi, "/(\\d{4})\\.")[, 2])   # bio/medRxiv DOIs carry the year
  list(cv_number = NA_integer_, title = title, year = year, venue = link[1, 2], doi = doi,
       url = if (is.na(doi)) href else NA_character_, citation = NA_character_, status = "preprint",
       authors = au$authors, authors_cv = authors_cv, et_al = au$et_al,
       authors_n = au$n, author_position = au$position)
}

# ---- walk the section -----------------------------------------------------------------------
articles <- list(); year <- NA_integer_; i <- 1
while (i <= length(pubs)) {
  ln <- pubs[i]
  if (str_detect(ln, "^#### \\*\\*\\d{4}\\*\\*")) year <- as.integer(str_extract(ln, "\\d{4}"))
  if (str_detect(ln, "^::: \\{\\.pub-item\\}")) {
    articles[[length(articles) + 1]] <- parse_article(pubs[i + 1], year); i <- i + 2
  } else if (str_detect(ln, "^::: \\{\\.cv-indent\\}") && length(preprint_hdr) && i > preprint_hdr) {
    j <- i + 1; while (!str_detect(pubs[j], "^:::\\s*$")) j <- j + 1
    articles[[length(articles) + 1]] <- parse_preprint(pubs[(i + 1):(j - 1)]); i <- j
  }
  i <- i + 1
}

# ---- defaults for judgement fields (FIRST RUN ONLY; kept from YAML thereafter) ---------------
# Area ratings, 0-3 on each of three axes, from titles alone. Peter reviews. The tree turns the
# ratings into a direction (vector sum along three axes 120 degrees apart), so 3/0/0 sits on its
# axis and 2/2/0 on the corner between two axes; the year picks the ring.
#                     biosocial, criminology, responders
area_guess <- list(
  `28` = c(0, 1, 3), `27` = c(3, 0, 0), `26` = c(1, 0, 3), `25` = c(0, 3, 0),
  `24` = c(0, 3, 0), `23` = c(0, 1, 3), `22` = c(0, 2, 2), `21` = c(0, 1, 3),
  `20` = c(0, 3, 0), `19` = c(0, 2, 2), `18` = c(3, 0, 0), `17` = c(1, 0, 3),
  `16` = c(1, 0, 3), `15` = c(3, 1, 0), `14` = c(0, 3, 0), `13` = c(3, 0, 0),
  `12` = c(2, 2, 0), `11` = c(3, 0, 0), `10` = c(3, 0, 0),  `9` = c(3, 0, 0),
   `8` = c(2, 2, 0),  `7` = c(3, 0, 0),  `6` = c(2, 2, 0),  `5` = c(2, 2, 0),
   `4` = c(1, 3, 0),  `3` = c(2, 2, 0),  `2` = c(3, 0, 0),  `1` = c(2, 2, 0))
area_guess_doi <- list(`10.64898/2026.04.01.715866` = c(3, 0, 0), `10.64898/2026.02.09.26344198` = c(3, 0, 0))
AREAS <- c("biosocial", "criminology", "responders")
as_areas <- function(v) if (is.null(v)) set_names(rep(list(NULL), 3), AREAS) else set_names(as.list(as.integer(v)), AREAS)
# Site rule (PROJ_tanksley_website/CLAUDE.md): do not feature the McAllister/Gonzalez firefighter
# biomarker papers. Rendered muted, not omitted (plan Q3). Visual tier only.
not_featured <- c(16L, 17L, 26L)

slugify <- function(x) str_replace_all(str_to_lower(str_replace_all(x, "[^A-Za-z0-9 ]", " ")), "\\s+", "_")
stopwords <- c("a", "an", "the", "of", "in", "on", "to", "and", "for", "from", "with", "do", "is", "are",
               "using", "among", "between", "what", "who", "how", "toward", "towards", "at", "by")
make_id <- function(a) {
  first_last <- str_extract(a$authors[1], "[A-Za-z\\-]+$")
  words <- str_split(slugify(a$title), "_")[[1]]; words <- words[nzchar(words) & !words %in% stopwords]
  paste(str_to_lower(first_last), a$year, words[1], sep = "_")
}

fresh_judgement <- function(a) {
  cv  <- a$cv_number                                   # NULL for preprints (na2null ran already)
  pos <- a$author_position
  list(id = make_id(a),
       role = if (!is.null(pos) && pos == 1) "lead" else "contributing",
       areas = as_areas(if (!is.null(cv)) area_guess[[as.character(cv)]] else if (!is.null(a$doi)) area_guess_doi[[a$doi]] else NULL),
       builds_on = list(), tier = NULL,
       featured = is.null(cv) || !(cv %in% not_featured),
       contribution = list(conceptualization = NULL, data = NULL, analysis = NULL,
                           methods = NULL, writing = NULL, supervision = NULL),
       effort = NULL, effort_note = NULL, blurb = NULL, sticker = NULL)
}

# ---- merge with the existing YAML, if any ---------------------------------------------------
JUDGEMENT <- c("id", "role", "areas", "builds_on", "tier", "featured", "contribution",
               "effort", "effort_note", "blurb", "sticker")
existing <- if (file.exists(out_path)) read_yaml(out_path) else list()
key_of <- function(e) if (!is.null(e$cv_number) && !is.na(e$cv_number)) paste0("cv", e$cv_number) else paste0("doi:", e$doi)
existing <- set_names(existing, map_chr(existing, key_of))

na2null <- function(x) if (length(x) == 1 && is.na(x)) NULL else x
entries <- map(articles, function(a) {
  a <- map(a, na2null)
  old <- existing[[key_of(a)]]
  j   <- if (is.null(old)) fresh_judgement(a) else old[JUDGEMENT]
  extracted <- a[c("title", "year", "venue", "doi", "url", "citation", "cv_number",
                   "authors", "authors_cv", "et_al", "authors_n", "author_position", "status")]
  # field order: identity → extracted bibliographic → judgement
  c(list(id = j$id), extracted, j[setdiff(JUDGEMENT, "id")])
})

# ensure ids are unique (two papers by the same first author, same year, same first title word)
ids <- map_chr(entries, "id")
dups <- ids[duplicated(ids)]
for (d in unique(dups)) { idx <- which(ids == d); ids[idx] <- paste0(d, "_", seq_along(idx)) }
entries <- map2(entries, ids, function(e, id) { e$id <- id; e })

# ---- write -----------------------------------------------------------------------------------
header <- c(
  "# data/articles.yml — source of truth for the skill tree.",
  "# Bibliographic fields (incl. authors_cv, the verbatim author string the CV prints) were extracted by",
  "# 5_skilltree/R/extract_cv.R and are OVERWRITTEN on rerun; render_cv_pubs.R prints them back into the",
  "# CV. Judgement fields are Peter's and are preserved:",
  "#   areas.biosocial / .criminology / .responders (0-3 each; they set the article's direction from the",
  "#   origin, so 3/0/0 sits on its axis and 2/2/0 between two axes; the year sets the ring),",
  "#   role (lead | contributing), builds_on (ids of lineage nodes), tier (unused for now),",
  "#   featured (false = muted tier),",
  "#   contribution.* (collapsed CRediT, 0-3 each), effort (1-5), effort_note, blurb, sticker.",
  "# First-run areas and role values are GUESSES from titles and author position — review them.",
  sprintf("# Last extracted %s from %s", format(Sys.time(), "%Y-%m-%d %H:%M"), basename(cv_path)),
  "")
body <- as.yaml(entries, indent.mapping.sequence = TRUE, line.sep = "\n",
                handlers = list(logical = verbatim_logical))   # true/false, not yes/no
writeLines(c(header, body), out_path, useBytes = FALSE)

n_new <- sum(!map_chr(entries, key_of) %in% names(existing))
cat(sprintf("articles.yml: %d entries (%d articles, %d preprints); %d new, %d preserved from existing YAML\n",
            length(entries), sum(map_chr(entries, "status") != "preprint"),
            sum(map_chr(entries, "status") == "preprint"), n_new, length(entries) - n_new))
missing_pos <- map_chr(entries, "id")[map_lgl(entries, ~ is.null(.x$author_position))]
if (length(missing_pos)) cat("WARNING: could not locate Peter in author list for:", missing_pos, "\n")
