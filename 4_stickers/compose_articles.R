# compose_articles.R — turn article ratings + lineage into bananarama prompts for per-article stickers.
#
# Reads 5_skilltree/data/articles.yml (areas, builds_on, sticker) and 4_stickers/motifs.yml (the
# visual vocabulary) and writes 4_stickers/articles.yaml, one bananarama entry per article that is
# READY to draw. Rules:
#   primary   = the highest-rated area (ties: responders > criminology > biosocial)
#   tie       = top two areas equal -> one fused object from motifs$pairs, no secondary accent
#   secondary = otherwise the next area if rated >= 1 ("strong" at 2-3, "faint" at 1)
#   level     = 1 + max(level of parents), capped at 3; roots are level 1
#   ready     = no parents, OR every parent already has a framed final in www/hex/ (its sticker
#               field is set and the file exists). Parents are attached as reference images, so
#               generation runs one lineage tier at a time: compose -> generate -> pick -> repeat.
# Articles that already have a sticker are left out (nothing to draw; also protects the budget).
#
# Usage (from repo root):
#   Rscript 4_stickers/compose_articles.R [--ids id1,id2,...] [--n 2] [--redo] [--dry-run]
#   Rscript -e 'bananarama::bananarama("4_stickers/articles.yaml")'   # then generate
# --dry-run prints the readiness table and assembled prompts without writing anything.
# --redo treats articles that already have a sticker as ready (for regenerating with a new vocabulary);
#    move or delete their old candidates in 4_stickers/articles/ first, or bananarama will skip them.
# --reseed K shifts every seed by K: a re-roll with the same prompt and seed reproduces the same composition,
#    so retries need a new seed. The seed used is recorded in articles.yaml and the winner in finals_src/.
# --n sets candidates per article for this run (default 3 from bananarama.yaml); 2 is enough for roots,
#    which vary little at a fixed seed; keep 3 for lineage children where the pick matters more.

suppressPackageStartupMessages({ library(here); library(yaml); library(purrr); library(stringr) })
source(here("5_skilltree", "tools", "rate_articles", "helpers.R"))   # read_articles(), AREAS

args    <- commandArgs(trailingOnly = TRUE)
dry_run <- "--dry-run" %in% args
redo    <- "--redo" %in% args        # plan regeneration: articles that already have a sticker count as ready
only    <- if (any(i <- args == "--ids")) str_split_1(args[which(i)[1] + 1], ",") else NULL
n_cand  <- if (any(i <- args == "--n")) as.integer(args[which(i)[1] + 1]) else NULL   # candidates per article; default = shared n (3)
reseed  <- if (any(i <- args == "--reseed")) as.integer(args[which(i)[1] + 1]) else 0L  # shift every seed for a retry (the hash seed makes re-rolls repeat)

ARTICLES_YML <- here("5_skilltree", "data", "articles.yml")
MOTIFS_YML   <- here("4_stickers", "motifs.yml")
SHARED_YAML  <- here("4_stickers", "bananarama.yaml")
OUT_YAML     <- here("4_stickers", "articles.yaml")
HEX_DIR      <- here("www", "hex")
TIE_ORDER    <- c("responders", "criminology", "biosocial")   # deterministic primary when areas tie
MAX_LEVEL    <- 3L
MAX_REFS     <- 2L                                             # parent finals attached per prompt

motifs <- read_yaml(MOTIFS_YML)
shared <- read_yaml(SHARED_YAML)$defaults
arts   <- read_articles(ARTICLES_YML)$entries
ids    <- map_chr(arts, "id")
by_id  <- set_names(arts, ids)
stopifnot(all(unlist(map(arts, "builds_on")) %in% ids))

# deterministic per-article seed (bananarama takes one seed per image; all n candidates share it)
seed_of <- function(id) { v <- utf8ToInt(id); (sum(v * (seq_along(v) * 31L)) %% 2147483L) + 1000L + reseed }

fill <- function(tpl, vars) str_replace_all(tpl, fixed(set_names(unname(vars), paste0("{", names(vars), "}"))))
squash <- function(x) str_squish(paste(x, collapse = " "))

