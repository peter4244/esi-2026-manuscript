#!/usr/bin/env Rscript
# Locate the source of the "unable to open connection to X11 display" warning.
#
# The warning survives every configuration change tried so far, and its position
# in render.log is uninformative because it is queued under warn = 0 and flushed
# when knit() returns. Guessing has failed four times; this reports the fact
# rather than inferring it.
#
# A calling handler installed OUTSIDE knitr sees every warning at the moment it
# is signalled, including ones raised by knitr itself between chunks, which
# evaluate() never sees and chunk options cannot suppress. At that moment the
# call stack still holds the frames that led to it, and knitr::opts_current
# still names the chunk being processed.
#
# Usage, from the repository root:
#   TMPDIR=/tmp/repjc_R Rscript diagnose_x11.R > diagnose_x11.log 2>&1
#
# Writes artifacts exactly as a normal run does; the analysis is deterministic,
# so this is not destructive.

RMD <- "esi_manuscript_analysis_2026.7.17_noILD.Rmd"

cat("R           : ", R.version.string, "\n", sep = "")
cat("knitr       : ", as.character(packageVersion("knitr")), "\n", sep = "")
cat("bitmapType  : ", getOption("bitmapType"), "  (at session start)\n", sep = "")
cat("cairo/X11   : ", paste(capabilities()[c("cairo", "X11")], collapse = " / "), "\n\n", sep = "")

seen <- 0L

withCallingHandlers(
  knitr::knit(RMD),
  warning = function(w) {
    if (!grepl("X11", conditionMessage(w), fixed = TRUE)) return(invisible(NULL))
    seen <<- seen + 1L
    cs <- sys.calls()
    lbl <- tryCatch(knitr::opts_current$get("label"), error = function(e) NA_character_)
    cat("\n=== X11 WARNING #", seen, " ===\n", sep = "", file = stderr())
    cat("chunk being processed : ", if (is.null(lbl) || is.na(lbl)) "<none>" else lbl,
        "\n", sep = "", file = stderr())
    cat("bitmapType now        : ", getOption("bitmapType"), "\n", sep = "", file = stderr())
    cat("knitr dev now         : ",
        paste(knitr::opts_chunk$get("dev"), collapse = ","), "\n", sep = "", file = stderr())
    cat("signalling call       : ",
        paste(deparse(conditionCall(w)), collapse = " "), "\n", sep = "", file = stderr())
    cat("call stack (innermost last):\n", file = stderr())
    for (i in seq_along(cs)) {
      s <- paste(deparse(cs[[i]]), collapse = " ")
      cat(sprintf("  [%02d] %s\n", i, substr(s, 1, 220)), file = stderr())
    }
    cat("=== END WARNING #", seen, " ===\n\n", sep = "", file = stderr())
  })

cat("\n\nTotal X11 warnings observed: ", seen, "\n", sep = "")
