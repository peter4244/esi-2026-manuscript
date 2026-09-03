#!/usr/bin/env Rscript
# Render the CT-free analysis report with a raster device that works on a
# headless node.
#
# Why this wrapper exists rather than a line inside the .Rmd:
#
# knitr probes whether the png device works during knit() startup, in
# set_html_dev() -> dev_available("png"), which opens a throwaway png before
# any chunk has run. On a node whose default bitmapType is "Xlib" with no X11
# display (Channing's compute nodes) that probe emits
#
#     In png(..., res = dpi, units = "in") :
#       unable to open connection to X11 display ''
#
# No chunk option and no code in the document can prevent it, because the
# document has not started executing yet. dev_available() also memoises its
# result per session, so the probe happens exactly once and the warning
# appears exactly once, queued under warn = 0 and flushed when render()
# returns.
#
# The warning is harmless: the figures are written by ggplot2 through the
# cairo png backend and never touch a display. This wrapper removes it so a
# clean log means a clean run.
#
# Usage:  Rscript /abs/path/to/ctfree/render_ctfree_2026.9.3.R

# Locate the .Rmd from this script's own directory, so it runs from any
# working directory (Channing cluster or local).
.b <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
HERE <- if (length(.b)) {
  dirname(normalizePath(sub("^--file=", "", .b[1])))
} else {
  stop("must be run with Rscript so --file= is set")
}
RMD <- file.path(HERE, "ESI_ctfree_analysis_2026.9.3.Rmd")
if (!file.exists(RMD)) stop("cannot find ", RMD)

# Rescue only a default that cannot work headless. Taking cairo
# unconditionally would switch macOS off quartz and change local figure
# rendering for no reason.
.bt <- getOption("bitmapType")
if (capabilities("cairo") &&
    (is.null(.bt) || !nzchar(.bt) || identical(.bt, "Xlib"))) {
  options(bitmapType = "cairo")
  message("bitmapType: ", .bt, " -> cairo (headless-safe)")
} else {
  message("bitmapType: ", .bt, " (left as is)")
}

# Write outputs beside the .Rmd rather than the working directory.
rmarkdown::render(RMD, output_dir = HERE, quiet = FALSE)
