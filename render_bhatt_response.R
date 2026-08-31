#!/usr/bin/env Rscript
# Render the co-author response report to HTML.
#
# Runs on a headless compute node. The raster device has to be selected before
# render() is called, because render() knits and knitr probes the png device
# during knit() startup, before any chunk runs -- see render_analysis.R.
#
# Usage, from the repository root:
#   Rscript render_bhatt_response.R
#
# Requires the analysis artifacts to be present in OUT_DIR, including
# Table_S18_exac_prior_adjusted.csv and Table_S19_decline_baseline_adjusted.csv.
# If they are missing, run `Rscript render_analysis.R` first; the report names
# the missing file rather than failing obscurely.

RMD <- "bhatt_response.Rmd"
if (!file.exists(RMD)) stop("run this from the repository root; ", RMD, " not found")

.bt <- getOption("bitmapType")
if (capabilities("cairo") &&
    (is.null(.bt) || !nzchar(.bt) || identical(.bt, "Xlib"))) {
  options(bitmapType = "cairo")
  message("bitmapType: ", .bt, " -> cairo (headless-safe)")
}

out <- rmarkdown::render(RMD, quiet = TRUE)
message("Wrote: ", out)
