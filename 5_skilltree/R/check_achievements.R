# check_achievements.R — diff citation snapshots against data/achievements.yml, render what fires as a Dungeon
# Crawler Carl system message (title / body / Reward line), and optionally write it to the ledger.
#
# Usage (from repo root):
#   Rscript 5_skilltree/R/check_achievements.R                 dry run: print what would fire (newest two snapshots)
#   Rscript 5_skilltree/R/check_achievements.R --log           also append to data/achievements_log.yml
#   Rscript 5_skilltree/R/check_achievements.R --replay        re-run every consecutive snapshot pair; entries already in the
#                                                              ledger are PRESERVED verbatim (an achievement, once earned, is
#                                                              archived), only keys never seen before are rendered and added
#   ... --replay --fresh                                       the old behaviour: discard the ledger and re-render everything
#                                                              from today's rules (deliberately rewrite history)
#   Rscript 5_skilltree/R/check_achievements.R --dir <dir>     snapshots elsewhere (tests)
#   ... --ledger <file>                                       ledger elsewhere (tests)
#   ... --manual <file>                                       manual-event file elsewhere (tests)
# Triggers: step (any increase), round (crosses a multiple of `every`), threshold (reaches `at` once),
# log10 (reaches a new power of ten), ladder (reaches a rung `at` of the reward tier ladder that old had not),
# revival (a dormant paper's count rises; reads articles.<id>.by_year), manual (never fires from snapshots: a
# template for hand-logged events in data/achievements_manual.yml, rendered and merged by --log and --replay).
#
# The ledger is committed: every fired achievement is written out in full (rendered text, metric, old and new
# values, snapshot date) with a `key` (<id>-<date>) that the site uses as the anchor. The site renders from the
# ledger, never from the rules (build_tree.R puts per-paper counts on the hexes; achievements.qmd lists it;
# index.qmd shows the latest). Re-running --log for the same snapshot pair is idempotent. Entries are archival
# (Peter, 2026-09-27): once in the ledger they are never re-rendered, so a wording edit, a new variant (which shifts the
# hash pick) or a moved rung applies only to achievements earned afterwards. --replay backfills keys the ledger lacks
# (e.g. a rule added after the snapshots) and keeps everything else as written; --fresh is the one way to rewrite.
# Register and tier logic: 5_skilltree/ACHIEVEMENTS.md. Exit 0 always; with < 2 snapshots it says so.

suppressPackageStartupMessages({ library(here); library(yaml); library(jsonlite); library(purrr); library(stringr) })
args      <- commandArgs(trailingOnly = TRUE)
do_log    <- "--log" %in% args
do_replay <- "--replay" %in% args
do_fresh  <- "--fresh" %in% args
snap_dir  <- if (any(i <- args == "--dir")) args[which(i)[1] + 1] else here("5_skilltree", "data", "scholar")
RULES     <- here("5_skilltree", "data", "achievements.yml")
LEDGER    <- if (any(j <- args == "--ledger")) args[which(j)[1] + 1] else here("5_skilltree", "data", "achievements_log.yml")
MANUAL    <- if (any(k <- args == "--manual")) args[which(k)[1] + 1] else here("5_skilltree", "data", "achievements_manual.yml")
TIERS     <- c("Bronze", "Silver", "Gold", "Platinum", "Legendary", "Celestial")

rules <- read_yaml(RULES)
arts  <- read_yaml(here("5_skilltree", "data", "articles.yml")); arts <- set_names(arts, map_chr(arts, "id"))
AREA_NAMES <- c(biosocial = "biosocial", criminology = "criminology", responders = "responders")
dominant <- function(a) { ar <- unlist(a$areas[names(AREA_NAMES)]); if (!length(ar) || sum(ar == max(ar)) > 1) "mixed" else names(ar)[which.max(ar)] }

