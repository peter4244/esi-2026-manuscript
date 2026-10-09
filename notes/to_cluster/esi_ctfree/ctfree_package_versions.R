# Record the software versions the CT-free analysis ran with on Channing (note esi-pkg).
# Prints versions only; reads no data. Run from the clone root:  Rscript ctfree_package_versions.R
pk <- c("MASS", "digest", "dplyr", "ggalluvial", "ggplot2", "knitr", "lme4", "lmerTest", "patchwork",
        "png", "rmarkdown", "scales", "survival", "tidyr", "Matrix", "xfun")
cat("R:", R.version.string, "\n")
cat("platform:", R.version$platform, "\n")
cat("pandoc:", if (requireNamespace("rmarkdown", quietly = TRUE) && rmarkdown::pandoc_available())
  as.character(rmarkdown::pandoc_version()) else "not found", "\n\n")
v <- vapply(pk, function(p) if (requireNamespace(p, quietly = TRUE)) as.character(packageVersion(p)) else "NOT INSTALLED", "")
for (p in names(v)) cat(sprintf("%-12s %s\n", p, v[[p]]))
