# preview_candidates.R — contact sheet for judging an article's sticker candidates AFTER hex-clipping.
#
# House rule (CLAUDE.md, "Hex stickers"): judge candidates framed, not square, and at the 92 px the
# CV band uses. This frames every 4_stickers/articles/<id>-<n>.png through frame_hex() at final size
# (554 tall), puts the article's parent finals (if any) on the left so inheritance can be judged
# side by side, and stacks a 92 px row beneath. Output:
#   4_stickers/articles/_preview/<id>_contact.png          (gitignored with the candidates)
#
# Usage (from repo root):  Rscript 4_stickers/preview_candidates.R <id>

suppressPackageStartupMessages({ library(here); library(yaml); library(purrr); library(magick) })
source(here("4_stickers", "frame_hex.R"))

id <- commandArgs(trailingOnly = TRUE)[1]
if (is.na(id)) stop("usage: Rscript 4_stickers/preview_candidates.R <id>")

CAND_DIR <- here("4_stickers", "articles")
PREV_DIR <- file.path(CAND_DIR, "_preview", id)
HEX_DIR  <- here("www", "hex")
SMALL_PX <- 92
dir.create(PREV_DIR, recursive = TRUE, showWarnings = FALSE)

arts  <- read_yaml(here("5_skilltree", "data", "articles.yml"))
by_id <- set_names(arts, map_chr(arts, "id"))
if (is.null(by_id[[id]])) stop("unknown article id: ", id)

cands <- sort(list.files(CAND_DIR, pattern = paste0("^", id, "-\\d+\\.png$"), full.names = TRUE))
if (!length(cands)) stop("no candidates for ", id, " in ", CAND_DIR, " — run compose + bananarama first")

# frame each candidate at final size
framed <- map_chr(cands, function(p) {
  out <- file.path(PREV_DIR, basename(p)); frame_hex(p, out, height = 554); out
})
labels <- sub("\\.png$", "", basename(cands))

# parent finals, left of the candidates, so the eye reads parent -> child
parents <- as.character(unlist(by_id[[id]]$builds_on))
parent_files <- vapply(parents, function(p) file.path(HEX_DIR, paste0(by_id[[p]]$sticker %||% "", ".png")), character(1))
have <- file.exists(parent_files)
tiles  <- c(unname(parent_files[have]), framed)
labels <- c(paste0("parent: ", parents[have], recycle0 = TRUE), labels)   # recycle0: no phantom label when there are no parents

label_tile <- function(path, label, h) {
  img <- image_read(path) |> image_resize(paste0("x", h)) |> image_background("#1C1B22", flatten = TRUE)
  if (h >= 200) img <- image_annotate(img, label, size = 22, color = "#FBFAF7", gravity = "south", location = "+0+8")
  image_border(img, "#1C1B22", "16x16")
}
row_big   <- image_append(do.call(c, map2(tiles, labels, label_tile, h = 554)))
row_small <- image_append(do.call(c, map2(tiles, labels, label_tile, h = SMALL_PX)))
sheet <- image_append(c(row_big, row_small), stack = TRUE) |> image_background("#1C1B22", flatten = TRUE)

out <- file.path(CAND_DIR, "_preview", paste0(id, "_contact.png"))
image_write(sheet, out, format = "png")
cat(sprintf("%s: %d candidate%s%s -> %s\n", id, length(cands), if (length(cands) == 1) "" else "s",
            if (length(parent_files)) sprintf(" (+%d parent)", length(parent_files)) else "", out))
