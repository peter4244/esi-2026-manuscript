#!/usr/bin/env Rscript
# Validate a site configuration BEFORE running the CT-free MD-COPD analysis
# (ctfree/ESI_ctfree_analysis_2026.9.3.Rmd).
#
#   Rscript check_config.R [config_file]
#
# Confirms each of the six inputs exists, carries the identifier column named
# by ID_COL, and supplies the columns the analysis actually reads. Reports
# everything it finds rather than stopping at the first problem, so one run
# tells you the full picture.
#
# Only the first line (the header) of each file is read. No data row is
# opened, so this is safe to run anywhere the files are visible.

args   <- commandArgs(trailingOnly = TRUE)
CONFIG <- if (length(args)) args[1] else Sys.getenv("ESI_CONFIG", "config_paths.R")
if (!file.exists(CONFIG)) stop("No such config: ", CONFIG)
source(CONFIG)

# OUT_DIR is not needed: the CT-free analysis always writes to ctfree/assets/.
need <- c("ESI_PATH","PHE_PATH","VS_PATH","COD_PATH","EX_PATH","MDCOPD_PATH","ID_COL")
miss <- need[!vapply(need, exists, logical(1))]
if (length(miss)) stop("config does not define: ", paste(miss, collapse=", "))

# Columns the CT-free analysis reads from each input, taken from the code of
# ctfree/ESI_ctfree_analysis_2026.9.3.Rmd. Keep in step with that file.
REQ <- list(
  # one row per participant-visit-manoeuvre; PrePost 0 = pre-, 1 = post-bronchodilator
  ESI_PATH    = c("visitnum","PrePost","ESI"),
  PHE_PATH    = c(
    # cohort exclusion chain
    "visitnum","ExclusionaryDisease","cohort","FEV1_FVC_post",
    # MD-COPD criteria used to build MD-NoCT and MD-COPD-ESI, and the cardiac rule
    "CT_Visual_Emph_Severity","CT_Visual_Wall_Thickening","MMRCDyspneaScor",
    "SGRQ_scoreTotal","Chronic_Bronchitis","CoronaryArtery","CongestHeartFail",
    # covariates, strata and baseline description
    "age_visit","gender","race","SmokCigNow","ATS_PackYears","BMI","Height_CM",
    "finalgold_visit","FEV1pp_utah","Exacerbation_Frequency",
    # FEV1 decline
    "FEV1_post","years_from_baseline",
    # quantitative CT (baseline description and discordance profiles)
    "Insp_LAA950_total_Thirona","PRM_pct_emphysema_Thirona"),
  VS_PATH     = c("vital_status","days_followed"),
  COD_PATH    = c("Torch_Group_Basic","mortality_survival_vital_status","days_followed"),
  EX_PATH     = c("Total_Exacerbations","Years_Followed"),
  MDCOPD_PATH = c("MultiDim_COPD_score")
)

# Use the same delimiter sniffing as the analysis. Reading a tab-delimited
# export as comma-separated yields a single mangled column, which previously
# made every required column look absent and reported a data problem that was
# really a checker problem. Only the header line is parsed.
read_hdr <- function(p) {
  h <- readLines(p, n = 1, warn = FALSE)   # R drops a leading UTF-8 byte-order mark
  sep <- if (grepl("\t", h)) "\t" else ","
  names(read.delim(text = h, sep = sep, header = TRUE, check.names = FALSE,
                   colClasses = "character"))
}

cat("config:", CONFIG, "\nidentifier column (ID_COL):", ID_COL, "\n\n")
ok <- TRUE
for (v in names(REQ)) {
  p <- get(v)
  cat(sprintf("%-11s %s\n", v, p))
  if (!file.exists(p)) { cat("            MISSING\n\n"); ok <- FALSE; next }
  hdr <- read_hdr(p)
  idc <- c(ID_COL, paste0(ID_COL, ".x"), paste0(ID_COL, ".y"))
  hit <- idc[idc %in% hdr]
  if (length(hit)) cat("            id column:", hit[1], "\n")
  else { cat("            NO ID COLUMN (looked for", paste(idc, collapse=", "), ")\n"); ok <- FALSE }
  absent <- setdiff(REQ[[v]], hdr)
  if (length(absent)) { cat("            MISSING COLUMNS:", paste(absent, collapse=", "), "\n"); ok <- FALSE }
  else cat("            all required columns present\n")
  cat("\n")
}

# What a header cannot show. The analysis checks these itself and stops if
# they fail, but it helps to know them before a long run:
# - the ILD/bronchiectasis exclusion keeps rows with ExclusionaryDisease
#   missing, and the never-smoker exclusion drops cohort == "Never smoked";
#   the first four cohort counts must match Bhatt et al. (10,305, 10,198,
#   10,132, 9,416) or the run stops;
# - MultiDim_COPD_score is coded 0 (neither), 1 (COPD-major), 2 (COPD-minor);
# - PrePost is 0 for pre- and 1 for post-bronchodilator manoeuvres.
cat(if (ok) "CONFIG OK" else "CONFIG HAS PROBLEMS - see above", "\n")
