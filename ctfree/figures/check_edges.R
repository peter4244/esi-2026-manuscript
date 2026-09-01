#!/usr/bin/env Rscript
# Does any ink touch the canvas edge?
#
# validate_layout checks font sizes but explicitly cannot detect text
# clipping; its own header says the author must eyeball the PNG. Eyeballing
# missed a clipped axis label four times in a row this session, so this checks
# it instead: if a label is cut off, its ink runs into the outermost pixels.
# A clean figure has a margin of blank pixels on all four sides.
suppressPackageStartupMessages(library(png))
MARGIN_MIN <- 3L   # pixels of blank border required on each side

check_edges <- function(path, margin_min = MARGIN_MIN) {
  img <- readPNG(path)
  # Any pixel that is not white (allowing for antialiasing) counts as ink.
  ink <- if (length(dim(img)) == 3) {
    apply(img[, , 1:3, drop = FALSE], c(1, 2), function(v) any(v < 0.98))
  } else img < 0.98
  rows <- which(apply(ink, 1, any)); cols <- which(apply(ink, 2, any))
  if (!length(rows)) return(data.frame(file = basename(path), top = NA, bottom = NA,
                                       left = NA, right = NA, ok = NA))
  m <- data.frame(file = basename(path),
                  top = min(rows) - 1L, bottom = nrow(ink) - max(rows),
                  left = min(cols) - 1L, right = ncol(ink) - max(cols),
                  stringsAsFactors = FALSE)
  m$ok <- with(m, top >= margin_min & bottom >= margin_min &
                  left >= margin_min & right >= margin_min)
  m
}

args <- commandArgs(trailingOnly = TRUE)
if (!length(args)) {
  .b <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  here <- if (length(.b)) dirname(normalizePath(sub("^--file=", "", .b[1]))) else "."
  args <- list.files(here, pattern = "\\.png$", full.names = TRUE)
}
res <- do.call(rbind, lapply(args, check_edges))
print(res, row.names = FALSE)
if (any(!res$ok, na.rm = TRUE))
  stop("ink touches the canvas edge in: ",
       paste(res$file[!res$ok], collapse = ", "),
       " -- a label is clipped or flush against the border")
cat("all figures clear the canvas edge\n")