# level: depth in the builds_on chain, memoised, with a cycle guard
level_memo <- list()
level_of <- function(id, seen = character()) {
  if (!is.null(level_memo[[id]])) return(level_memo[[id]])
  if (id %in% seen) stop("builds_on cycle through ", id)
  parents <- unlist(by_id[[id]]$builds_on)
  lv <- if (length(parents)) 1L + max(map_int(parents, level_of, seen = c(seen, id))) else 1L
  level_memo[[id]] <<- lv
  lv
}

# effective motif: the article's own, else its deepest parent's, else a deterministic sample from
# the area's variant list. Returns the variant name; callers look up the text.
motif_of <- function(id, area, seen = character()) {
  e <- by_id[[id]]
  if (!is.null(e$motif) && nzchar(e$motif)) return(e$motif)
  parents <- setdiff(unlist(e$builds_on), seen)
  if (length(parents)) {
    deepest <- parents[order(-map_int(parents, level_of))][1]
    m <- motif_of(deepest, area, c(seen, id)); if (!is.null(m)) return(m)
  }
  vs <- names(motifs$areas[[area]]$variants)
  vs[(seed_of(id) %% length(vs)) + 1]
}

has_final <- function(id) {
  s <- by_id[[id]]$sticker
  !is.null(s) && nzchar(s) && file.exists(file.path(HEX_DIR, paste0(s, ".png")))
}

compose_one <- function(e) {
  a <- unlist(e$areas)[TIE_ORDER]; a[is.na(a)] <- 0L
  if (sum(a) == 0) return(list(id = e$id, status = "unrated"))
  primary <- names(a)[which.max(a)]
  rest    <- a[names(a) != primary]
  sec     <- names(rest)[which.max(rest)]; sec_rating <- unname(rest[sec])
  lv      <- min(level_of(e$id), MAX_LEVEL)
  parents <- unlist(e$builds_on)
  if (has_final(e$id) && !redo) return(list(id = e$id, status = "done", level = lv, primary = primary))
  waiting <- parents[!map_lgl(parents, has_final)]
  if (length(waiting)) return(list(id = e$id, status = "waiting", level = lv, primary = primary, waiting = waiting))

  # a tie between the top two areas is a fused object from motifs$pairs, not a primary plus an accent
  tie <- sec_rating > 0 && a[primary] == sec_rating
  if (tie) {
    key <- paste(sort(c(primary, sec)), collapse = "+")
    m <- motifs$pairs[[key]]; if (is.null(m)) stop("no pair motif for ", key)
    v_area <- m$variant_from
  } else { m <- motifs$areas[[primary]]; v_area <- primary }
  motif <- motif_of(e$id, v_area)
  # a motif that names a variant uses its text; any other string is free text written for this article
  v_txt <- motifs$areas[[v_area]]$variants[[motif]] %||% motif
  if (nchar(v_txt) < 4) stop(e$id, ": motif '", motif, "' is too short to draw")
  vars <- c(object = fill(squash(m$object), c(variant = squash(v_txt))), surface = squash(m$surface), noun = squash(m$noun))
  parts <- character()
  if (length(parents)) {
    deepest <- parents[order(-map_int(parents, level_of))][seq_len(min(MAX_REFS, length(parents)))]
    refs <- paste0("[../www/hex/", map_chr(deepest, ~ by_id[[.x]]$sticker), "]")
    tpl  <- if (length(refs) == 1) motifs$lineage$one else motifs$lineage$two
    parts <- c(parts, fill(squash(tpl), c(vars, ref1 = refs[1], ref2 = refs[min(2, length(refs))])))
  }
  parts <- c(parts, fill(squash(motifs$levels[[as.character(lv)]]), vars))
  if (sec_rating >= 1 && !tie) {
    tpl <- if (sec_rating >= 2) motifs$secondary$strong else motifs$secondary$faint
    parts <- c(parts, fill(squash(tpl), c(vars, accent = squash(motifs$areas[[sec]]$accent))))
  }
  parts <- c(parts, "Nothing else in the picture.")
  parts  <- str_c(str_to_upper(str_sub(parts, 1, 1)), str_sub(parts, 2))   # sentence-case each part; never lowercase the rest (DNA)
  prompt <- str_c(parts, collapse = " ")
  list(id = e$id, status = "ready", level = lv, primary = if (tie) paste0(primary, "+", sec) else primary,
       secondary = if (tie) "tie" else if (sec_rating >= 1) sprintf("%s (%d)", sec, sec_rating) else "-",
       motif = if (nchar(motif) > 24) paste0(substr(motif, 1, 22), "..") else motif,
       motif_src = if (!is.null(e$motif) && nzchar(e$motif)) { if (is.null(motifs$areas[[v_area]]$variants[[motif]])) "custom" else "set" } else if (length(parents)) "inherited" else "sampled",
       seed = seed_of(e$id), parents = parents, prompt = prompt)
}

