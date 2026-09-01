#!/usr/bin/env Rscript
# Render the co-author report to a self-contained HTML file, suitable for
# attaching to an email. Runs from any working directory.
#
# bitmapType is set before render() because knitr probes the png device during
# knit() startup, before any chunk runs; see render_analysis.R in the parent
# directory for the full explanation.
.b <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
HERE <- if (length(.b)) dirname(normalizePath(sub("^--file=", "", .b[1]))) else "ctfree"
.bt <- getOption("bitmapType")
if (capabilities("cairo") && (is.null(.bt) || !nzchar(.bt) || identical(.bt, "Xlib")))
  options(bitmapType = "cairo")
out <- file.path(HERE, "massimo_report.html")
rmarkdown::render(file.path(HERE, "massimo_report.Rmd"),
                  output_file = basename(out), output_dir = HERE, quiet = TRUE)
cat("wrote", normalizePath(out), "\n")
