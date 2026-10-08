# Preflight for the ctfree reproduction (note esi-repro). Run from the clone root:
#   Rscript ctfree_preflight.R
# Reads only file headers and line counts. Prints no data values and no identifiers.

cat("R:", R.version.string, "\n")
cat("locale LC_CTYPE:", Sys.getlocale("LC_CTYPE"), "\n\n")

pk <- c("MASS", "digest", "dplyr", "tidyr", "ggalluvial", "ggplot2", "knitr", "rmarkdown",
        "lme4", "lmerTest", "patchwork", "png", "survival")
miss <- setdiff(pk, rownames(installed.packages()))
cat("packages missing:", if (length(miss)) paste(miss, collapse = ", ") else "none", "\n")
pandoc_ok <- "rmarkdown" %in% rownames(installed.packages()) && rmarkdown::pandoc_available()
cat("pandoc:", if (pandoc_ok) as.character(rmarkdown::pandoc_version()) else "NOT FOUND", "\n\n")
if (!pandoc_ok) miss <- c(miss, "pandoc")

source("config_paths.R")
need <- list(ESI_PATH = "ESI", PHE_PATH = character(0), VS_PATH = character(0),
             COD_PATH = "Torch_Group_Basic", EX_PATH = character(0),
             MDCOPD_PATH = c("MultiDim_COPD_Subtype", "MultiDim_COPD_score"))
ok <- TRUE
for (v in names(need)) {
  p <- get(v)
  if (!file.exists(p)) { cat(sprintf("%-12s MISSING %s\n", v, p)); ok <- FALSE; next }
  h <- readLines(p, n = 1, warn = FALSE)
  d <- read.delim(p, sep = if (grepl("\t", h)) "\t" else ",", stringsAsFactors = FALSE, nrows = 1)
  idhit <- intersect(c(ID_COL, paste0(ID_COL, ".x"), paste0(ID_COL, ".y")), names(d))
  cols  <- need[[v]]; cmiss <- setdiff(cols, names(d))
  n <- length(readLines(p, warn = FALSE)) - 1L
  cat(sprintf("%-12s rows %6d  cols %4d  id column: %-6s  required columns missing: %s\n",
              v, n, ncol(d), if (length(idhit)) idhit[1] else "NONE",
              if (length(cmiss)) paste(cmiss, collapse = ", ") else "none"))
  if (!length(idhit) || length(cmiss)) ok <- FALSE
}
cat("\nPREFLIGHT", if (ok && !length(miss)) "PASSED" else "FAILED", "\n")
