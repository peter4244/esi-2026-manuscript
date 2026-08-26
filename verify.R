#!/usr/bin/env Rscript
# Render verification_report.Rmd, then fail loudly if any manuscript claim did
# not reconcile. The gate lives here rather than inside the Rmd so that a failing
# run still leaves a readable HTML document behind.
CONFIG <- Sys.getenv("ESI_CONFIG", unset = "config_paths.R")
if (!file.exists(CONFIG)) stop("Missing input-path config: '", CONFIG, "'")
source(CONFIG, local = FALSE)

rmarkdown::render("verification_report.Rmd", quiet = TRUE)

csv <- file.path(OUT_DIR, "VERIFICATION.csv")
if (!file.exists(csv)) stop("verification_report.Rmd wrote no VERIFICATION.csv")
V <- read.csv(csv)

bad <- V[V$status %in% c("FAIL", "ERROR"), ]
if (nrow(bad)) {
  for (i in seq_len(nrow(bad))) {
    message(sprintf("  %-24s %-46s expected %-10s computed %s",
                    bad$id[i], substr(bad$claim[i], 1, 46),
                    bad$expected[i], bad$computed[i]))
  }
  stop(sprintf("VERIFICATION FAILED: %d of %d manuscript claims do not reconcile. See %s",
               nrow(bad), nrow(V), csv))
}
message(sprintf("VERIFICATION PASSED: %d claims reconcile (%d local-only). See %s",
                sum(V$status == "PASS"), sum(V$status == "LOCAL-ONLY"), csv))
