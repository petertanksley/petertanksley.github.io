# build_tree.R — validate 5_skilltree/data/articles.yml, lay the articles out on a point-up hex lattice,
# write www/tree.json for the renderer, and downscale stickers into www/hex/sm/.
#
# Layout: concentric hexagonal rings on a hex lattice. Ring k holds the articles from year
# (FIRST_YEAR + k - 1), so the tree grows outward like a stump. Three axes leave the origin 120
# degrees apart through alternating corners of the rings: biosocial (up-left), criminology
# (down-left), first-responder occupational (right). An article's direction is the vector sum of
# its 0-3 area ratings along those axes, so a pure paper sits on its axis and a 2/2/0 paper sits
# on the corner between two axes. On its year ring it takes the free cell nearest that angle
# (purest articles placed first). The origin cell holds Peter. Same hex geometry as the site's
# 4_stickers/hexband.R (h = w / 0.866, alternate rows offset half a cell).
#
# Run from the site repo root:  Rscript 5_skilltree/R/build_tree.R
# Outputs (www/tree.json, www/hex/sm/) are COMMITTED: CI renders the site without R.

suppressPackageStartupMessages({
  library(here); library(yaml); library(jsonlite); library(purrr); library(magick)
})

hex_src  <- here("www", "hex")
hex_out  <- here("www", "hex", "sm")
json_out <- here("www", "tree.json")
dir.create(hex_out, recursive = TRUE, showWarnings = FALSE)

# ---- constants ------------------------------------------------------------------------------
AREAS     <- c(biosocial = "Biosocial", criminology = "Criminology", responders = "First responders")
# dark-theme area colours: the site's teal / indigo / belt-red lifted so they read on an ink ground
AREA_COL  <- c(biosocial = "#3FBDB6", criminology = "#A47FE0", responders = "#E2574B")
BLANK_DARK <- "#6E6A80"        # placeholder hex colour; sits dimmed to ~#33313E at rest (see skilltree.scss)
ROLES     <- c("lead", "contributing")   # co-lead dropped 2026-09-10: never used
STATUSES  <- c("published", "in_press", "preprint")
CREDIT    <- c("conceptualization", "data", "analysis", "methods", "writing", "supervision")

W   <- 100                     # hex width in viewBox units (the SVG scales to its container)
GAP <- 4
H   <- W / 0.866
DX  <- W + GAP                 # column pitch
DY  <- DX * sqrt(3) / 2        # row pitch: exact triangular lattice so the triangle's vertices land on cells
AXIS_DEG   <- c(biosocial = 240, criminology = 120, responders = 0)   # screen angles, clockwise from +x
FIRST_YEAR <- 2019             # sits on ring FIRST_RING; ring 0 is the origin
FIRST_RING <- 2                # ring 1 stays empty as a halo round the origin; it also has only 6 cells (60-degree steps),
                               # too coarse to place a 2/2/0 paper honestly once its corner is taken
ORIGIN_STICKER <- "puzzled"    # site sticker for the centre cell (Peter); falls back to blank
LABEL_PAD  <- 40               # room beyond the outer ring for axis/year labels
STICKER_PX <- 220              # downscaled sticker width; finals are 1200 px / ~300 KB, far too heavy

# ---- read + validate ------------------------------------------------------------------------
arts <- read_yaml(here("5_skilltree", "data", "articles.yml"))
stopifnot(length(arts) > 0)
ids <- map_chr(arts, "id")
problems <- character()
note <- function(...) problems <<- c(problems, sprintf(...))
if (anyDuplicated(ids)) note("duplicate ids: %s", paste(unique(ids[duplicated(ids)]), collapse = ", "))
for (a in arts) {
  ar <- unlist(a$areas)
  if (!setequal(names(a$areas), names(AREAS))) note("%s: areas keys must be exactly %s", a$id, paste(names(AREAS), collapse = ", "))
  else if (length(ar) < 3) note("%s: areas not rated (will sit at the centre of the triangle)", a$id)
  else if (any(ar < 0 | ar > 3) || sum(ar) == 0) note("%s: area ratings must be 0-3 and not all zero", a$id)
  if (is.null(a$role) || !a$role %in% ROLES) note("%s: role must be one of %s", a$id, paste(ROLES, collapse = "/"))
  if (is.null(a$status) || !a$status %in% STATUSES) note("%s: status must be one of %s", a$id, paste(STATUSES, collapse = "/"))
  if (is.null(a$year) || is.null(a$title)) note("%s: title/year missing", a$id)
  bad <- setdiff(a$builds_on, ids); if (length(bad)) note("%s: builds_on refers to unknown id(s) %s", a$id, paste(bad, collapse = ", "))
  if (!setequal(names(a$contribution), CREDIT)) note("%s: contribution keys must be exactly %s", a$id, paste(CREDIT, collapse = ", "))
  scores <- unlist(a$contribution); if (length(scores) && any(scores < 0 | scores > 3)) note("%s: contribution scores must be 0-3", a$id)
  if (!is.null(a$effort) && (a$effort < 1 || a$effort > 5)) note("%s: effort must be 1-5", a$id)
  if (is.null(a$doi) && is.null(a$url) && a$status != "in_press") note("%s: no DOI or URL", a$id)
}
hard <- problems[!grepl("not rated", problems)]
if (length(hard)) stop("articles.yml failed validation:\n  ", paste(hard, collapse = "\n  "))
if (length(problems)) message("Warnings:\n  ", paste(problems, collapse = "\n  "))

