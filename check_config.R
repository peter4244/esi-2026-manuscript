#!/usr/bin/env Rscript
# Validate a site configuration BEFORE running the analysis.
#
#   Rscript check_config.R [config_file]
#
# Confirms each input exists, carries the identifier column named by ID_COL,
# and supplies the columns the analysis actually reads. Reports everything it
# finds rather than stopping at the first problem, so one run tells you the
# full picture.

args   <- commandArgs(trailingOnly = TRUE)
CONFIG <- if (length(args)) args[1] else Sys.getenv("ESI_CONFIG", "config_paths.R")
if (!file.exists(CONFIG)) stop("No such config: ", CONFIG)
source(CONFIG)

need <- c("ESI_PATH","PHE_PATH","VS_PATH","COD_PATH","EX_PATH","OUT_DIR","ID_COL")
miss <- need[!vapply(need, exists, logical(1))]
if (length(miss)) stop("config does not define: ", paste(miss, collapse=", "))

# Columns the analysis reads from each input.
REQ <- list(
  ESI_PATH = c("ESI"),
  PHE_PATH = c("visitnum","finalgold_visit","FEV1_post","FEV1_FVC_post",
               "years_from_baseline","CT_Visual_Emph_Severity",
               "CT_Visual_Wall_Thickening","MMRCDyspneaScor","SGRQ_scoreTotal",
               "Chronic_Bronchitis","Height_CM","age_visit","gender","race",
               "SmokCigNow","ATS_PackYears","BMI","cohort"),
  VS_PATH  = c("vital_status","days_followed"),
  COD_PATH = c("Torch_Group_Basic"),
  EX_PATH  = c("Total_Exacerbations","Total_Severe_Exacer","Years_Followed")
)

# Use the same delimiter sniffing as the analysis. Reading a tab-delimited
# export with read.csv yields a single mangled column, which previously made
# every required column look absent and reported a data problem that was really
# a checker problem.
read_hdr <- function(p) {
  sep <- if (grepl("\t", readLines(p, n = 1, warn = FALSE))) "\t" else ","
  read.delim(p, sep = sep, nrows = 1, check.names = FALSE)
}

cat("config:", CONFIG, "\nidentifier column (ID_COL):", ID_COL, "\n\n")
ok <- TRUE
for (v in names(REQ)) {
  p <- get(v)
  cat(sprintf("%-9s %s\n", v, p))
  if (!file.exists(p)) { cat("            MISSING\n\n"); ok <- FALSE; next }
  hdr <- names(read_hdr(p))
  idc <- c(ID_COL, paste0(ID_COL, ".x"), paste0(ID_COL, ".y"))
  hit <- idc[idc %in% hdr]
  if (length(hit)) cat("            id column:", hit[1], "\n")
  else { cat("            NO ID COLUMN (looked for", paste(idc, collapse=", "), ")\n"); ok <- FALSE }
  absent <- setdiff(REQ[[v]], hdr)
  if (length(absent)) { cat("            MISSING COLUMNS:", paste(absent, collapse=", "), "\n"); ok <- FALSE }
  else cat("            all required columns present\n")
  cat("\n")
}

# The cohort column drives the ILD/Bronchiectasis exclusion. If it is absent or
# uses different level names the exclusion silently removes nobody, so report
# its levels explicitly rather than letting that pass unnoticed.
if (file.exists(PHE_PATH)) {
  ph <- read.delim(PHE_PATH, stringsAsFactors = FALSE,
                   sep = if (grepl("\t", readLines(PHE_PATH, 1, warn = FALSE))) "\t" else ",")
  if ("cohort" %in% names(ph)) {
    cat("cohort levels in the phenotype file:\n")
    print(table(trimws(ph$cohort), useNA = "ifany"))
    if (!any(trimws(ph$cohort) == "ILD/Brnch")) {
      cat("\n  NOTE: no 'ILD/Brnch' level present, so the exclusion removes nobody\n",
          "  here. That is expected if this export already excludes that cohort\n",
          "  upstream; the resulting analytic cohort should then match the\n",
          "  published one. It is NOT expected if the export should contain them,\n",
          "  in which case the cohort column may be named or coded differently.\n")
    }
  }
}
# Filenames are not a reliable guide to which participants a file covers, so
# measure the overlap instead of inferring it. A file that silently omits a
# stratum would shrink an analytic set without any error being raised.
if (file.exists(PHE_PATH) && file.exists(EX_PATH) && exists("ph") &&
    "cohort" %in% names(ph)) {
  bind <- function(df) {
    cand <- c(ID_COL, paste0(ID_COL, ".x"), paste0(ID_COL, ".y"))
    hit  <- cand[cand %in% names(df)]
    if (length(hit)) as.character(df[[hit[1]]]) else character(0)
  }
  exs <- read.csv(EX_PATH, stringsAsFactors = FALSE, sep =
                  if (grepl("\t", readLines(EX_PATH, 1, warn = FALSE))) "\t" else ",")
  v1  <- ph[ph$visitnum == 1, ]
  eid <- unique(bind(exs))
  cat("\ncoverage of the exacerbations file, by recruitment cohort:\n")
  for (lv in sort(unique(trimws(v1$cohort)))) {
    ids <- unique(bind(v1[trimws(v1$cohort) == lv, ]))
    cat(sprintf("  %-14s %5d of %5d present\n", lv, sum(ids %in% eid), length(ids)))
  }
}

cat("\n", if (ok) "CONFIG OK" else "CONFIG HAS PROBLEMS - see above", "\n")
