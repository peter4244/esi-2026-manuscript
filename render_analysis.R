#!/usr/bin/env Rscript
# Render the analysis with a raster device that works on a headless node.
#
# Why this wrapper exists rather than a line inside the .Rmd:
#
# knitr probes whether the png device works during knit() startup, in
# set_html_dev() -> dev_available("png"), which opens a throwaway png before any
# chunk has run. On a node whose default bitmapType is "Xlib" with no X11
# display -- Channing's compute nodes -- that probe emits
#
#     In png(..., res = dpi, units = "in") :
#       unable to open connection to X11 display ''
#
# No chunk option and no code in the document can prevent it, because the
# document has not started executing yet. dev_available() also memoises its
# result per session, so the probe happens exactly once and the warning appears
# exactly once, queued under warn = 0 and flushed when knit() returns.
#
# The warning is harmless: the figures are written by ggplot2 through ragg and
# never touch a display. This wrapper removes it so a clean log means a clean
# run, rather than a log where one benign warning has to be recognised and
# dismissed on every render.
#
# Usage, from the repository root:
#   Rscript render_analysis.R
#
# The analysis still renders correctly under a plain
# `Rscript -e 'knitr::knit("...")'`; that route simply carries the warning.

RMD <- "esi_manuscript_analysis_2026.7.17_noILD.Rmd"
if (!file.exists(RMD)) stop("run this from the repository root; ", RMD, " not found")

# Rescue only a default that cannot work headless. Taking cairo unconditionally
# would switch macOS off quartz and change local figure rendering for no reason.
.bt <- getOption("bitmapType")
if (capabilities("cairo") &&
    (is.null(.bt) || !nzchar(.bt) || identical(.bt, "Xlib"))) {
  options(bitmapType = "cairo")
  message("bitmapType: ", .bt, " -> cairo (headless-safe)")
} else {
  message("bitmapType: ", .bt, " (left as is)")
}

knitr::knit(RMD)