# ---- layout ---------------------------------------------------------------------------------
years  <- map_int(arts, "year")
n_ring <- max(years) - FIRST_YEAR + FIRST_RING
if (min(years) < FIRST_YEAR) stop("FIRST_YEAR is ", FIRST_YEAR, " but an article is dated ", min(years))
R_out  <- (n_ring + 1.6) * DX                       # axis length; labels sit beyond it
cx0 <- R_out + LABEL_PAD + 160                      # origin (room for the left-hand axis labels)
cy0 <- R_out + LABEL_PAD
RIGHT_LABEL_W <- 330                                # "First responders" at 36px, start-anchored past the axis tip
deg2rad <- function(d) d * pi / 180
unit <- function(deg) c(cos(deg2rad(deg)), sin(deg2rad(deg)))
U <- t(sapply(AXIS_DEG, unit))                      # 3 x 2 unit vectors, rows named by area

# axial coordinates (q, r) → pixel, pointy-top lattice: x = DX (q + r/2), y = DY r
ring_cells <- function(k) {
  g <- expand.grid(q = -k:k, r = -k:k)
  g <- g[(abs(g$q) + abs(g$r) + abs(g$q + g$r)) / 2 == k, ]
  g$x <- cx0 + DX * (g$q + g$r / 2); g$y <- cy0 + DY * g$r
  g$deg <- (atan2(g$y - cy0, g$x - cx0) * 180 / pi) %% 360
  g$taken <- FALSE
  g
}
rings <- lapply(seq_len(n_ring), ring_cells)
ring_of <- function(year) year - FIRST_YEAR + FIRST_RING
year_of <- function(k) k - FIRST_RING + FIRST_YEAR

weights_of <- function(a) {
  ar <- unlist(a$areas[names(AREAS)])
  if (length(ar) < 3 || sum(ar) == 0) return(setNames(rep(1 / 3, 3), names(AREAS)))
  ar / sum(ar)
}
mix_colour <- function(w) {                        # weighted mean in CIE Lab so mixes stay vivid-ish
  lab <- convertColor(t(col2rgb(AREA_COL[names(w)])) / 255, from = "sRGB", to = "Lab")
  mix <- colSums(w * lab)
  if (sum(w > 0) > 1) mix[1] <- max(mix[1], 42)          # blends of dark hues go near-black; keep them legible
  m   <- convertColor(matrix(mix, 1), from = "Lab", to = "sRGB")
  m   <- pmin(pmax(m, 0), 1); rgb(m[1], m[2], m[3])
}
ang_dist <- function(a, b) { d <- abs(a - b) %% 360; pmin(d, 360 - d) }

placed <- vector("list", length(arts))
info <- data.frame(i = seq_along(arts), year = years, cv = map_int(arts, ~ .x$cv_number %||% 999L))
info$w <- lapply(arts, weights_of)
info$vec <- lapply(info$w, function(w) colSums(w * U))
info$purity <- sapply(info$vec, function(v) sqrt(sum(v^2)))                 # 1 = pure, 0 = equal thirds
info$deg <- sapply(info$vec, function(v) if (sqrt(sum(v^2)) < 1e-6) 270 else (atan2(v[2], v[1]) * 180 / pi) %% 360)
# purest first so axis corners go to the papers that belong there; then oldest CV number
info <- info[order(info$year, -info$purity, info$cv), ]
for (j in seq_len(nrow(info))) {
  i <- info$i[j]; k <- ring_of(info$year[j])
  cells <- rings[[k]]
  d <- ang_dist(cells$deg, info$deg[j]); d[cells$taken] <- Inf
  if (all(is.infinite(d))) stop("ring ", k, " (", info$year[j], ") is full: ", 6 * k, " cells")
  m <- which.min(d); rings[[k]]$taken[m] <- TRUE
  w <- info$w[[j]]
  placed[[i]] <- list(weights = as.list(w), dominant = if (sum(w == max(w)) > 1) "mixed" else names(w)[which.max(w)],
                      colour = mix_colour(w), x = cells$x[m], y = cells$y[m], ring = k, q = cells$q[m], r = cells$r[m],
                      target_deg = info$deg[j], angle_error = ang_dist(cells$deg[m], info$deg[j]), purity = info$purity[j])
}

