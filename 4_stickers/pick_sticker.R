# pick_sticker.R — promote one candidate to an article's final sticker.
#
# Frames 4_stickers/articles/<id>-<n>.png to www/hex/<id>.png (480x554 point-up hex, the site
# convention), archives the winner's unframed square to 4_stickers/finals_src/<id>.png (committed,
# so a final can be reframed anywhere), sets `sticker: <id>` on the article in
# 5_skilltree/data/articles.yml through the rating app's helpers (header and field order preserved),
# then rebuilds www/tree.json and www/hex/sm/ via build_tree.R. The sticker name IS the article id.
#
# Usage (from repo root):  Rscript 4_stickers/pick_sticker.R <id> <n> [--no-build]

suppressPackageStartupMessages({ library(here); library(yaml); library(purrr); library(stringr); library(magick) })
source(here("4_stickers", "frame_hex.R"))
source(here("5_skilltree", "tools", "rate_articles", "helpers.R"))

args <- commandArgs(trailingOnly = TRUE)
id <- args[1]; n <- suppressWarnings(as.integer(args[2])); no_build <- "--no-build" %in% args
if (is.na(id) || is.na(n)) stop("usage: Rscript 4_stickers/pick_sticker.R <id> <n> [--no-build]")

ARTICLES_YML <- here("5_skilltree", "data", "articles.yml")
cand  <- here("4_stickers", "articles", sprintf("%s-%d.png", id, n))
final <- here("www", "hex", paste0(id, ".png"))
if (!file.exists(cand)) stop("candidate not found: ", cand)

a <- read_articles(ARTICLES_YML)
idx <- match(id, map_chr(a$entries, "id"))
if (is.na(idx)) stop("unknown article id: ", id)

frame_hex(cand, final, height = 554)
info <- image_info(image_read(final))
stopifnot(info$width == 480, info$height == 554, info$format == "PNG")

# archive the winner's unframed square (committed) so the final can be reframed on any machine;
# the losing candidates stay gitignored scratch in 4_stickers/articles/ (2026-09-18)
# Bytes are copied verbatim under their TRUE extension: Gemini squares are usually JPEG despite the
# .png name, and re-encoding them as PNG doubles the size for nothing.
src_dir <- here("4_stickers", "finals_src"); dir.create(src_dir, showWarnings = FALSE)
ext <- tolower(image_info(image_read(cand))$format); ext <- if (ext == "jpeg") "jpg" else ext
invisible(file.copy(cand, file.path(src_dir, paste0(id, ".", ext)), overwrite = TRUE))

a$entries[[idx]] <- set_nullable(a$entries[[idx]], "sticker", id)
write_articles(ARTICLES_YML, a$header, a$entries)
cat(sprintf("%s: candidate %d -> %s (%dx%d); sticker field set\n", id, n, final, info$width, info$height))

if (!no_build) {
  status <- system2("Rscript", here("5_skilltree", "R", "build_tree.R"))
  if (status != 0) stop("build_tree.R failed with status ", status)
}
