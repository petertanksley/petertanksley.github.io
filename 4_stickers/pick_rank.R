# pick_rank.R — promote one candidate to a career-rank sticker (2026-09-27).
#
# The rank analogue of pick_sticker.R. Frames 4_stickers/ranks/<id>-<n>.png to www/hex/<id>.png (480x554 point-up
# hex), archives the winner's unframed square to 4_stickers/finals_src/<id>.<ext> (committed), then rebuilds
# www/tree.json and www/hex/sm/ via build_tree.R. No YAML edit: 5_skilltree/data/ranks.yml names each rank's
# sticker statically, so the id here must be one of those `sticker` values (rank_student, rank_postdoc, ...).
#
# Usage (from repo root):  Rscript 4_stickers/pick_rank.R <id> <n> [--no-build]

suppressPackageStartupMessages({ library(here); library(yaml); library(purrr); library(magick) })
source(here("4_stickers", "frame_hex.R"))

args <- commandArgs(trailingOnly = TRUE)
id <- args[1]; n <- suppressWarnings(as.integer(args[2])); no_build <- "--no-build" %in% args
if (is.na(id) || is.na(n)) stop("usage: Rscript 4_stickers/pick_rank.R <id> <n> [--no-build]")

ranks <- read_yaml(here("5_skilltree", "data", "ranks.yml"))
if (!id %in% map_chr(ranks, "sticker")) stop("'", id, "' is not a sticker named in ranks.yml (", paste(map_chr(ranks, "sticker"), collapse = ", "), ")")
cand  <- here("4_stickers", "ranks", sprintf("%s-%d.png", id, n))
final <- here("www", "hex", paste0(id, ".png"))
if (!file.exists(cand)) stop("candidate not found: ", cand)

frame_hex(cand, final, height = 554)
info <- image_info(image_read(final))
stopifnot(info$width == 480, info$height == 554, info$format == "PNG")

# archive the winner's square verbatim under its true extension (Gemini squares are usually JPEG in a .png name)
src_dir <- here("4_stickers", "finals_src"); dir.create(src_dir, showWarnings = FALSE)
ext <- tolower(image_info(image_read(cand))$format); ext <- if (ext == "jpeg") "jpg" else ext
invisible(file.copy(cand, file.path(src_dir, paste0(id, ".", ext)), overwrite = TRUE))
cat(sprintf("%s: candidate %d -> %s (%dx%d); square archived to finals_src/%s.%s\n", id, n, final, info$width, info$height, id, ext))

if (!no_build) {
  status <- system2("Rscript", here("5_skilltree", "R", "build_tree.R"))
  if (status != 0) stop("build_tree.R failed with status ", status)
}
