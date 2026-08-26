#!/usr/bin/env Rscript
# Render verification_report.Rmd, then fail loudly if any manuscript claim did
# not reconcile. The gate lives here rather than inside the Rmd so that a failing
# run still leaves a readable HTML document behind.
CONFIG <- Sys.getenv("ESI_CONFIG", unset = "config_paths.R")
if (!file.exists(CONFIG)) stop("Missing input-path config: '", CONFIG, "'")
source(CONFIG, local = FALSE)

# Coverage is part of the check. Losing registry entries -- an edited loop bound,
# a chunk turned eval=FALSE, a cached CSV -- reduces what is verified without
# reducing how green it looks, so the expected count is asserted here rather
# than merely recorded in a commit message. Raise it when entries are added.
REGISTRY_N <- 132L

csv <- file.path(OUT_DIR, "VERIFICATION.csv")
if (file.exists(csv)) invisible(file.remove(csv))   # never gate on a previous run's CSV

# Same headless-device problem as the analysis, and the same fix. render()
# knits, and knitr probes the png device during knit() startup before any chunk
# runs, so on a node whose default bitmapType is "Xlib" with no display that
# probe warns. It has to be set here, before render() is called; nothing inside
# verification_report.Rmd is early enough. See render_analysis.R.
local({
  .bt <- getOption("bitmapType")
  if (capabilities("cairo") &&
      (is.null(.bt) || !nzchar(.bt) || identical(.bt, "Xlib"))) {
    options(bitmapType = "cairo")
  }
})

rmarkdown::render("verification_report.Rmd", quiet = TRUE)

if (!file.exists(csv)) stop("verification_report.Rmd wrote no VERIFICATION.csv")
V <- read.csv(csv)

if (nrow(V) != REGISTRY_N) {
  stop(sprintf(paste("REGISTRY SHRANK OR GREW: %d entries evaluated, %d expected.",
                     "Coverage changed. Update REGISTRY_N in verify.R if that was intended."),
               nrow(V), REGISTRY_N))
}

# LOCAL-ONLY waives a numeric comparison that is known not to reproduce across
# sites. It is a real hole in coverage, so name the entries rather than counting
# them: an unnoticed one is a claim nobody is checking.
lo <- V[V$status == "LOCAL-ONLY", ]
for (i in seq_len(nrow(lo)))
  message(sprintf("  LOCAL-ONLY  %-14s %s (expected %s, computed %s)",
                  lo$id[i], lo$claim[i], lo$expected[i], lo$computed[i]))

na <- V[V$status == "NOT-AVAILABLE", ]
for (i in seq_len(nrow(na)))
  message(sprintf("  NOT-AVAIL   %-14s %s", na$id[i], na$claim[i]))

bad <- V[V$status %in% c("FAIL", "ERROR"), ]
if (nrow(bad)) {
  for (i in seq_len(nrow(bad))) {
    message(sprintf("  %-6s %-24s %-46s expected %-10s computed %s",
                    bad$status[i], bad$id[i], substr(bad$claim[i], 1, 46),
                    bad$expected[i], bad$computed[i]))
  }
  stop(sprintf("VERIFICATION FAILED: %d of %d manuscript claims do not reconcile. See %s",
               nrow(bad), nrow(V), csv))
}
# Report waived and inapplicable entries as their own categories rather than
# folding them into a "129 of 132" that reads as three failures. Every entry is
# accounted for; none of them failed.
n_pass <- sum(V$status == "PASS")
n_lo   <- sum(V$status == "LOCAL-ONLY")
n_na   <- sum(V$status == "NOT-AVAILABLE")
parts  <- c(sprintf("%d verified", n_pass),
            if (n_lo) sprintf("%d waived (differs by site, named above)", n_lo),
            if (n_na) sprintf("%d not applicable here", n_na))
message(sprintf("VERIFICATION PASSED: %d claims, 0 failed - %s. See %s",
                nrow(V), paste(parts, collapse = ", "), csv))
