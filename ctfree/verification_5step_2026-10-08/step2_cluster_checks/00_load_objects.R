# Step-2 verification, cluster side. Rebuilds the Rmd's in-memory objects
# (d_b, mort, exa, cod, decline, p4, k3, OTHER, COV, ...) WITHOUT writing to
# ctfree/assets/: the purled code is redirected to a temporary OUT_DIR, and the
# three bootstrap chunks plus everything after the discordance chunks are cut.
# Run from the ctfree/ directory:  Rscript verification_5step_2026-10-08/step2_cluster_checks/<script>.R
# (each check script sources this file first).
stopifnot(file.exists("ESI_ctfree_analysis_2026.9.3.Rmd"))
tmp_r <- tempfile(fileext = ".R")
knitr::purl("ESI_ctfree_analysis_2026.9.3.Rmd", output = tmp_r, quiet = TRUE, documentation = 1)
src <- readLines(tmp_r)
# redirect every write away from the real assets directory
hit <- grep('^OUT_DIR <- file.path\\(HERE, "assets"\\)', src)
stopifnot(length(hit) == 1)
src[hit] <- 'OUT_DIR <- file.path(tempdir(), "step2_assets"); HERE <- normalizePath(".")'
# drop chunks that are slow or touch the bootstrap cache
lab <- grep("^## ----", src)
chunk_name <- sub("^## ----([A-Za-z0-9_.-]+?)(,.*|-*)$", "\\1", src[lab], perl = TRUE)
stopifnot(all(c("crude-rr", "paired-bootstrap", "fev1-decline") %in% chunk_name))
drop <- c("group-paired-bootstrap", "fev1-paired-bootstrap", "paired-bootstrap",
          "crude-rr", "binary-vs-mdcopd", "strata-combined", "strata-profile-tests",
          "completeness", "provenance", "session")
keep <- rep(TRUE, length(src))
for (i in seq_along(lab)) if (chunk_name[i] %in% drop) {
  end <- if (i < length(lab)) lab[i + 1] - 1 else length(src)
  keep[lab[i]:end] <- FALSE
}
src <- src[keep]
# exact_rate_ratio lives in the dropped crude-rr chunk; re-define it
exact_rate_ratio <- function(e1, t1, e0, t0) {
  if (e1 == 0) return(c(NA_real_, NA_real_))
  poisson.test(c(e1, e0), c(t1, t0))$conf.int[1:2]
}
writeLines(src, tmp_r)
source(tmp_r, echo = FALSE)
stopifnot(nrow(d_b) == 9240, exists("decline"), exists("mort_c"), p4$t_low == 1.5, k3 == 2)
cat("objects loaded; temporary OUT_DIR =", OUT_DIR, "\n")