# a rule whose metric contains `articles.*.` expands to one rule per article in articles.yml; the paper's title, venue,
# year and dominant area fill {paper} {venue} {year} and pick the box type when `reward.type` is a map by area
expand <- function(r) {
  if (is.null(r$metric) || !str_detect(r$metric, fixed("articles.*."))) return(list(r))
  map(arts, function(a) { e <- r; e$metric <- str_replace(r$metric, fixed("articles.*."), paste0("articles.", a$id, "."))
    e$id <- paste(r$id, a$id, sep = "-"); e$paper <- a; e })
}
rules <- flatten(map(rules, expand))
manual_rules <- keep(rules, ~ identical(.x$trigger, "manual")); manual_rules <- set_names(manual_rules, map_chr(manual_rules, "id"))
rules <- discard(rules, ~ identical(.x$trigger, "manual"))
files <- sort(list.files(snap_dir, pattern = "^\\d{4}-\\d{2}-\\d{2}\\.json$", full.names = TRUE))
if (length(files) < 2) cat("no previous snapshot in", snap_dir, "; nothing to compare, manual events only\n")
date_of <- function(f) str_remove(basename(f), "\\.json$")

dig  <- function(x, path) { for (k in str_split_1(path, fixed("."))) { x <- x[[k]]; if (is.null(x)) return(NA) }; if (is.null(x)) NA else as.numeric(x) }
fill <- function(tpl, o, n, a = NULL, extra = NULL) {
  vals <- c("{old}" = format(o), "{new}" = format(n), "{delta}" = format(n - o), "{times}" = if (n == 1) "once" else paste(format(n), "times"),
            "{top}" = format(100 - n), "{s}" = if (n == 1) "" else "s")      # a percentile read as "top N%"; a plural
  if (!is.null(a)) vals <- c(vals, "{paper}" = a$title, "{venue}" = a$venue %||% "", "{year}" = format(a$year))
  if (length(extra)) vals <- c(vals, set_names(unlist(extra), paste0("{", names(extra), "}")))   # {silent}; manual {what} {where} {note}
  str_replace_all(str_squish(tpl), fixed(vals))
}
# variants: title / body / joke reward may be a vector of alternatives; one is picked per firing, seeded from the
# achievement key so the same paper on the same date always reads the same and --replay is exact. Never the clock.
hash32 <- function(s) { h <- 0; for (c in utf8ToInt(s)) h <- (h * 31 + c) %% 2147483647; h }
pick   <- function(x, key, salt) if (length(x) <= 1) x else x[[hash32(paste(key, salt)) %% length(x) + 1]]
# log10 rungs: 1, 10, 100, 1000 ...; zero sits below the first rung
rung <- function(x) if (x < 1) -1 else floor(log10(x))

# the rungs of a rule's ladder that apply to this paper: a rung with `role:` exists only for papers of that role
rungs_of <- function(r) { rw <- r$reward$tier; if (is.character(rw)) return(list())
  keep(rw, ~ is.null(.x$role) || (!is.null(r$paper) && identical(r$paper$role, .x$role))) }
# the Reward line: a joke string, or a box whose tier is fixed or read off a ladder against the new value
reward_of <- function(r, o, n, key, extra = NULL) {
  rw <- r$reward
  if (is.character(rw)) { txt <- fill(pick(rw, key, "reward"), o, n, r$paper, extra); return(list(text = if (str_starts(txt, "Reward:")) txt else paste("Reward:", txt), tier = NA, box = NA)) }
  if (is.null(rw$type)) stop("rule ", r$id, ": reward must be text or {type, tier}")
  type <- if (is.character(rw$type)) rw$type else {                       # a map by dominant area, with a `mixed` fallback
    d <- if (is.null(r$paper)) "mixed" else dominant(r$paper); rw$type[[d]] %||% rw$type[["mixed"]] %||% stop("rule ", r$id, ": no box type for area ", d) }
  tier <- if (is.character(rw$tier)) rw$tier else {
    ladder <- keep(rungs_of(r), ~ n >= .x$at); if (!length(ladder)) stop("rule ", r$id, ": no ladder rung at or below ", n)
    ladder[[which.max(map_dbl(ladder, "at"))]]$tier }
  if (!tier %in% TIERS) stop("rule ", r$id, ": unknown tier '", tier, "'")
  list(text = sprintf("Reward: You've received %s %s %s!", if (grepl("^[AEIOU]", tier)) "an" else "a", tier, type), tier = tier, box = type)
}

