# check_achievements.R — diff the two newest citation snapshots against data/achievements.yml and print
# what would fire. Data layer only: nothing is posted to news.yml yet (that is the next pass).
#
# Usage (from repo root):  Rscript 5_skilltree/R/check_achievements.R [--dir <snapshot dir>]
# Exit 0 always; with fewer than two snapshots it says so and stops.

suppressPackageStartupMessages({ library(here); library(yaml); library(jsonlite); library(purrr); library(stringr) })
args <- commandArgs(trailingOnly = TRUE)
snap_dir <- if (any(i <- args == "--dir")) args[which(i)[1] + 1] else here("5_skilltree", "data", "scholar")
rules <- read_yaml(here("5_skilltree", "data", "achievements.yml"))

files <- sort(list.files(snap_dir, pattern = "^\\d{4}-\\d{2}-\\d{2}\\.json$", full.names = TRUE))
if (length(files) < 2) { cat("no previous snapshot in", snap_dir, "; nothing to compare\n"); quit(save = "no", status = 0) }
old <- read_json(files[length(files) - 1]); new <- read_json(files[length(files)])
cat(sprintf("comparing %s -> %s\n", basename(files[length(files) - 1]), basename(files[length(files)])))

dig <- function(x, path) { for (k in str_split_1(path, fixed("."))) { x <- x[[k]]; if (is.null(x)) return(NA) }; if (is.null(x)) NA else as.numeric(x) }
fill <- function(tpl, o, n) str_replace_all(str_squish(tpl), fixed(c("{old}" = format(o), "{new}" = format(n), "{delta}" = format(n - o))))

fired <- 0
for (r in rules) {
  o <- dig(old, r$metric); n <- dig(new, r$metric)
  if (is.na(n)) next
  if (is.na(o)) o <- 0                                       # a metric that did not exist yet (e.g. an uncited paper) counts as 0
  hit <- switch(r$trigger,
    step      = n > o,
    round     = (n %/% r$every) > (o %/% r$every),
    threshold = n >= r$at && o < r$at,
    stop("unknown trigger '", r$trigger, "' in rule ", r$id))
  if (hit) {
    fired <- fired + 1
    cat(sprintf("\n[%s] %s: %s -> %s\n  %s\n  %s\n", r$id, r$metric, format(o), format(n), fill(r$title, o, n), fill(r$reward, o, n)))
  }
}
cat(sprintf("\n%d rule%s would fire\n", fired, if (fired == 1) "" else "s"))
