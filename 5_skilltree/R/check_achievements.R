# check_achievements.R — diff citation snapshots against data/achievements.yml, render what fires as a Dungeon
# Crawler Carl system message (title / body / Reward line), and optionally write it to the ledger.
#
# Usage (from repo root):
#   Rscript 5_skilltree/R/check_achievements.R                 dry run: print what would fire (newest two snapshots)
#   Rscript 5_skilltree/R/check_achievements.R --log           also append to data/achievements_log.yml
#   Rscript 5_skilltree/R/check_achievements.R --replay        REBUILD the ledger from every consecutive snapshot pair
#                                                              (after editing a rule's wording; the ledger is derived state)
#   Rscript 5_skilltree/R/check_achievements.R --dir <dir>     snapshots elsewhere (tests)
#   ... --ledger <file>                                       ledger elsewhere (tests)
# Triggers: step (any increase), round (crosses a multiple of `every`), threshold (reaches `at` once),
# log10 (reaches a new power of ten), ladder (reaches a rung `at` of the reward tier ladder that old had not).
#
# The ledger is committed: every fired achievement is written out in full (rendered text, metric, old and new
# values, snapshot date) with a `key` (<id>-<date>) that the site uses as the anchor. The site renders from the
# ledger, never from the rules (build_tree.R puts per-paper counts on the hexes; achievements.qmd lists it;
# index.qmd shows the latest). Re-running --log for the same snapshot pair is idempotent. Because snapshots are
# kept, the whole ledger can be regenerated with --replay, so a wording edit never strands old entries.
# Register and tier logic: 5_skilltree/ACHIEVEMENTS.md. Exit 0 always; with < 2 snapshots it says so.

suppressPackageStartupMessages({ library(here); library(yaml); library(jsonlite); library(purrr); library(stringr) })
args      <- commandArgs(trailingOnly = TRUE)
do_log    <- "--log" %in% args
do_replay <- "--replay" %in% args
snap_dir  <- if (any(i <- args == "--dir")) args[which(i)[1] + 1] else here("5_skilltree", "data", "scholar")
RULES     <- here("5_skilltree", "data", "achievements.yml")
LEDGER    <- if (any(j <- args == "--ledger")) args[which(j)[1] + 1] else here("5_skilltree", "data", "achievements_log.yml")
TIERS     <- c("Bronze", "Silver", "Gold", "Platinum", "Legendary", "Celestial")

rules <- read_yaml(RULES)
arts  <- read_yaml(here("5_skilltree", "data", "articles.yml")); arts <- set_names(arts, map_chr(arts, "id"))
AREA_NAMES <- c(biosocial = "biosocial", criminology = "criminology", responders = "responders")
dominant <- function(a) { ar <- unlist(a$areas[names(AREA_NAMES)]); if (!length(ar) || sum(ar == max(ar)) > 1) "mixed" else names(ar)[which.max(ar)] }

# a rule whose metric contains `articles.*.` expands to one rule per article in articles.yml; the paper's title, venue,
# year and dominant area fill {paper} {venue} {year} and pick the box type when `reward.type` is a map by area
expand <- function(r) {
  if (!str_detect(r$metric, fixed("articles.*."))) return(list(r))
  map(arts, function(a) { e <- r; e$metric <- str_replace(r$metric, fixed("articles.*."), paste0("articles.", a$id, "."))
    e$id <- paste(r$id, a$id, sep = "-"); e$paper <- a; e })
}
rules <- flatten(map(rules, expand))
files <- sort(list.files(snap_dir, pattern = "^\\d{4}-\\d{2}-\\d{2}\\.json$", full.names = TRUE))
if (length(files) < 2) { cat("no previous snapshot in", snap_dir, "; nothing to compare\n"); quit(save = "no", status = 0) }
date_of <- function(f) str_remove(basename(f), "\\.json$")

dig  <- function(x, path) { for (k in str_split_1(path, fixed("."))) { x <- x[[k]]; if (is.null(x)) return(NA) }; if (is.null(x)) NA else as.numeric(x) }
fill <- function(tpl, o, n, a = NULL) {
  vals <- c("{old}" = format(o), "{new}" = format(n), "{delta}" = format(n - o), "{times}" = if (n == 1) "once" else paste(format(n), "times"),
            "{top}" = format(100 - n), "{s}" = if (n == 1) "" else "s")      # a percentile read as "top N%"; a plural
  if (!is.null(a)) vals <- c(vals, "{paper}" = a$title, "{venue}" = a$venue %||% "", "{year}" = format(a$year))
  str_replace_all(str_squish(tpl), fixed(vals))
}
# log10 rungs: 1, 10, 100, 1000 ...; zero sits below the first rung
rung <- function(x) if (x < 1) -1 else floor(log10(x))

# the rungs of a rule's ladder that apply to this paper: a rung with `role:` exists only for papers of that role
rungs_of <- function(r) { rw <- r$reward$tier; if (is.character(rw)) return(list())
  keep(rw, ~ is.null(.x$role) || (!is.null(r$paper) && identical(r$paper$role, .x$role))) }