pick <- if (is.null(only)) arts else { stopifnot(all(only %in% ids)); by_id[only] }
rows <- map(pick, compose_one)

# ---- readiness table ------------------------------------------------------------------------
cat(sprintf("%-34s %-7s %-3s %-22s %-20s %s\n", "id", "status", "lvl", "primary", "motif", "note"))
for (r in rows) {
  note <- switch(r$status,
                 waiting = paste("waits on", paste(r$waiting, collapse = ", ")),
                 ready   = if (length(r$parents)) paste("refs", paste(r$parents, collapse = ", ")) else "root",
                 done    = paste0("www/hex/", by_id[[r$id]]$sticker, ".png"),
                 unrated = "no area ratings")
  mot <- if (!is.null(r$motif)) sprintf("%s (%s)", r$motif, r$motif_src) else "-"
  cat(sprintf("%-34s %-7s %-3s %-22s %-20s %s\n", r$id, r$status, r$level %||% "-", r$primary %||% "-", mot, note))
}
ready <- keep(rows, ~ .x$status == "ready")
cat(sprintf("\n%d ready, %d waiting, %d done, %d unrated\n",
            length(ready), sum(map_chr(rows, "status") == "waiting"),
            sum(map_chr(rows, "status") == "done"), sum(map_chr(rows, "status") == "unrated")))

if (dry_run) {
  for (r in ready) cat("\n---- ", r$id, " (level ", r$level, ", ", r$primary, ", secondary ", r$secondary, ", motif ", r$motif, ", seed ", r$seed, ")\n", r$prompt, "\n", sep = "")
  quit(save = "no")
}
if (!length(ready)) { cat("Nothing to write.\n"); quit(save = "no") }

# ---- write articles.yaml --------------------------------------------------------------------
config <- list(
  defaults = list(style = squash(c(shared$style, motifs$style)),
                  `aspect-ratio` = "1:1", n = n_cand %||% shared$n %||% 3L, seed = shared$seed %||% 5891L),
  `output-dir` = "articles/",
  images = unname(map(ready, ~ list(name = .x$id, seed = .x$seed, description = .x$prompt)))   # bananarama wants a sequence
)
header <- c(
  "# articles.yaml — GENERATED by 4_stickers/compose_articles.R; do not edit by hand.",
  sprintf("# Written %s from 5_skilltree/data/articles.yml + 4_stickers/motifs.yml.", format(Sys.time(), "%Y-%m-%d %H:%M")),
  "# Generate:  Rscript -e 'bananarama::bananarama(\"4_stickers/articles.yaml\")'   (candidates -> 4_stickers/articles/, gitignored)",
  "# Then:      Rscript 4_stickers/preview_candidates.R <id>   ->   Rscript 4_stickers/pick_sticker.R <id> <n>",
  "# Only articles whose parents already have finals are listed; rerun compose after each pick to reach the next tier.",
  ""
)
writeLines(c(header, as.yaml(config, indent.mapping.sequence = TRUE, line.sep = "\n")), OUT_YAML)
cat(sprintf("wrote %s (%d prompt%s)\n", OUT_YAML, length(ready), if (length(ready) == 1) "" else "s"))
