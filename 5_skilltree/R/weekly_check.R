# weekly_check.R — the unattended Monday citation check (Peter, 2026-10-11).
#
# Runs refresh.R's steps on a schedule, leaves every change UNCOMMITTED, and posts a macOS notification saying what
# moved. It never commits or pushes: each push still needs Peter's yes, in a Claude session ("push the weekly
# refresh"). A quiet week writes nothing; a Scholar block writes nothing. Laptop only: two machines running this
# would race each other on git.
#
# Scheduled by launchd, not CI: Scholar blocks datacenter IPs (see fetch_scholar.R). The agent is
#   ~/Library/LaunchAgents/com.petertanksley.website-weekly-check.plist   (Mondays 08:30; runs on wake if asleep)
# and is machine-local, set up once per machine; see CLAUDE.md "Weekly check".
#   Run now:   launchctl kickstart gui/$(id -u)/com.petertanksley.website-weekly-check
#   By hand:   Rscript 5_skilltree/R/weekly_check.R          (same thing, in the foreground)
#   Log:       ~/Library/Logs/tanksley_website_weekly.log    (one line per step; R output in ..._weekly.out)

suppressPackageStartupMessages({ library(here); library(yaml); library(jsonlite); library(purrr) })
setwd(here())

LOG  <- path.expand("~/Library/Logs/tanksley_website_weekly.log")
SNAP <- here("5_skilltree", "data", "scholar")
LEDGER <- here("5_skilltree", "data", "achievements_log.yml")
say <- function(...) { line <- sprintf("[%s] %s", format(Sys.time(), "%Y-%m-%d %H:%M"), paste0(...)); cat(line, "\n"); cat(line, "\n", file = LOG, append = TRUE, sep = "") }
notify <- function(msg, title = "Website stats") {
  esc <- function(x) gsub('"', "'", x)
  system2("osascript", c("-e", shQuote(sprintf('display notification "%s" with title "%s" sound name "Glass"', esc(msg), esc(title)))))
}
rscript <- file.path(R.home("bin"), "Rscript")
step <- function(script, ...) system2(rscript, c(shQuote(here("5_skilltree", "R", script)), ...))
git  <- function(...) suppressWarnings(system2("git", c(...), stdout = TRUE, stderr = TRUE))

# ---- 0. stay in step with GitHub -------------------------------------------------------------------
# Fast-forward when the tree is clean, so the refresh lands on top of whatever the other clone pushed. With local
# changes present (e.g. last week's unreviewed refresh) it runs on what is here and says so; nothing is merged.
git("fetch", "-q")
dirty  <- length(git("status", "--porcelain")) > 0
behind <- suppressWarnings(as.integer(git("rev-list", "--count", "HEAD..@{u}")[1]))
notes  <- character()
if (isTRUE(behind > 0)) {
  if (!dirty) { git("merge", "--ff-only", "-q", "@{u}"); say("fast-forwarded ", behind, " commit(s) from GitHub") }
  else notes <- c(notes, sprintf("%d commit(s) behind GitHub, not pulled (local changes)", behind))
}

# ---- 1. fetch --------------------------------------------------------------------------------------
newest <- function() tail(sort(list.files(SNAP, pattern = "^\\d{4}-\\d{2}-\\d{2}\\.json$", full.names = TRUE)), 1)
old    <- read_json(newest())                                   # read now: a same-day rerun overwrites that file
keys   <- function() { l <- if (file.exists(LEDGER)) read_yaml(LEDGER) else NULL; map_chr(l %||% list(), "key") }
k0     <- keys()
stats  <- function(s) sprintf("%s citations, h %s, i10 %s", s$scholar$citations, s$scholar$h_index, s$scholar$i10)

st <- step("fetch_scholar.R", "--skip-unchanged")
if (st == 3) { say("Scholar unreachable or blocking; nothing written"); notify("Google Scholar blocked this week's check. Nothing changed; it tries again next Monday."); quit(save = "no") }
if (st == 4) { say("no change (", stats(old), ")"); notify(paste0("No change this week: ", stats(old), ".", if (length(notes)) paste0(" Note: ", notes[1], ".") else "")); quit(save = "no") }
if (st != 0) { say("fetch_scholar.R failed, status ", st); notify("The weekly check failed at the Scholar fetch. See ~/Library/Logs/tanksley_website_weekly.out", "Website stats: error"); quit(save = "no", status = 1) }

# ---- 2. achievements + tree ------------------------------------------------------------------------
if (step("check_achievements.R", "--log") != 0) { say("check_achievements.R failed"); notify("The weekly check failed at check_achievements.R. Snapshot written, ledger not.", "Website stats: error"); quit(save = "no", status = 1) }
if (step("build_tree.R") != 0)                  { say("build_tree.R failed"); notify("The weekly check failed at build_tree.R. Snapshot and ledger written, tree not.", "Website stats: error"); quit(save = "no", status = 1) }

# ---- 3. report -------------------------------------------------------------------------------------
new   <- read_json(newest())
delta <- function(f, lab) { a <- old$scholar[[f]]; b <- new$scholar[[f]]; if (identical(a, b)) sprintf("%s %s", lab, b) else sprintf("%s %s -> %s", lab, a, b) }
moved <- paste(delta("citations", "citations"), delta("h_index", "h"), delta("i10", "i10"), sep = ", ")
fired <- keep(read_yaml(LEDGER) %||% list(), ~ !.x$key %in% k0)
ach   <- if (length(fired)) sprintf(" %d new achievement%s: %s", length(fired), if (length(fired) == 1) "" else "s",
                                    paste0("“", map_chr(fired, "title"), "”", collapse = ", ")) else ""
say("refreshed: ", moved, ";", if (nzchar(ach)) ach else " no achievements", if (length(notes)) paste0("; ", notes, collapse = "") else "")
notify(paste0(moved, ".", ach, " Uncommitted: ask Claude to push."), "Website stats updated")
