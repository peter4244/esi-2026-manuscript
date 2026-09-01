# Resolve this paper's own directory so the scripts run from anywhere.
#
# They used to build paths from the working directory, which meant they only
# worked when invoked from the repository root. That is a bad assumption for a
# command handed to someone else to run: the shell it lands in is often
# somewhere else entirely, and the failure is a confusing "cannot open file"
# rather than "you are in the wrong directory".
#
# Sourced by every script here via a two-line bootstrap, which is the one bit
# that cannot itself be factored out.
.ctfree_locate <- function() {
  a <- commandArgs(trailingOnly = FALSE)
  m <- grep("^--file=", a, value = TRUE)
  if (length(m)) return(dirname(normalizePath(sub("^--file=", "", m[1]))))
  # Interactive or sourced: accept the working directory only if it really is
  # the repository root, rather than guessing.
  if (file.exists(file.path("ctfree", "verify.R")) && file.exists("config_paths.R"))
    return(normalizePath("ctfree"))
  stop("cannot locate ctfree/; run with Rscript, or set the working directory ",
       "to the repository root")
}
CTFREE <- .ctfree_locate()
ROOT   <- dirname(CTFREE)
ASSETS <- file.path(CTFREE, "assets")
CONFIG <- file.path(ROOT, "config_paths.R")