# by_tag: a rule may carry {<tag>: {title, body, reward}} overrides, used when the paper carries that tag in
# articles.yml (`tags`). The first matching tag wins. Mortality papers draw death-free Necromancy wording this way.
tagged <- function(r) {
  if (is.null(r$by_tag) || is.null(r$paper)) return(r)
  hit <- intersect(names(r$by_tag), unlist(r$paper$tags)); if (!length(hit)) return(r)
  ov <- r$by_tag[[hit[1]]]; for (f in names(ov)) r[[f]] <- ov[[f]]; r
}
# Necromancy (2026-10-03). A paper is dormant at the old snapshot when it is at least `min_age` calendar years old
# then and has zero citations in each of the last `dormant_years` complete calendar years AND so far in the current
# one (so a paper that already woke up does not fire again on every later snapshot). It revives when its count rises
# and the new snapshot's by_year shows the citations landing in or after that window (guards OpenAlex dedup jitter).
# Needs by_year in BOTH snapshots: older snapshots lack it, so nothing fires across them. Returns NULL (no fire) or
# the number of complete calendar years the paper had been silent, read back as far as by_year and its age allow.
revived <- function(r, old, new, old_date, new_date, o, n) {
  if (is.na(o) || is.na(n) || n <= o || is.null(r$paper)) return(NULL)
  Y <- as.integer(substr(old_date, 1, 4)); pub <- r$paper$year
  if (Y - pub < (r$min_age %||% 0)) return(NULL)
  by_o <- old$articles[[r$paper$id]]$by_year; by_n <- new$articles[[r$paper$id]]$by_year
  if (is.null(by_o) || is.null(by_n)) return(NULL)
  cites <- function(by, yrs) map_dbl(as.character(yrs), ~ as.numeric(by[[.x]] %||% 0))
  window <- (Y - (r$dormant_years %||% 1)):Y
  if (any(cites(by_o, window) > 0)) return(NULL)
  if (!any(cites(by_n, min(window):as.integer(substr(new_date, 1, 4))) > 0)) return(NULL)
  silent <- 0L                                               # OpenAlex keeps ~10 years of counts_by_year: read no further back
  lo <- max(pub + 1, Y - 10)
  if (Y - 1 >= lo) for (y in (Y - 1):lo) { if (cites(by_o, y) > 0) break; silent <- silent + 1L }
  max(silent, 1L)
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
    extra <- NULL
    if (identical(r$trigger, "revival")) {                     # judged on the raw values: no zero-fill, old must be eligible too
      rv <- revived(r, old, new, old_date, new_date, o, n); if (is.null(rv)) next
      extra <- list(silent = format(rv), ys = if (rv == 1) "" else "s")
    }
    # forward_only (Peter, 2026-10-03): a metric the old snapshot did not carry yet never fires (no dump of past events
    # the first time a count is recorded). Cumulative ladders leave it off, so they may fire once for history.
    if (is.na(o) && isTRUE(r$forward_only)) next
    if (is.na(o) || !age_ok(r, old_date)) o <- 0               # a metric that did not exist yet (e.g. an uncited paper) counts as 0
    r <- tagged(r)
    hit <- switch(r$trigger,
      step      = n > o,
      round     = (n %/% r$every) > (o %/% r$every),
      threshold = n >= r$at && o < r$at,
      log10     = rung(n) > rung(o),
      ladder    = { at <- map_dbl(rungs_of(r), "at"); length(at) > 0 && any(n >= at & o < at) },
      revival   = TRUE,                                        # revived() already decided
      stop("unknown trigger '", r$trigger, "' in rule ", r$id))
    if (!hit) next
    key <- paste(r$id, new_date, sep = "-")
    rw <- reward_of(r, o, n, key, extra)
    num <- function(x) if (x == round(x)) as.integer(x) else x          # whole counts print as 12, not 12.0
    a <- list(key = key, id = r$id, date = new_date, since = old_date, metric = r$metric,
              old = num(o), new = num(n),
              title = fill(pick(r$title, key, "title"), o, n, r$paper, extra), body = fill(pick(r$body %||% "", key, "body"), o, n, r$paper, extra),
              reward = rw$text)
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

# ---- manual events ---------------------------------------------------------------------------------
# data/achievements_manual.yml is hand-appended, one entry per event: {kind, date, what, where?, note?, approx?, slug?}.
# `kind` names a `trigger: manual` rule in achievements.yml, whose title / body / reward render the entry ({what}
# {where} {note} {year}). `approx: month | year` marks a date known only that precisely (the CV backfill); the page
# then prints the month or year instead of a day. Key = <kind>-<date>-<slug>, slug from `what` unless given (two
# events with the same title in the same approximate period need an explicit slug). Rendered entries go into the
# ledger under the same archival rules as citation entries: once in, never re-rendered.
MONTHS <- c("January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December")
slug_of <- function(x) { w <- str_split_1(str_squish(str_replace_all(str_to_lower(x), "[^a-z0-9 ]", " ")), " ")
  w <- w[!w %in% c("a", "an", "the", "of", "in", "on", "to", "and", "for", "from", "with", "at", "by")]; paste(head(w, 4), collapse = "-") }
manual_entries <- function() {
  if (!file.exists(MANUAL)) return(list())
  ev <- read_yaml(MANUAL) %||% list()
  out <- map(ev, function(e) {
    d <- format(e$date)
    if (!str_detect(d, "^\\d{4}-\\d{2}-\\d{2}$")) stop("manual event '", e$what, "': date must be YYYY-MM-DD (use approx: for month/year)")
    r <- manual_rules[[e$kind]] %||% stop("manual event '", e$what, "': no `trigger: manual` rule with id '", e$kind, "'")
    key <- paste(e$kind, d, e$slug %||% slug_of(e$what), sep = "-")
    extra <- list(what = e$what, where = e$where %||% "", note = e$note %||% "", year = substr(d, 1, 4))
    rw <- reward_of(r, 0, 1, key, extra)
    a <- list(key = key, id = e$kind, date = d, source = "manual",
              title = fill(pick(r$title, key, "title"), 0, 1, NULL, extra), body = fill(pick(r$body %||% "", key, "body"), 0, 1, NULL, extra),
              reward = rw$text, what = e$what)
    if (!is.null(e$approx)) a$when <- switch(e$approx, month = paste(MONTHS[as.integer(substr(d, 6, 7))], substr(d, 1, 4)),
                                              year = substr(d, 1, 4), stop("manual event '", e$what, "': approx must be month or year"))
    if (!is.na(rw$tier)) a$tier <- rw$tier
    if (!is.na(rw$box))  a$box  <- rw$box
    a$rank <- if (is.na(rw$tier)) 0L else match(rw$tier, TIERS)
    a$featured <- TRUE
    a
  })
  k <- map_chr(out, "key"); if (any(d <- duplicated(k))) stop("duplicate manual keys (add a `slug:`): ", paste(unique(k[d]), collapse = ", "))
  out
}
manual <- manual_entries()

if (do_replay) {
  # every consecutive pair, oldest first, so the ledger reads in the order things happened. Existing entries are
  # archival: an entry whose key is already in the ledger is kept exactly as written (its wording, tier and values
  # were earned under the rules of the day), and one the rules no longer produce (a rung moved) is kept too. Only
  # keys never seen before are rendered. --fresh discards the ledger and re-renders everything from today's rules.
  old_ledger <- if (!do_fresh && file.exists(LEDGER)) read_yaml(LEDGER) else list()
  if (is.null(old_ledger)) old_ledger <- list()
  by_key <- set_names(old_ledger, map_chr(old_ledger, ~ .x$key %||% paste(.x$id, .x$date, sep = "-")))
  ledger <- list(); kept <- 0L; added <- 0L; used <- character()
  for (k in seq_len(max(0, length(files) - 1)) + 1) {
    d <- date_of(files[k])
    f <- fire(files[k - 1], files[k], quiet = TRUE)
    is_old <- map_lgl(f, ~ !is.null(by_key[[.x$key]]))
    f <- map2(f, is_old, ~ if (.y) by_key[[.x$key]] else .x)               # earned already: keep as written
    used <- c(used, map_chr(f, "key"))
    # entries earned on this date that today's rules would not fire (e.g. a rung was raised): earned is earned
    orphans <- keep(by_key, ~ identical(.x$date, d) && !identical(.x$source, "manual") && !(.x$key %||% "") %in% used)
    used <- c(used, names(orphans))
    kept <- kept + sum(is_old) + length(orphans); added <- added + sum(!is_old)
    cat(sprintf("%s -> %s: %d fired (%d kept as written, %d new)%s\n", date_of(files[k - 1]), d, length(f), sum(is_old), sum(!is_old),
                if (length(orphans)) sprintf(", %d earned under earlier rules kept", length(orphans)) else ""))
    ledger <- c(ledger, f, unname(orphans))
  }
  # manual events: kept as written when already in, rendered when new; one the file no longer lists stays (earned is earned)
  m_old <- map_lgl(manual, ~ !is.null(by_key[[.x$key]]))
  ledger <- c(ledger, map2(manual, m_old, ~ if (.y) by_key[[.x$key]] else .x))
  used <- c(used, map_chr(manual, "key")); kept <- kept + sum(m_old); added <- added + sum(!m_old)
  m_gone <- keep(by_key, ~ identical(.x$source, "manual") && !(.x$key %||% "") %in% used)
  ledger <- c(ledger, unname(m_gone)); used <- c(used, names(m_gone)); kept <- kept + length(m_gone)
  cat(sprintf("manual events: %d (%d kept as written, %d new)%s\n", length(manual), sum(m_old), sum(!m_old),
              if (length(m_gone)) sprintf(", %d no longer in %s kept", length(m_gone), basename(MANUAL)) else ""))
  # anything left whose date matches no snapshot pair (a snapshot was removed): keep it at the end and say so
  stray <- keep(by_key, ~ !(.x$key %||% "") %in% used)
  if (length(stray)) { cat(sprintf("%d entr%s dated to no current snapshot pair, kept at the end\n", length(stray), if (length(stray) == 1) "y" else "ies")); ledger <- c(ledger, unname(stray)); kept <- kept + length(stray) }
  write_ledger(ledger)
  cat(sprintf("replayed %d snapshot pair%s into %s: %d entries (%d kept, %d added%s)\n", max(0, length(files) - 1), if (length(files) == 2) "" else "s",
              basename(LEDGER), length(ledger), kept, added, if (do_fresh) ", --fresh: all re-rendered" else ""))
  quit(save = "no", status = 0)
}

fired <- list()
if (length(files) >= 2) {
  cat(sprintf("comparing %s -> %s\n", date_of(files[length(files) - 1]), date_of(files[length(files)])))
  fired <- fire(files[length(files) - 1], files[length(files)])
  cat(sprintf("\n%d rule%s fired\n", length(fired), if (length(fired) == 1) "" else "s"))
}

ledger <- if (file.exists(LEDGER)) read_yaml(LEDGER) else list()
if (is.null(ledger)) ledger <- list()
keys <- map_chr(ledger, ~ .x$key %||% paste(.x$id, .x$date, sep = "-"))
pending <- keep(manual, ~ !.x$key %in% keys)
for (a in pending) cat(sprintf("\n[manual %s] %s\nNew achievement! %s\n%s\n%s\n", a$date, a$what, a$title, a$body, a$reward))
cat(sprintf("%d manual event%s not yet in the ledger\n", length(pending), if (length(pending) == 1) "" else "s"))

if (do_log && length(c(fired, pending))) {
  add <- c(keep(fired, ~ !.x$key %in% keys), pending)
  write_ledger(c(ledger, add))
  cat(sprintf("logged %d new (%d already in %s)\n", length(add), length(fired) + length(pending) - length(add), basename(LEDGER)))
}
