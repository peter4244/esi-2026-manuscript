# Compare the cluster run's aggregate outputs (ctfree/assets/) with the laptop's (ctfree_assets_laptop/,
# copied from the clone before the run). Run from the clone root:  Rscript ctfree_compare_assets.R
# Every file compared is an aggregate table; nothing participant-level is read or printed.

# Baseline folder: first argument, default ctfree_assets_laptop (the first reproduction).
.a <- commandArgs(trailingOnly = TRUE)
A <- if (length(.a)) .a[1] else "ctfree_assets_laptop"; B <- file.path("ctfree", "assets")
files <- sort(list.files(A, pattern = "\\.csv$"))
files <- setdiff(files, "VERIFICATION.csv")   # verify.R's own output, compared separately by its PASS line
rows <- list(); cells <- list()
for (f in files) {
  pb <- file.path(B, f)
  if (!file.exists(pb)) { rows[[f]] <- data.frame(file = f, status = "MISSING on cluster"); next }
  a <- read.csv(file.path(A, f), stringsAsFactors = FALSE, check.names = FALSE)
  b <- read.csv(pb, stringsAsFactors = FALSE, check.names = FALSE)
  if (!identical(dim(a), dim(b)) || !identical(names(a), names(b))) {
    rows[[f]] <- data.frame(file = f, status = sprintf("SHAPE laptop %dx%d cluster %dx%d",
                            nrow(a), ncol(a), nrow(b), ncol(b))); next
  }
  num <- vapply(a, is.numeric, TRUE) & vapply(b, is.numeric, TRUE)
  txt_mis <- sum(vapply(names(a)[!num], function(k)
    sum(as.character(a[[k]]) != as.character(b[[k]]), na.rm = TRUE) +
    sum(is.na(a[[k]]) != is.na(b[[k]])), 0))
  na_mis <- 0; maxabs <- 0; maxrel <- 0; nrel <- 0
  for (k in names(a)[num]) {
    x <- a[[k]]; y <- b[[k]]
    # non-finite cells (NA, NaN, Inf) must match exactly; finite cells are compared numerically
    fx <- is.finite(x); fy <- is.finite(y)
    na_mis <- na_mis + sum(fx != fy) + sum(!fx & !fy & (as.character(x) != as.character(y)), na.rm = TRUE)
    w <- fx & fy
    d <- abs(x[w] - y[w]); r <- d / pmax(abs(x[w]), 1e-12)
    if (length(d)) {
      maxabs <- max(maxabs, d); maxrel <- max(maxrel, r); nrel <- nrel + sum(r > 1e-6)
      idx <- which(r > 1e-6)
      if (length(idx)) cells[[length(cells) + 1]] <- data.frame(file = f, row = which(w)[idx],
        key = as.character(a[[1]][which(w)[idx]]), column = k, laptop = x[w][idx], cluster = y[w][idx],
        rel_diff = r[idx])
    }
  }
  st <- if (txt_mis + na_mis + nrel == 0) "SAME" else "DIFFERS"
  rows[[f]] <- data.frame(file = f, status = st, text_mismatch = txt_mis, na_mismatch = na_mis,
                          cells_reldiff_gt_1e6 = nrel, max_abs = signif(maxabs, 3), max_rel = signif(maxrel, 3))
}
tab <- do.call(rbind, lapply(rows, function(r) { for (k in c("text_mismatch", "na_mismatch",
  "cells_reldiff_gt_1e6", "max_abs", "max_rel")) if (is.null(r[[k]])) r[[k]] <- NA; r }))
rownames(tab) <- NULL
options(width = 200)
cat("FILES:", nrow(tab), " SAME:", sum(tab$status == "SAME"), " DIFFERS:", sum(tab$status == "DIFFERS"),
    " OTHER:", sum(!tab$status %in% c("SAME", "DIFFERS")), "\n\n")
print(tab, row.names = FALSE)
for (t in c("cohort.txt", "PROVENANCE.txt")) {
  same <- identical(readLines(file.path(A, t), warn = FALSE), readLines(file.path(B, t), warn = FALSE))
  cat("\n", t, if (same) "SAME" else "DIFFERS", "\n")
  if (!same) { cat("--- laptop\n"); writeLines(readLines(file.path(A, t), warn = FALSE))
               cat("--- cluster\n"); writeLines(readLines(file.path(B, t), warn = FALSE)) }
}
if (length(cells)) {
  cc <- do.call(rbind, cells); cc <- cc[order(-cc$rel_diff), ]
  cat("\nLargest differing cells (up to 60):\n"); print(head(cc, 60), row.names = FALSE)
}
