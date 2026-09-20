# refresh.R — the citation refresh, in the one order that works:
#   1. fetch_scholar.R        new snapshot in data/scholar/ and www/scholar.json
#   2. check_achievements.R   --log: what fired since the previous snapshot goes into data/achievements_log.yml
#   3. build_tree.R           www/tree.json picks up the per-paper numerals and the origin's career list
# Then render (or push and let CI render) and commit: the snapshot, scholar.json, achievements_log.yml, tree.json.
#
# Usage (from repo root):  Rscript 5_skilltree/R/refresh.R [--no-fetch]
#   --no-fetch   skip step 1 (rebuild ledger + tree from the snapshots already on disk)
# Stops at the first step that fails; nothing downstream runs on a bad snapshot.

suppressPackageStartupMessages(library(here))
args <- commandArgs(trailingOnly = TRUE)
step <- function(script, ...) {
  cat(sprintf("\n==> %s %s\n", script, paste(c(...), collapse = " ")))
  status <- system2("Rscript", c(shQuote(here("5_skilltree", "R", script)), ...))
  if (status != 0) stop(script, " exited with status ", status)
}
if (!"--no-fetch" %in% args) step("fetch_scholar.R")
step("check_achievements.R", "--log")
step("build_tree.R")
cat("\nrefresh done. Commit: 5_skilltree/data/scholar/, www/scholar.json, 5_skilltree/data/achievements_log.yml, www/tree.json\n")