# ring guides: the hexagon through ring k's six corner cells (corners at 0, 60, ... 300 degrees, radius k DX)
ring_path <- function(k) {
  pts <- t(sapply(seq(0, 300, 60), function(d) c(cx0, cy0) + k * DX * unit(d)))
  paste0("M", paste(sprintf("%.1f,%.1f", pts[, 1], pts[, 2]), collapse = "L"), "Z")
}
# year label on the top edge of each ring (270 degrees), over a free cell if one exists
year_label_pos <- function(k) {
  top <- rings[[k]][rings[[k]]$r == -k, ]                   # the ring's top edge cells
  free <- top[!top$taken, ]
  x <- if (nrow(free)) free$x[which.min(abs(free$x - cx0))] else top$x[which.min(abs(top$x - cx0))]
  c(x = x, y = cy0 - k * DY, over_hex = nrow(free) == 0)
}
canvas_w <- cx0 + R_out + 46 + RIGHT_LABEL_W
canvas_h <- 2 * cy0

# ---- stickers -------------------------------------------------------------------------------
sticker_name <- map_chr(arts, ~ .x$sticker %||% "blank")
for (s in unique(c(sticker_name, ORIGIN_STICKER))) {
  src <- file.path(hex_src, paste0(s, ".png")); dst <- file.path(hex_out, paste0(s, ".png"))
  if (!file.exists(src)) { warning("sticker '", s, "' not found in ", hex_src, "; using blank"); next }
  if (!file.exists(dst) || file.mtime(src) > file.mtime(dst)) {
    image_read(src) |> image_resize(paste0(STICKER_PX, "x")) |> image_write(dst, format = "png")
  }
}
sticker_name[!file.exists(file.path(hex_out, paste0(sticker_name, ".png")))] <- "blank"
# dark-theme placeholder: same hex mask as blank.png, filled with BLANK_DARK (ink-on-ink would vanish)
blank_src <- file.path(hex_out, "blank.png"); blank_dark <- file.path(hex_out, "blank_dark.png")
if (file.exists(blank_src) && (!file.exists(blank_dark) || file.mtime(blank_src) > file.mtime(blank_dark))) {
  bl <- image_read(blank_src); inf <- image_info(bl)
  image_composite(image_blank(inf$width, inf$height, BLANK_DARK), bl, operator = "CopyOpacity") |>
    image_write(blank_dark, format = "png")
}
sticker_name[sticker_name == "blank" & file.exists(blank_dark)] <- "blank_dark"
origin_sticker <- if (file.exists(file.path(hex_out, paste0(ORIGIN_STICKER, ".png")))) ORIGIN_STICKER else "blank"