# the Reward line: a joke string, or a box whose tier is fixed or read off a ladder against the new value
reward_of <- function(r, o, n) {
  rw <- r$reward
  if (is.character(rw)) { txt <- fill(rw, o, n, r$paper); return(list(text = if (str_starts(txt, "Reward:")) txt else paste("Reward:", txt), tier = NA, box = NA)) }
  if (is.null(rw$type)) stop("rule ", r$id, ": reward must be text or {type, tier}")
  type <- if (is.character(rw$type)) rw$type else {                       # a map by dominant area, with a `mixed` fallback
    d <- if (is.null(r$paper)) "mixed" else dominant(r$paper); rw$type[[d]] %||% rw$type[["mixed"]] %||% stop("rule ", r$id, ": no box type for area ", d) }
  tier <- if (is.character(rw$tier)) rw$tier else {
    ladder <- keep(rungs_of(r), ~ n >= .x$at); if (!length(ladder)) stop("rule ", r$id, ": no ladder rung at or below ", n)
    ladder[[which.max(map_dbl(ladder, "at"))]]$tier }
  if (!tier %in% TIERS) stop("rule ", r$id, ": unknown tier '", tier, "'")
  list(text = sprintf("Reward: You've received %s %s %s!", if (grepl("^[AEIOU]", tier)) "an" else "a", tier, type), tier = tier, box = type)
}

# everything that fires between two snapshots, rendered; `quiet` suppresses the per-achievement printout (replay)
fire <- function(old_file, new_file, quiet = FALSE) {
  old <- read_json(old_file); new <- read_json(new_file)
  old_date <- date_of(old_file); new_date <- date_of(new_file)
  fired <- list()
  # min_age: a per-paper rule ignores papers younger than this many calendar years at the snapshot date. A paper
  # that was too young at the OLD snapshot counts as 0 there, so its first eligible snapshot fires the rung it sits on.
  age_ok <- function(r, date) is.null(r$min_age) || is.null(r$paper) || (as.integer(substr(date, 1, 4)) - r$paper$year) >= r$min_age
  for (r in rules) {
    if (!age_ok(r, new_date)) next
    o <- dig(old, r$metric); n <- dig(new, r$metric)
    if (is.na(n)) next
    if (is.na(o) || !age_ok(r, old_date)) o <- 0               # a metric that did not exist yet (e.g. an uncited paper) counts as 0
    hit <- switch(r$trigger,
      step      = n > o,
      round     = (n %/% r$every) > (o %/% r$every),
      threshold = n >= r$at && o < r$at,
      log10     = rung(n) > rung(o),
      ladder    = { at <- map_dbl(rungs_of(r), "at"); length(at) > 0 && any(n >= at & o < at) },
      stop("unknown trigger '", r$trigger, "' in rule ", r$id))
    if (!hit) next
    rw <- reward_of(r, o, n)
    num <- function(x) if (x == round(x)) as.integer(x) else x          # whole counts print as 12, not 12.0
    a <- list(key = paste(r$id, new_date, sep = "-"), id = r$id, date = new_date, since = old_date, metric = r$metric,
              old = num(o), new = num(n),
              title = fill(r$title, o, n, r$paper), body = fill(r$body %||% "", o, n, r$paper), reward = rw$text)
    if (!is.null(r$paper)) { a$article <- r$paper$id; a$paper <- r$paper$title }   # id for the hex link, title for the byline
    if (!is.na(rw$tier)) a$tier <- rw$tier
    if (!is.na(rw$box))  a$box  <- rw$box
    a$rank     <- if (is.na(rw$tier)) 0L else match(rw$tier, TIERS)                # sorts the page within a date; 0 = joke reward
    a$featured <- is.null(r$paper) || !isFALSE(r$paper$featured)                  # the homepage card skips unfeatured papers (CLAUDE.md)
    fired[[length(fired) + 1]] <- a
    if (!quiet) cat(sprintf("\n[%s] %s: %s -> %s\nNew achievement! %s\n%s\n%s\n", a$id, a$metric, format(o), format(n), a$title, a$body, a$reward))
  }
  fired
}
write_ledger <- function(ledger) {
  header <- c("# achievements_log.yml — GENERATED ledger of every achievement that has fired; the site renders from this file.",
              "# Written by 5_skilltree/R/check_achievements.R --log (append) or --replay (rebuild from all snapshots).",
              "# Do not edit by hand: fix the wording in achievements.yml and run --replay. `key` is the anchor on achievements.html.", "")
  # logicals as true/false, not R yaml's yes/no: Quarto's YAML 1.2 reader would keep "no" as a truthy string
  tf <- function(x) { r <- ifelse(x, "true", "false"); class(r) <- "verbatim"; r }
  writeLines(c(header, as.yaml(ledger, indent.mapping.sequence = TRUE, handlers = list(logical = tf))), LEDGER)
}

if (do_replay) {
  # rebuild from scratch: every consecutive pair, oldest first, so the ledger reads in the order things happened
  ledger <- list()
  for (k in 2:length(files)) {
    f <- fire(files[k - 1], files[k], quiet = TRUE)
    cat(sprintf("%s -> %s: %d fired\n", date_of(files[k - 1]), date_of(files[k]), length(f)))
    ledger <- c(ledger, f)
  }
  write_ledger(ledger)
  cat(sprintf("replayed %d snapshot pair%s into %s: %d entries\n", length(files) - 1, if (length(files) == 2) "" else "s", basename(LEDGER), length(ledger)))
  quit(save = "no", status = 0)
}

cat(sprintf("comparing %s -> %s\n", date_of(files[length(files) - 1]), date_of(files[length(files)])))
fired <- fire(files[length(files) - 1], files[length(files)])
cat(sprintf("\n%d rule%s fired\n", length(fired), if (length(fired) == 1) "" else "s"))

if (do_log && length(fired)) {
  ledger <- if (file.exists(LEDGER)) read_yaml(LEDGER) else list()
  if (is.null(ledger)) ledger <- list()
  keys   <- map_chr(ledger, ~ .x$key %||% paste(.x$id, .x$date, sep = "-"))
  add    <- keep(fired, ~ !.x$key %in% keys)
  write_ledger(c(ledger, add))
  cat(sprintf("logged %d new (%d already in %s)\n", length(add), length(fired) - length(add), basename(LEDGER)))
}
