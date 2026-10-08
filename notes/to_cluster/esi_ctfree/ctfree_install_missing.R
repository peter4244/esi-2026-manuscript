# Install the two packages the ctfree analysis needs that are absent from R 4.5.1 on r9
# (preflight, esi-repro, 2026-10-07): ggalluvial and lmerTest, plus any of their dependencies that are
# themselves absent. Nothing already installed is upgraded or reinstalled. Run from the clone root:
#   Rscript ctfree_install_missing.R

lib <- Sys.getenv("R_LIBS_USER")
cat("R:", R.version.string, "\nuser library:", lib, "exists:", dir.exists(lib), "\n")
if (!dir.exists(lib)) stop("user library does not exist; stopping without installing")

want <- c("ggalluvial", "lmerTest")
db <- available.packages(repos = "https://cloud.r-project.org")
deps <- tools::package_dependencies(want, db = db, which = c("Depends", "Imports", "LinkingTo"),
                                    recursive = TRUE)
need <- unique(c(want, unlist(deps)))
base <- rownames(installed.packages(priority = "base"))
absent <- setdiff(need, c(rownames(installed.packages()), base))
cat("to install (absent only):", paste(absent, collapse = ", "), "\n")

if (length(absent)) install.packages(absent, lib = lib, repos = "https://cloud.r-project.org",
                                     dependencies = FALSE)

still <- setdiff(want, rownames(installed.packages()))
cat("INSTALL", if (length(still)) paste("FAILED, still missing:", paste(still, collapse = ", ")) else "DONE", "\n")