# ---- assemble JSON --------------------------------------------------------------------------
na_if_null <- function(x) if (is.null(x)) NA else x
nodes <- map2(arts, seq_along(arts), function(a, i) {
  r <- placed[[i]]
  list(
    id = a$id, title = a$title, year = a$year, venue = na_if_null(a$venue),
    doi = na_if_null(a$doi), url = na_if_null(a$url), citation = na_if_null(a$citation),
    link = if (!is.null(a$doi)) paste0("https://doi.org/", a$doi) else na_if_null(a$url),
    cv_number = na_if_null(a$cv_number), authors_n = na_if_null(a$authors_n),
    author_position = na_if_null(a$author_position),
    role = a$role, status = a$status, featured = isTRUE(a$featured),
    areas = map(a$areas[names(AREAS)], na_if_null), weights = map(r$weights, ~ round(.x, 3)),
    dominant = r$dominant, colour = r$colour,
    contribution = map(a$contribution[CREDIT], na_if_null),
    scored = !any(map_lgl(a$contribution[CREDIT], is.null)),
    effort = na_if_null(a$effort), effort_note = na_if_null(a$effort_note), blurb = na_if_null(a$blurb),
    sticker_src = paste0("www/hex/sm/", sticker_name[i], ".png"),
    x = round(r$x, 1), y = round(r$y, 1), ring = r$ring, q = r$q, r = r$r,
    angle = round(r$target_deg, 1), angle_error = round(r$angle_error, 1), purity = round(r$purity, 3)
  )
})
# lineage edges: parent → child, trimmed to the hex borders so they read as connectors, carrying both
# end colours so the renderer can run a gradient from parent to child
# Two idioms: neighbouring hexes (one cell apart) get a short "bridge" welded across their shared border,
# drawn above the tiles; anything further gets a curve trimmed to the hex borders, drawn beneath.
EDGE_TRIM   <- W * 0.54
BRIDGE_TRIM <- W * 0.36                              # leaves ~0.28 W spanning the gap between neighbours
edges <- flatten(map(seq_along(arts), function(i) map(arts[[i]]$builds_on, function(p) {
  from <- placed[[match(p, ids)]]; to <- placed[[i]]
  v <- c(to$x - from$x, to$y - from$y); len <- sqrt(sum(v^2)); u <- v / len
  adjacent <- len < 1.3 * DX
  trim <- if (adjacent) BRIDGE_TRIM else EDGE_TRIM
  a <- c(from$x, from$y) + u * trim; b <- c(to$x, to$y) - u * trim
  list(from = p, to = ids[i], x1 = round(a[1], 1), y1 = round(a[2], 1), x2 = round(b[1], 1), y2 = round(b[2], 1),
       from_colour = from$colour, to_colour = to$colour, length_cells = round(len / DX, 2), adjacent = adjacent)
})))

tree <- list(
  meta = list(
    generated = format(Sys.time(), "%Y-%m-%d %H:%M"),
    hex_w = W, hex_h = round(H, 2), width = round(canvas_w), height = round(canvas_h),
    origin = list(x = cx0, y = cy0, scale = 1.45, sticker_src = paste0("www/hex/sm/", origin_sticker, ".png")),
    axes = map(names(AREAS), function(k) {
      u <- unit(AXIS_DEG[[k]]); tip <- c(cx0, cy0) + R_out * u; lab <- c(cx0, cy0) + (R_out + 46) * u
      list(key = k, label = unname(AREAS[k]), colour = unname(AREA_COL[k]), deg = AXIS_DEG[[k]],
           x1 = round(cx0 + DX * 0.6 * u[1], 1), y1 = round(cy0 + DX * 0.6 * u[2], 1), x2 = round(tip[1], 1), y2 = round(tip[2], 1),
           label_x = round(lab[1], 1), label_y = round(lab[2], 1),
           anchor = if (abs(u[1]) < 0.1) "middle" else if (u[1] > 0) "start" else "end")
    }),
    rings = map(seq(FIRST_RING, n_ring), function(k) { yl <- year_label_pos(k)
      list(k = k, year = year_of(k), path = ring_path(k), n_cells = 6 * k, n_used = sum(rings[[k]]$taken),
           label_x = round(unname(yl["x"]), 1), label_y = round(unname(yl["y"]), 1), label_over_hex = as.logical(yl["over_hex"])) }),
    areas = names(AREAS), credit = CREDIT
  ),
  nodes = nodes, edges = edges
)
write_json(tree, json_out, auto_unbox = TRUE, pretty = TRUE, na = "null", null = "null", digits = NA)

dom <- table(factor(map_chr(nodes, "dominant"), c(names(AREAS), "mixed")))
cat(sprintf("tree.json: %d nodes, %d edges; canvas %d x %d; rings %d-%d hold %d-%d; dominant area: %s; max angle error %.0f deg\n",
            length(nodes), length(edges), round(canvas_w), round(canvas_h), FIRST_RING, n_ring, FIRST_YEAR, year_of(n_ring),
            paste(sprintf("%s=%d", names(dom), dom), collapse = ", "), max(map_dbl(nodes, "angle_error"))))
cat("ring occupancy:", paste(sprintf("%d:%d/%d", map_int(tree$meta$rings, "year"), map_int(tree$meta$rings, "n_used"), map_int(tree$meta$rings, "n_cells")), collapse = "  "), "\n")
cat(sprintf("stickers: %d unique in www/hex/sm/ (%s); %d of %d nodes scored\n",
            length(unique(sticker_name)), paste(unique(sticker_name), collapse = ", "),
            sum(map_lgl(nodes, "scored")), length(nodes)))
