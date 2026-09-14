#!/usr/bin/env Rscript
# Claims verification for the CT-free paper. Fresh registry; shares nothing
# with the v15 manuscript's. Every claim in ctfree/CLAIMS.md is evaluated
# against ctfree/assets/ as it exists now, and any drift fails the run.
#
# Runs from any working directory:  Rscript /abs/path/to/ctfree/verify.R
# Locate this script's own directory, so it runs from any working directory.
.b <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
source(file.path(if (length(.b)) dirname(normalizePath(sub("^--file=", "", .b[1])))
                 else "ctfree", "_locate.R"))
REGISTRY_N <- 189L
TOL_2DP <- 0.005; TOL_3DP <- 0.0005; TOL_1DP <- 0.05; TOL_EXACT <- 0

.cache <- new.env(parent = emptyenv())
load_artifact <- function(name) {
  if (!is.null(.cache[[name]])) return(.cache[[name]])
  p <- file.path(ASSETS, name)
  if (!file.exists(p)) stop("missing artifact: ", p)
  x <- if (grepl("\\.csv$", name)) read.csv(p, stringsAsFactors = FALSE) else {
    kv <- strsplit(readLines(p), "=", fixed = TRUE)
    setNames(as.list(vapply(kv, `[`, "", 2)), vapply(kv, `[`, "", 1))
  }
  .cache[[name]] <- x; x
}

REG <- list()
reg <- function(id, section, claim, expected, artifact, field, tol) {
  REG[[length(REG) + 1]] <<- list(id = id, section = section, claim = claim,
    expected = expected, artifact = artifact, field = field, tol = tol)
}

# --- cohort ---------------------------------------------------------------
reg("COH-01", "Cohort", "analytic cohort n = 9,240", 9240, "cohort.txt",
    'as.numeric(x[["n_cohort"]])', TOL_EXACT)
reg("COH-02", "Cohort", "4,084 with airflow limitation", 4084, "cohort.txt",
    'as.numeric(x[["n_afl"]])', TOL_EXACT)
reg("COH-03", "Cohort", "5,156 without airflow limitation", 5156, "cohort.txt",
    'as.numeric(x[["n_noafl"]])', TOL_EXACT)

# --- per-category F1, reclassification detail, crude COPD-minor, visual CT --
FC <- function(cat, fld) sprintf('x$%s[x$category == "%s"]', fld, cat)
reg("F1CAT-01", "Fitting", "per-category F1 for AFL-only rises from 0.40 to 0.47", TRUE,
    "f1_by_category.csv",
    sprintf('abs(%s - 0.40) < 0.01 && abs(%s - 0.47) < 0.01',
            FC("AFL-only","f1_noct"), FC("AFL-only","f1_esi")), TOL_EXACT)
reg("F1CAT-02", "Fitting", "and for COPD-major from 0.88 to 0.94", TRUE,
    "f1_by_category.csv",
    sprintf('abs(%s - 0.88) < 0.01 && abs(%s - 0.94) < 0.01',
            FC("COPD-major","f1_noct"), FC("COPD-major","f1_esi")), TOL_EXACT)
reg("F1CAT-03", "Fitting",
    "and is fractionally lower for noCOPD and COPD-minor", TRUE,
    "f1_by_category.csv",
    sprintf('%s < 0 && %s < 0', FC("noCOPD","gain"), FC("COPD-minor","gain")), TOL_EXACT)

RC <- function(sch, fld) sprintf('x$%s[x$schema == "%s"]', fld, sch)
reg("RECL-07", "Reclassification",
    "NoCT moves 465 noCOPD to COPD-minor and 90 the other way", TRUE,
    "reclassification.csv",
    sprintf('%s == 465 && %s == 90', RC("S3","nocopd_to_minor"), RC("S3","minor_to_nocopd")),
    TOL_EXACT)
reg("RECL-08", "Reclassification",
    "NoCT retains all 275 AFL-only, ESI retains 193", TRUE,
    "reclassification.csv",
    sprintf('%s == 275 && %s == 193', RC("S3","aflonly_kept"), RC("S4","aflonly_kept")),
    TOL_EXACT)



CL <- function(cr, lab) sprintf('x$mean_ESI[x$criterion == "%s" & x$label == "%s"]', cr, lab)
reg("CTLEV-01", "ESI and CT",
    "mean ESI rises from 1.04 at no emphysema to 6.62 at advanced destructive", TRUE,
    "esi_ct_levels.csv",
    sprintf('abs(%s-1.04)<0.01 && abs(%s-6.62)<0.01',
            CL("Visual emphysema","none"), CL("Visual emphysema","advanced destructive")),
    TOL_EXACT)
reg("CTLEV-02", "ESI and CT",
    "and from 0.96 to 3.32 across wall thickening", TRUE, "esi_ct_levels.csv",
    sprintf('abs(%s-0.96)<0.01 && abs(%s-3.32)<0.01',
            CL("Airway wall thickening","absent"), CL("Airway wall thickening","definite")),
    TOL_EXACT)

CA <- function(st, cr, fld)
  sprintf('x$%s[x$stratum == "%s" & x$criterion == "%s"]', fld, st, cr)
reg("CTAUC-01", "ESI and CT", "pooled ESI AUC 0.78 for emphysema", 0.78,
    "esi_ct_auc.csv", CA("All participants","Visual emphysema","auc_ESI"), TOL_2DP)
# FEV1/FVC discriminates better in five of the six stratum-by-criterion
# comparisons. The exception is wall thickening among participants with
# airflow limitation, where the two are equal to two decimal places
# (0.746 vs 0.745). Pinned as "five of six" rather than "every", which is
# what the prose originally claimed and the artifact refuted.
reg("CTAUC-02", "ESI and CT",
    "FEV1/FVC discriminates at least as well in five of six comparisons", 5L,
    "esi_ct_auc.csv", 'sum(x$auc_FEV1FVC >= x$auc_ESI)', TOL_EXACT)
reg("CTAUC-02b", "ESI and CT",
    "the exception is a tie to two decimals, not an ESI advantage", TRUE,
    "esi_ct_auc.csv",
    'all(round(x$auc_ESI, 2) <= round(x$auc_FEV1FVC, 2))', TOL_EXACT)
reg("CTAUC-03", "ESI and CT",
    "in preserved spirometry ESI reaches only 0.56 for emphysema", 0.56,
    "esi_ct_auc.csv", CA("Preserved spirometry","Visual emphysema","auc_ESI"), TOL_2DP)
reg("CTAUC-04", "ESI and CT",
    "ESI discriminates better with airflow limitation than without, for both criteria",
    TRUE, "esi_ct_auc.csv",
    sprintf('%s > %s && %s > %s',
            CA("Airflow limitation","Visual emphysema","auc_ESI"),
            CA("Preserved spirometry","Visual emphysema","auc_ESI"),
            CA("Airflow limitation","Airway wall thickening","auc_ESI"),
            CA("Preserved spirometry","Airway wall thickening","auc_ESI")), TOL_EXACT)

# --- FEV1 decline and continuous ESI ---------------------------------------
FD <- function(sch, cat, fld)
  sprintf('x$%s[x$schema == "%s" & x$category == "%s"]', fld, sch, cat)
reg("DEC-01", "FEV1 decline",
    "under MD-COPD, AFL-only does not differ from the common reference", TRUE,
    "fev1_decline.csv",
    sprintf('%s > 0.05', FD("S2","AFL-only","p")), TOL_EXACT)
reg("DEC-02", "FEV1 decline",
    "under ESI-MD-COPD, COPD-major declines FASTER than the common reference", TRUE,
    "fev1_decline.csv",
    sprintf('%s < 0 && %s < 0.05',
            FD("S4","COPD-major","est_mL_yr"), FD("S4","COPD-major","p")), TOL_EXACT)

reg("CONT-06", "Continuous ESI",
    "ESI is essentially unchanged by bronchodilator, mean -0.09", -0.09,
    "bronchodilator_delta_esi.csv", 'x$mean_delta', TOL_2DP)
reg("CONT-07", "Continuous ESI",
    "computed on this cohort, 9,234 paired measurements", 9234,
    "bronchodilator_delta_esi.csv", 'x$n_paired', TOL_EXACT)

# --- concordant and discordant classification -----------------------------
# MD-COPD against ESI-MD-COPD, pairwise, in preserved spirometry.
DC <- function(g, fld) sprintf('x$%s[x$group == "%s"]', fld, g)
reg("DISC2-01", "Discordance", "ESI misses only 85 of MD-COPD's COPD-minor", 85,
    "discord_counts.csv", DC("CT-only-COPD", "n"), TOL_EXACT)
reg("DISC2-02", "Discordance", "ESI adds 501 the CT framework does not call COPD", 501,
    "discord_counts.csv", DC("ESI-only-COPD", "n"), TOL_EXACT)
reg("DISC2-03", "Discordance", "714 are called COPD by both", 714,
    "discord_counts.csv", DC("Both-COPD", "n"), TOL_EXACT)

# --- paired comparison between classifications ----------------------------
# The Results previously asserted that ESI-MD-COPD "tracks the reference"
# from two overlapping intervals. These test it.

# --- numbers the opening Results section quotes ---------------------------
# The gate is now reported as P values rather than chi-squares, so the P values
# themselves are pinned; the chi-squares stay registered because the artifact
# still carries them.

reg("LAB-01c", "Labels", "S2 reference COPD-minor n = 799", 799,
    "schema_labels.csv",
    'x$n[x$schema == "S2" & x$category == "COPD-minor"]', TOL_EXACT)

# --- ESI against quantitative CT ------------------------------------------
# Cited in Results, Study population, and shown as Supplemental Table S2. These
# were previously unregistered and the table cited for them was a correlation
# matrix among the CT measures, which did not contain them.

# --- baseline description --------------------------------------------------
reg("BASE-01", "Cohort", "baseline table totals the analytic cohort, 9,240", 9240,
    "supp_baseline.csv", 'as.numeric(x$n[x$stratum == "Overall"])', TOL_EXACT)
reg("BASE-02", "Cohort", "the cohort has no never-smoker stratum", TRUE,
    "supp_baseline.csv", '!("Never" %in% x$stratum)', TOL_EXACT)

# --- the gate -------------------------------------------------------------
# Guard the interpretation, not just the number: the gain must stay small, or
# the paper's "reclassification, not prediction" framing needs revisiting.

# --- fitting --------------------------------------------------------------
f <- function(s, fld) sprintf('x$%s[x$schema == "%s"]', fld, s)
reg("FIT-01", "Fitting", "S3 rule is >= 2 of 3 symptom criteria", 2, "schema_fit.csv",
    f("S3", "k"), TOL_EXACT)
reg("FIT-02a", "Fitting", "S4 rule is >= 2 of 4", 2, "schema_fit.csv", f("S4", "k"), TOL_EXACT)
reg("FIT-02b", "Fitting", "S4 ESI threshold 1.50", 1.50, "schema_fit.csv",
    f("S4", "t_low"), TOL_3DP)
# The rule previously scored ESI 0/1/2 using an upper threshold fitted at 7.00
# and reached by 2 of 5,156 participants with preserved spirometry. Dropping it
# left the fitted rule, every category count and macro-F1 unchanged, so the
# parameter was carrying nothing. This pins the rule as single-threshold.
reg("FIT-03", "Fitting", "the ESI rule uses a single threshold", TRUE,
    "schema_fit.csv", sprintf('is.na(%s)', f("S4", "t_high")), TOL_EXACT)


# --- labels ---------------------------------------------------------------
L <- function(s, cat) sprintf('x$n[x$schema == "%s" & x$category == "%s"]', s, cat)
reg("LAB-01a", "Labels", "S2 reference COPD-major n = 3,809", 3809, "schema_labels.csv",
    L("S2", "COPD-major"), TOL_EXACT)
reg("LAB-01b", "Labels", "S2 reference AFL-only n = 275", 275, "schema_labels.csv",
    L("S2", "AFL-only"), TOL_EXACT)
reg("LAB-02", "Labels", "S3 calls only 2,976 COPD-major, losing 833", 2976,
    "schema_labels.csv", L("S3", "COPD-major"), TOL_EXACT)
reg("LAB-03", "Labels", "S4 holds COPD-major at 3,541", 3541, "schema_labels.csv",
    L("S4", "COPD-major"), TOL_EXACT)
reg("LAB-04", "Labels", "S3 calls 1,108 AFL-only against the reference's 275",
    1108, "schema_labels.csv", L("S3", "AFL-only"), TOL_EXACT)

# --- reclassification counts the Results quotes ---------------------------
RC <- function(sch, fld) sprintf('x$%s[x$schema == "%s"]', fld, sch)
reg("ACC-01", "Reclassification",
    "the accuracy difference is significant by McNemar (P < 0.001)", 1,
    "accuracy_test.csv", "as.integer(x$p_value < 0.001)", TOL_EXACT)

reg("RECL-09", "Reclassification",
    "ESI-MD-COPD agrees with MD-COPD for 8,222 of 9,240 participants (89.0%)", 8222,
    "reclassification.csv", 'x$concordant[x$schema == "S4"]', TOL_EXACT)
reg("RECL-10", "Reclassification",
    "NoCT-MD-COPD agrees for 7,852 of 9,240 (85.0%)", 7852,
    "reclassification.csv", 'x$concordant[x$schema == "S3"]', TOL_EXACT)
# Results: "At the level of COPD versus no COPD, agreement was 87.9% and 83.9%".
# Equal to the four-group agreement because every disagreement with MD-COPD
# crosses the COPD / no-COPD line; if these ever diverge, the sentence needs rewording.
BIN <- function(sch) sprintf(paste0('with(x[x$schema == "%s", ], 100 * sum(n[(row_cat %%in%% ',
  'c("COPD-minor", "COPD-major")) == (col_cat %%in%% c("COPD-minor", "COPD-major"))]) / sum(n))'), sch)
reg("RECL-11", "Reclassification", "COPD versus no COPD agreement is 89.0% for the ESI classification",
    89.0, "crossclass.csv", BIN("S4"), TOL_1DP)
reg("RECL-12", "Reclassification", "COPD versus no COPD agreement is 85.0% for the NoCT classification",
    85.0, "crossclass.csv", BIN("S3"), TOL_1DP)

# Results fills and the S5 sentence (2026-09-11 13:01 draft).
reg("FU-01", "Follow-up", "median follow-up 10.8 years for mortality", 10.8, "followup_medians.csv",
    'x$median_yr[x$outcome == "mortality (all-cause and respiratory)"]', TOL_1DP)
reg("FU-02", "Follow-up", "median follow-up 10.4 years for exacerbations", 10.4, "followup_medians.csv",
    'x$median_yr[x$outcome == "exacerbations"]', TOL_1DP)
reg("FU-03", "Follow-up", "median follow-up 9.7 years for lung function decline", 9.7, "followup_medians.csv",
    'x$median_yr[x$outcome == "FEV1 decline, participants with a follow-up visit"]', TOL_1DP)
reg("FU-04", "Follow-up", "among 5,414 participants with a follow-up spirometry visit", 5414, "followup_medians.csv",
    'x$n[x$outcome == "FEV1 decline, participants with a follow-up visit"]', TOL_EXACT)
reg("AFL-01", "AFL-only paragraph", "ESI AFL-only group n = 543", 543, "schema_labels.csv",
    'x$n[x$schema == "S4" & x$category == "AFL-only"]', TOL_EXACT)
reg("AFL-02", "AFL-only paragraph", "ESI AFL-only crude all-cause 1.25", 1.25, "consensus_ref_crude.csv",
    'x$rr[x$schema == "S4" & x$category == "AFL-only" & x$outcome == "all"]', TOL_2DP)
reg("AFL-03", "AFL-only paragraph", "its lower bound 1.01", 1.01, "consensus_ref_crude.csv",
    'x$lo[x$schema == "S4" & x$category == "AFL-only" & x$outcome == "all"]', TOL_2DP)
reg("AFL-04", "AFL-only paragraph", "its upper bound 1.54", 1.54, "consensus_ref_crude.csv",
    'x$hi[x$schema == "S4" & x$category == "AFL-only" & x$outcome == "all"]', TOL_2DP)
reg("AFL-05", "AFL-only paragraph", "MD-COPD AFL-only crude all-cause 1.10", 1.10, "consensus_ref_crude.csv",
    'x$rr[x$schema == "S2" & x$category == "AFL-only" & x$outcome == "all"]', TOL_2DP)
reg("AFL-06", "AFL-only paragraph", "its lower bound 0.81", 0.81, "consensus_ref_crude.csv",
    'x$lo[x$schema == "S2" & x$category == "AFL-only" & x$outcome == "all"]', TOL_2DP)
reg("AFL-07", "AFL-only paragraph", "its upper bound 1.47", 1.47, "consensus_ref_crude.csv",
    'x$hi[x$schema == "S2" & x$category == "AFL-only" & x$outcome == "all"]', TOL_2DP)
reg("AFL-08", "AFL-only paragraph", "ESI AFL-only crude exacerbations 1.11", 1.11, "consensus_ref_crude.csv",
    'x$rr[x$schema == "S4" & x$category == "AFL-only" & x$outcome == "exac"]', TOL_2DP)
reg("AFL-09", "AFL-only paragraph", "its lower bound 0.89", 0.89, "consensus_ref_crude.csv",
    'x$lo[x$schema == "S4" & x$category == "AFL-only" & x$outcome == "exac"]', TOL_2DP)
reg("AFL-10", "AFL-only paragraph", "its upper bound 1.33", 1.33, "consensus_ref_crude.csv",
    'x$hi[x$schema == "S4" & x$category == "AFL-only" & x$outcome == "exac"]', TOL_2DP)
reg("AFL-11", "AFL-only paragraph", "MD-COPD AFL-only crude exacerbations 1.15", 1.15, "consensus_ref_crude.csv",
    'x$rr[x$schema == "S2" & x$category == "AFL-only" & x$outcome == "exac"]', TOL_2DP)
reg("AFL-12", "AFL-only paragraph", "its lower bound 0.89", 0.89, "consensus_ref_crude.csv",
    'x$lo[x$schema == "S2" & x$category == "AFL-only" & x$outcome == "exac"]', TOL_2DP)
reg("AFL-13", "AFL-only paragraph", "its upper bound 1.46", 1.46, "consensus_ref_crude.csv",
    'x$hi[x$schema == "S2" & x$category == "AFL-only" & x$outcome == "exac"]', TOL_2DP)
reg("AFL-14", "AFL-only paragraph", "4 respiratory deaths in the ESI AFL-only group", 4, "consensus_ref_crude.csv",
    'x$events[x$schema == "S4" & x$category == "AFL-only" & x$outcome == "resp"]', TOL_EXACT)
reg("AFL-15", "AFL-only paragraph", "2 respiratory deaths in the MD-COPD AFL-only group", 2, "consensus_ref_crude.csv",
    'x$events[x$schema == "S2" & x$category == "AFL-only" & x$outcome == "resp"]', TOL_EXACT)
reg("AFL-16", "AFL-only paragraph", "NoCT AFL-only crude all-cause 1.52", 1.52, "consensus_ref_crude.csv",
    'x$rr[x$schema == "S3" & x$category == "AFL-only" & x$outcome == "all"]', TOL_2DP)
reg("AFL-17", "AFL-only paragraph", "its lower bound 1.31", 1.31, "consensus_ref_crude.csv",
    'x$lo[x$schema == "S3" & x$category == "AFL-only" & x$outcome == "all"]', TOL_2DP)
reg("AFL-18", "AFL-only paragraph", "its upper bound 1.76", 1.76, "consensus_ref_crude.csv",
    'x$hi[x$schema == "S3" & x$category == "AFL-only" & x$outcome == "all"]', TOL_2DP)
reg("AFL-19", "AFL-only paragraph", "NoCT AFL-only crude respiratory 8.07", 8.07, "consensus_ref_crude.csv",
    'x$rr[x$schema == "S3" & x$category == "AFL-only" & x$outcome == "resp"]', TOL_2DP)
reg("AFL-20", "AFL-only paragraph", "its lower bound 4.22", 4.22, "consensus_ref_crude.csv",
    'x$lo[x$schema == "S3" & x$category == "AFL-only" & x$outcome == "resp"]', TOL_2DP)
reg("AFL-21", "AFL-only paragraph", "its upper bound 16.27", 16.27, "consensus_ref_crude.csv",
    'x$hi[x$schema == "S3" & x$category == "AFL-only" & x$outcome == "resp"]', TOL_2DP)
reg("AFL-22", "AFL-only paragraph", "NoCT AFL-only crude exacerbations 1.64", 1.64, "consensus_ref_crude.csv",
    'x$rr[x$schema == "S3" & x$category == "AFL-only" & x$outcome == "exac"]', TOL_2DP)
reg("AFL-23", "AFL-only paragraph", "its lower bound 1.38", 1.38, "consensus_ref_crude.csv",
    'x$lo[x$schema == "S3" & x$category == "AFL-only" & x$outcome == "exac"]', TOL_2DP)
reg("AFL-24", "AFL-only paragraph", "its upper bound 1.90", 1.90, "consensus_ref_crude.csv",
    'x$hi[x$schema == "S3" & x$category == "AFL-only" & x$outcome == "exac"]', TOL_2DP)
reg("AFL-25", "AFL-only paragraph", "34 respiratory deaths in the NoCT AFL-only group", 34, "consensus_ref_crude.csv",
    'x$events[x$schema == "S3" & x$category == "AFL-only" & x$outcome == "resp"]', TOL_EXACT)
reg("AFL-26", "AFL-only paragraph", "MD-COPD AFL-only crude respiratory rate ratio 1.80", 1.80, "consensus_ref_crude.csv",
    'x$rr[x$schema == "S2" & x$category == "AFL-only" & x$outcome == "resp"]', TOL_2DP)
reg("FILL-32", "Results study population", "bronchodilator change in ESI has SD 0.82", 0.82, "bronchodilator_delta_esi.csv",
    'x$sd_delta', TOL_2DP)
reg("GRP-01", "Group comparisons", "AFL-only NoCT vs MD-COPD, crude all-cause 1.38", 1.38, "group_vs_mdcopd.csv",
    'x$ratio_of_ratios[x$schema == "S3" & x$category == "AFL-only" & x$type == "crude" & x$outcome == "all"]', TOL_2DP)
reg("GRP-02", "Group comparisons", "its lower bound 1.10", 1.10, "group_vs_mdcopd.csv",
    'x$lo[x$schema == "S3" & x$category == "AFL-only" & x$type == "crude" & x$outcome == "all"]', TOL_2DP)
reg("GRP-03", "Group comparisons", "its upper bound 1.77", 1.77, "group_vs_mdcopd.csv",
    'x$hi[x$schema == "S3" & x$category == "AFL-only" & x$type == "crude" & x$outcome == "all"]', TOL_2DP)
reg("GRP-04", "Group comparisons", "its p = 0.002", 0.002, "group_vs_mdcopd.csv",
    'x$p_boot[x$schema == "S3" & x$category == "AFL-only" & x$type == "crude" & x$outcome == "all"]', TOL_3DP)
reg("GRP-05", "Group comparisons", "AFL-only NoCT vs MD-COPD, crude exacerbations 1.42", 1.42, "group_vs_mdcopd.csv",
    'x$ratio_of_ratios[x$schema == "S3" & x$category == "AFL-only" & x$type == "crude" & x$outcome == "exac"]', TOL_2DP)
reg("GRP-06", "Group comparisons", "its lower bound 1.15", 1.15, "group_vs_mdcopd.csv",
    'x$lo[x$schema == "S3" & x$category == "AFL-only" & x$type == "crude" & x$outcome == "exac"]', TOL_2DP)
reg("GRP-07", "Group comparisons", "its upper bound 1.79", 1.79, "group_vs_mdcopd.csv",
    'x$hi[x$schema == "S3" & x$category == "AFL-only" & x$type == "crude" & x$outcome == "exac"]', TOL_2DP)
reg("GRP-08", "Group comparisons", "its p < 0.005", 1, "group_vs_mdcopd.csv",
    'as.integer(x$p_boot[x$schema == "S3" & x$category == "AFL-only" & x$type == "crude" & x$outcome == "exac"] < 0.005)', TOL_EXACT)
reg("GRP-09", "Group comparisons", "AFL-only ESI vs MD-COPD, crude all-cause p = 0.25", 0.25, "group_vs_mdcopd.csv",
    'x$p_boot[x$schema == "S4" & x$category == "AFL-only" & x$type == "crude" & x$outcome == "all"]', TOL_2DP)
reg("GRP-10", "Group comparisons", "AFL-only ESI vs MD-COPD, crude exacerbations p = 0.73", 0.73, "group_vs_mdcopd.csv",
    'x$p_boot[x$schema == "S4" & x$category == "AFL-only" & x$type == "crude" & x$outcome == "exac"]', TOL_2DP)
reg("GRP-11", "Group comparisons", "COPD-major NoCT vs MD-COPD, crude ratios from 1.18", 1.18, "group_vs_mdcopd.csv",
    'min(x$ratio_of_ratios[x$schema == "S3" & x$category == "COPD-major" & x$type == "crude"])', TOL_2DP)
reg("GRP-12", "Group comparisons", "to 1.28", 1.28, "group_vs_mdcopd.csv",
    'max(x$ratio_of_ratios[x$schema == "S3" & x$category == "COPD-major" & x$type == "crude"])', TOL_2DP)
reg("GRP-13", "Group comparisons", "COPD-major ESI vs MD-COPD, crude ratios from 1.05", 1.05, "group_vs_mdcopd.csv",
    'min(x$ratio_of_ratios[x$schema == "S4" & x$category == "COPD-major" & x$type == "crude"])', TOL_2DP)
reg("GRP-14", "Group comparisons", "to 1.09", 1.09, "group_vs_mdcopd.csv",
    'max(x$ratio_of_ratios[x$schema == "S4" & x$category == "COPD-major" & x$type == "crude"])', TOL_2DP)
reg("GRP-15", "Group comparisons", "every COPD-major crude comparison has p < 0.005", 1, "group_vs_mdcopd.csv",
    'as.integer(all(x$p_boot[x$category == "COPD-major" & x$type == "crude"] < 0.005))', TOL_EXACT)
reg("MINOR-09", "COPD-minor comparison", "every crude NoCT and ESI estimate is below MD-COPD\u2019s", 6,
    "group_vs_mdcopd.csv", 'sum(x$ratio_of_ratios[x$category == "COPD-minor" & x$type == "crude"] < 1)', TOL_EXACT)
reg("MINOR-07", "COPD-minor comparison", "NoCT crude exacerbation ratio is 0.90 of MD-COPD\u2019s", 0.90,
    "group_vs_mdcopd.csv", 'x$ratio_of_ratios[x$category == "COPD-minor" & x$schema == "S3" & x$type == "crude" & x$outcome == "exac"]', TOL_2DP)
reg("MINOR-08", "COPD-minor comparison", "its p = 0.036, so both CT-free exacerbation ratios are significant", 0.036,
    "group_vs_mdcopd.csv", 'x$p_boot[x$category == "COPD-minor" & x$schema == "S3" & x$type == "crude" & x$outcome == "exac"]', TOL_3DP)
reg("MINOR-01", "COPD-minor comparison", "ESI crude exacerbation ratio is 0.89 of MD-COPD\u2019s", 0.89,
    "group_vs_mdcopd.csv", 'x$ratio_of_ratios[x$category == "COPD-minor" & x$schema == "S4" & x$type == "crude" & x$outcome == "exac"]', TOL_2DP)
reg("MINOR-02", "COPD-minor comparison", "its lower bound 0.81", 0.81,
    "group_vs_mdcopd.csv", 'x$lo[x$category == "COPD-minor" & x$schema == "S4" & x$type == "crude" & x$outcome == "exac"]', TOL_2DP)
reg("MINOR-03", "COPD-minor comparison", "its upper bound 0.98", 0.98,
    "group_vs_mdcopd.csv", 'x$hi[x$category == "COPD-minor" & x$schema == "S4" & x$type == "crude" & x$outcome == "exac"]', TOL_2DP)
reg("MINOR-04", "COPD-minor comparison", "its p = 0.016", 0.016,
    "group_vs_mdcopd.csv", 'x$p_boot[x$category == "COPD-minor" & x$schema == "S4" & x$type == "crude" & x$outcome == "exac"]', TOL_3DP)
reg("MINOR-06", "COPD-minor comparison", "all-cause and exacerbation comparisons are significant for both CT-free classifications", 1,
    "group_vs_mdcopd.csv",
    'as.integer(sum(x$p_boot[x$category == "COPD-minor" & x$type == "crude"] < 0.05, na.rm = TRUE) == 4)', TOL_EXACT)
reg("FILL-30", "Discussion", "mean change in ESI after bronchodilation -0.09", -0.09,
    "bronchodilator_delta_esi.csv", 'x$mean_delta', TOL_2DP)
reg("FILL-31", "Discussion", "9,234 participants with paired ESI measurements", 9234,
    "bronchodilator_delta_esi.csv", 'x$n_paired', TOL_EXACT)
reg("FILL-23", "Fills 2026-09-11", "obstructed CT-only: 77.7% visual emphysema", 77.7,
    "discord_profile_strata.csv", 'x$pct_visual_emph[x$stratum == "Airflow limitation" & x$group == "CT-only-COPD"]', TOL_1DP)
reg("FILL-24", "Fills 2026-09-11", "obstructed CT-only: 47.4% wall thickening", 47.4,
    "discord_profile_strata.csv", 'x$pct_wall_thick[x$stratum == "Airflow limitation" & x$group == "CT-only-COPD"]', TOL_1DP)
reg("FILL-25", "Discussion", "ESI-only crude all-cause rate ratio 1.39 (preserved spirometry)", 1.39,
    "discord_crude_strata.csv", 'x$rr[x$stratum == "Preserved spirometry" & x$group == "ESI-only-COPD" & x$outcome == "all"]', TOL_2DP)
reg("FILL-26", "Discussion", "its lower bound 1.11", 1.11,
    "discord_crude_strata.csv", 'x$lo[x$stratum == "Preserved spirometry" & x$group == "ESI-only-COPD" & x$outcome == "all"]', TOL_2DP)
reg("FILL-27", "Discussion", "its upper bound 1.74", 1.74,
    "discord_crude_strata.csv", 'x$hi[x$stratum == "Preserved spirometry" & x$group == "ESI-only-COPD" & x$outcome == "all"]', TOL_2DP)
reg("FILL-28", "Discussion", "Both-COPD crude all-cause rate ratio 1.80 (preserved spirometry)", 1.80,
    "discord_crude_strata.csv", 'x$rr[x$stratum == "Preserved spirometry" & x$group == "Both-COPD" & x$outcome == "all"]', TOL_2DP)
reg("FILL-29", "Discussion", "its upper bound 2.15", 2.15,
    "discord_crude_strata.csv", 'x$hi[x$stratum == "Preserved spirometry" & x$group == "Both-COPD" & x$outcome == "all"]', TOL_2DP)
reg("FILL-20", "Fills 2026-09-11", "AFL-only FEV1 decline -4.9 mL/yr under the NoCT classification",
    -4.9, "fev1_noct_vs_esi.csv", 'x$est_noct[x$category == "AFL-only"]', TOL_1DP)
reg("FILL-21", "Fills 2026-09-11", "AFL-only FEV1 decline -4.3 mL/yr under the ESI classification",
    -4.3, "fev1_noct_vs_esi.csv", 'x$est_esi[x$category == "AFL-only"]', TOL_1DP)
reg("FILL-22", "Fills 2026-09-11", "the NoCT minus ESI difference in AFL-only decline is p=0.68",
    0.68, "fev1_noct_vs_esi.csv", 'x$p_boot[x$category == "AFL-only"]', TOL_2DP)
reg("FILL-01", "Fills 2026-09-11", "common noCOPD reference n=3,856", 3856, "consensus_ref_group.csv",
    'x$n_cohort', TOL_EXACT)
reg("FILL-02", "Fills 2026-09-11", "preserved: visual emphysema 100% in CT-only", 100, "discord_profile_strata.csv",
    'x$pct_visual_emph[x$stratum == "Preserved spirometry" & x$group == "CT-only-COPD"]', TOL_1DP)
reg("FILL-03", "Fills 2026-09-11", "preserved: visual emphysema 1.2% in ESI-only", 1.2, "discord_profile_strata.csv",
    'x$pct_visual_emph[x$stratum == "Preserved spirometry" & x$group == "ESI-only-COPD"]', TOL_1DP)
reg("FILL-04", "Fills 2026-09-11", "preserved: visual emphysema contrast p<0.001", 1, "discord_profile_tests.csv",
    'as.integer(x$p[x$stratum == "Preserved spirometry" & x$measure == "emph_yn" & x$group1 == "CT-only-COPD" & x$group2 == "ESI-only-COPD"] < 0.001)', TOL_EXACT)
reg("FILL-05", "Fills 2026-09-11", "preserved: mean %LAA-950 1.91 in CT-only", 1.91, "discord_profile_strata.csv",
    'x$mean_LAA950[x$stratum == "Preserved spirometry" & x$group == "CT-only-COPD"]', TOL_2DP)
reg("FILL-06", "Fills 2026-09-11", "preserved: mean %LAA-950 1.24 in ESI-only", 1.24, "discord_profile_strata.csv",
    'x$mean_LAA950[x$stratum == "Preserved spirometry" & x$group == "ESI-only-COPD"]', TOL_2DP)
reg("FILL-07", "Fills 2026-09-11", "preserved: %LAA-950 contrast p=0.001", 0.001, "discord_profile_tests.csv",
    'x$p[x$stratum == "Preserved spirometry" & x$measure == "Insp_LAA950_total_Thirona" & x$group1 == "CT-only-COPD" & x$group2 == "ESI-only-COPD"]', TOL_3DP)
reg("FILL-08", "Fills 2026-09-11", "preserved: wall thickening 100% in CT-only", 100, "discord_profile_strata.csv",
    'x$pct_wall_thick[x$stratum == "Preserved spirometry" & x$group == "CT-only-COPD"]', TOL_1DP)
reg("FILL-09", "Fills 2026-09-11", "preserved: wall thickening 0.6% in ESI-only", 0.6, "discord_profile_strata.csv",
    'x$pct_wall_thick[x$stratum == "Preserved spirometry" & x$group == "ESI-only-COPD"]', TOL_1DP)
reg("FILL-10", "Fills 2026-09-11", "preserved: wall thickening contrast p<0.001", 1, "discord_profile_tests.csv",
    'as.integer(x$p[x$stratum == "Preserved spirometry" & x$measure == "wall_yn" & x$group1 == "CT-only-COPD" & x$group2 == "ESI-only-COPD"] < 0.001)', TOL_EXACT)
reg("FILL-11", "Fills 2026-09-11", "preserved: mean ESI 0.90 in CT-only", 0.9, "discord_profile_strata.csv",
    'x$mean_ESI[x$stratum == "Preserved spirometry" & x$group == "CT-only-COPD"]', TOL_2DP)
reg("FILL-12", "Fills 2026-09-11", "preserved: mean ESI 0.97 in ESI-only", 0.97, "discord_profile_strata.csv",
    'x$mean_ESI[x$stratum == "Preserved spirometry" & x$group == "ESI-only-COPD"]', TOL_2DP)
reg("FILL-13", "Fills 2026-09-11", "preserved: ESI contrast p=0.13", 0.13, "discord_profile_tests.csv",
    'x$p[x$stratum == "Preserved spirometry" & x$measure == "ESI" & x$group1 == "CT-only-COPD" & x$group2 == "ESI-only-COPD"]', TOL_2DP)
reg("FILL-14", "Fills 2026-09-11", "obstructed: mean %LAA-950 4.80 in ESI-only", 4.8, "discord_profile_strata.csv",
    'x$mean_LAA950[x$stratum == "Airflow limitation" & x$group == "ESI-only-COPD"]', TOL_2DP)
reg("FILL-15", "Fills 2026-09-11", "obstructed: mean %LAA-950 4.09 in CT-only", 4.09, "discord_profile_strata.csv",
    'x$mean_LAA950[x$stratum == "Airflow limitation" & x$group == "CT-only-COPD"]', TOL_2DP)
reg("FILL-16", "Fills 2026-09-11", "obstructed: %LAA-950 contrast p=0.53", 0.53, "discord_profile_tests.csv",
    'x$p[x$stratum == "Airflow limitation" & x$measure == "Insp_LAA950_total_Thirona" & x$group1 == "CT-only-COPD" & x$group2 == "ESI-only-COPD"]', TOL_2DP)
reg("FILL-17", "Fills 2026-09-11", "obstructed: mean ESI 2.25 in ESI-only", 2.25, "discord_profile_strata.csv",
    'x$mean_ESI[x$stratum == "Airflow limitation" & x$group == "ESI-only-COPD"]', TOL_2DP)
reg("FILL-18", "Fills 2026-09-11", "obstructed: mean ESI 1.21 in CT-only", 1.21, "discord_profile_strata.csv",
    'x$mean_ESI[x$stratum == "Airflow limitation" & x$group == "CT-only-COPD"]', TOL_2DP)
reg("FILL-19", "Fills 2026-09-11", "obstructed: ESI contrast p<0.001", 1, "discord_profile_tests.csv",
    'as.integer(x$p[x$stratum == "Airflow limitation" & x$measure == "ESI" & x$group1 == "CT-only-COPD" & x$group2 == "ESI-only-COPD"] < 0.001)', TOL_EXACT)

reg("RECL-01", "Reclassification", "833 COPD-major become AFL-only without CT",
    833, "reclassification.csv", RC("S3", "major_to_aflonly"), TOL_EXACT)
reg("RECL-02", "Reclassification", "350 do so with ESI", 350,
    "reclassification.csv", RC("S4", "major_to_aflonly"), TOL_EXACT)
reg("RECL-04", "Reclassification", "that is 833 of 3,809 participants", 833,
    "reclassification.csv", 'x$ct_only_major[1]', TOL_EXACT)
# The two counts are the same number for a reason: without a structural
# criterion, exactly the participants whose only minor criteria were CT
# findings are the ones who lose the category. If these ever diverge the
# explanation in the Results is wrong.
reg("RECL-05", "Reclassification",
    "the CT-only COPD-major group is exactly the group schema 3 loses",
    TRUE, "reclassification.csv",
    'x$ct_only_major[1] == x$major_to_aflonly[x$schema == "S3"]', TOL_EXACT)
reg("RECL-06", "Reclassification", "schema 3 keeps all 275 true AFL-only", 275,
    "reclassification.csv", RC("S3", "aflonly_kept"), TOL_EXACT)


# --- common noCOPD reference across the three classifications -------------
# Every estimate against the same 3,745 participants, so the three
# classifications sit on one scale. The AFL-only respiratory contrast is the
# section's claim and it rests on raw counts, which are registered too.
CN <- function(sch, cat, fld)
  sprintf('x$%s[x$schema == "%s" & x$category == "%s"]', fld, sch, cat)
CNC <- function(sch, cat, out, fld)
  sprintf('x$%s[x$schema == "%s" & x$category == "%s" & x$outcome == "%s"]',
          fld, sch, cat, out)

reg("CONSREF-00", "Common reference",
    "common reference holds 3,856 participants", 3856,
    "consensus_ref_group.csv", "x$n_cohort", TOL_EXACT)
reg("CONSREF-01", "Common reference",
    "MD-COPD AFL-only all-cause HR 0.91 against the common reference", 0.91,
    "consensus_ref_risk.csv", CN("S2", "AFL-only", "all_HR"), TOL_2DP)
reg("CONSREF-02", "Common reference",
    "ESI-MD-COPD AFL-only all-cause HR 0.94", 0.94,
    "consensus_ref_risk.csv", CN("S4", "AFL-only", "all_HR"), TOL_2DP)
reg("CONSREF-03", "Common reference",
    "NoCT-MD-COPD AFL-only all-cause HR 1.11", 1.11,
    "consensus_ref_risk.csv", CN("S3", "AFL-only", "all_HR"), TOL_2DP)
reg("CONSREF-04", "Common reference",
    "NoCT-MD-COPD AFL-only crude respiratory rate ratio 8.07", 8.07,
    "consensus_ref_crude.csv", CNC("S3", "AFL-only", "resp", "rr"), TOL_2DP)
reg("CONSREF-05", "Common reference",
    "MD-COPD AFL-only crude respiratory rate ratio 1.80", 1.80,
    "consensus_ref_crude.csv", CNC("S2", "AFL-only", "resp", "rr"), TOL_2DP)
reg("CONSREF-06", "Common reference",
    "ESI-MD-COPD AFL-only crude respiratory rate ratio 1.88", 1.88,
    "consensus_ref_crude.csv", CNC("S4", "AFL-only", "resp", "rr"), TOL_2DP)
# The three raw counts the argument actually rests on.
reg("CONSREF-07", "Common reference",
    "MD-COPD AFL-only had 2 respiratory deaths", 2,
    "consensus_ref_risk.csv", CN("S2", "AFL-only", "resp_deaths"), TOL_EXACT)
reg("CONSREF-08", "Common reference",
    "NoCT-MD-COPD AFL-only had 34 respiratory deaths", 34,
    "consensus_ref_risk.csv", CN("S3", "AFL-only", "resp_deaths"), TOL_EXACT)
reg("CONSREF-09", "Common reference",
    "ESI-MD-COPD AFL-only had 4 respiratory deaths", 4,
    "consensus_ref_risk.csv", CN("S4", "AFL-only", "resp_deaths"), TOL_EXACT)
reg("CONSREF-10", "Common reference",
    "MD-COPD COPD-minor all-cause HR 1.95", 1.95,
    "consensus_ref_risk.csv", CN("S2", "COPD-minor", "all_HR"), TOL_2DP)
reg("CONSREF-11", "Common reference",
    "NoCT-MD-COPD COPD-minor all-cause HR 1.85", 1.85,
    "consensus_ref_risk.csv", CN("S3", "COPD-minor", "all_HR"), TOL_2DP)
reg("CONSREF-12", "Common reference",
    "ESI-MD-COPD COPD-minor all-cause HR 1.83", 1.83,
    "consensus_ref_risk.csv", CN("S4", "COPD-minor", "all_HR"), TOL_2DP)
reg("CONSREF-13", "Common reference",
    "MD-COPD COPD-major all-cause HR 2.67", 2.67,
    "consensus_ref_risk.csv", CN("S2", "COPD-major", "all_HR"), TOL_2DP)
reg("CONSREF-14", "Common reference",
    "NoCT-MD-COPD COPD-major all-cause HR 3.28", 3.28,
    "consensus_ref_risk.csv", CN("S3", "COPD-major", "all_HR"), TOL_2DP)
reg("CONSREF-15", "Common reference",
    "ESI-MD-COPD COPD-major all-cause HR 2.85", 2.85,
    "consensus_ref_risk.csv", CN("S4", "COPD-major", "all_HR"), TOL_2DP)

reg("CONSREF-16", "Common reference",
    "NoCT-MD-COPD AFL-only adjusted respiratory HR 5.46", 5.46,
    "consensus_ref_risk.csv", CN("S3", "AFL-only", "resp_HR"), TOL_2DP)
reg("CONSREF-17", "Common reference",
    "NoCT-MD-COPD AFL-only adjusted all-cause upper bound 1.29 covers 1", 1.29,
    "consensus_ref_risk.csv", CN("S3", "AFL-only", "all_UCI"), TOL_2DP)
reg("CONSREF-18", "Common reference",
    "ESI-MD-COPD AFL-only crude all-cause rate ratio 1.25", 1.25,
    "consensus_ref_crude.csv", CNC("S4", "AFL-only", "all", "rr"), TOL_2DP)
reg("CONSREF-19", "Common reference",
    "ESI-MD-COPD AFL-only crude all-cause lower bound 1.01 excludes 1", 1.01,
    "consensus_ref_crude.csv", CNC("S4", "AFL-only", "all", "lo"), TOL_2DP)

reg("CONSREF-20", "Common reference",
    "NoCT-MD-COPD AFL-only crude respiratory lower bound 4.22", 4.22,
    "consensus_ref_crude.csv", CNC("S3", "AFL-only", "resp", "lo"), TOL_2DP)
reg("CONSREF-21", "Common reference",
    "NoCT-MD-COPD AFL-only crude respiratory upper bound 16.27", 16.27,
    "consensus_ref_crude.csv", CNC("S3", "AFL-only", "resp", "hi"), TOL_2DP)
reg("CONSREF-22", "Common reference",
    "MD-COPD AFL-only respiratory estimate is below the event floor", 1,
    "consensus_ref_crude.csv",
    'as.integer(x$few_events[x$schema == "S2" & x$category == "AFL-only" & x$outcome == "resp"])',
    TOL_EXACT)
reg("CONSREF-23", "Common reference",
    "ESI-MD-COPD AFL-only respiratory estimate is below the event floor", 1,
    "consensus_ref_crude.csv",
    'as.integer(x$few_events[x$schema == "S4" & x$category == "AFL-only" & x$outcome == "resp"])',
    TOL_EXACT)

# Numbers the group-by-group paragraphs quote that were not yet registered.
reg("CONSREF-24", "Common reference",
    "MD-COPD AFL-only adjusted exacerbation IRR 1.30", 1.30,
    "consensus_ref_risk.csv", CN("S2", "AFL-only", "exac_IRR"), TOL_2DP)
reg("CONSREF-25", "Common reference",
    "MD-COPD AFL-only exacerbation lower bound 1.02 excludes 1", 1.02,
    "consensus_ref_risk.csv", CN("S2", "AFL-only", "exac_LCI"), TOL_2DP)
reg("CONSREF-26", "Common reference",
    "ESI-MD-COPD AFL-only adjusted exacerbation IRR 1.19", 1.19,
    "consensus_ref_risk.csv", CN("S4", "AFL-only", "exac_IRR"), TOL_2DP)
reg("CONSREF-27", "Common reference",
    "ESI-MD-COPD AFL-only exacerbation lower bound 1.00", 1.00,
    "consensus_ref_risk.csv", CN("S4", "AFL-only", "exac_LCI"), TOL_2DP)
reg("CONSREF-28", "Common reference",
    "MD-COPD AFL-only crude all-cause rate ratio 1.10", 1.10,
    "consensus_ref_crude.csv", CNC("S2", "AFL-only", "all", "rr"), TOL_2DP)
reg("CONSREF-29", "Common reference",
    "NoCT-MD-COPD AFL-only crude all-cause rate ratio 1.52", 1.52,
    "consensus_ref_crude.csv", CNC("S3", "AFL-only", "all", "rr"), TOL_2DP)
reg("CONSREF-30", "Common reference",
    "NoCT-MD-COPD AFL-only adjusted exacerbation IRR 1.73", 1.73,
    "consensus_ref_risk.csv", CN("S3", "AFL-only", "exac_IRR"), TOL_2DP)
reg("CONSREF-31", "Common reference",
    "MD-COPD AFL-only adjusted respiratory HR 1.47", 1.47,
    "consensus_ref_risk.csv", CN("S2", "AFL-only", "resp_HR"), TOL_2DP)
reg("CONSREF-32", "Common reference",
    "ESI-MD-COPD AFL-only adjusted respiratory HR 1.40", 1.40,
    "consensus_ref_risk.csv", CN("S4", "AFL-only", "resp_HR"), TOL_2DP)

# FEV1 decline is now adjusted for baseline FEV1, as the source report did.
# Every estimate is negative; the unadjusted model gave positive estimates for
# COPD-major, so these are pinned in the new direction.
reg("FEV1-01", "FEV1 decline",
    "MD-COPD COPD-major declines 5.3 mL/yr faster than the common reference", -5.33,
    "fev1_decline.csv", FD("S2", "COPD-major", "est_mL_yr"), 0.05)
reg("FEV1-02", "FEV1 decline",
    "NoCT-MD-COPD COPD-major, -5.1 mL/yr", -5.10,
    "fev1_decline.csv", FD("S3", "COPD-major", "est_mL_yr"), 0.05)
reg("FEV1-03", "FEV1 decline",
    "ESI-MD-COPD COPD-major, -5.0 mL/yr", -4.99,
    "fev1_decline.csv", FD("S4", "COPD-major", "est_mL_yr"), 0.05)
reg("FEV1-05", "FEV1 decline",
    "six of the nine estimates reach significance", 6,
    "fev1_decline.csv", "sum(x$p < 0.05)", TOL_EXACT)
reg("FEV1-06", "FEV1 decline",
    "every point estimate is negative", 9,
    "fev1_decline.csv", "sum(x$est_mL_yr < 0)", TOL_EXACT)
# Nine between-classification comparisons, three groups by three pairs. If any
# stopped overlapping, the Results claim that FEV1 decline does not distinguish
# the classifications would be false.
reg("FEV1-07", "FEV1 decline",
    "no group differs between classifications; all nine intervals overlap", 9,
    "fev1_decline.csv",
    'sum(unlist(lapply(c("AFL-only","COPD-minor","COPD-major"), function(g) { z <- x[x$category == g, ]; sapply(list(c(1,2),c(1,3),c(2,3)), function(p) z$lo[p[1]] <= z$hi[p[2]] && z$lo[p[2]] <= z$hi[p[1]]) })))',
    TOL_EXACT)
reg("FEV1-08", "FEV1 decline",
    "under ESI-MD-COPD the AFL-only group declines faster than the reference", TRUE,
    "fev1_decline.csv",
    sprintf('%s < 0 && %s < 0.05', FD("S4","AFL-only","est_mL_yr"), FD("S4","AFL-only","p")),
    TOL_EXACT)

# --- crude rate ratios quoted alongside the adjusted ----------------------
# On the corrected cohort this interval no longer includes 1. The estimate is
# unchanged in size; ESI-MD-COPD's AFL-only category is twice the size of
# MD-COPD's, so the interval is narrower. Pinned in the new direction so a
# revert would fail rather than pass silently.

# --- risk: do the labels mean what they say -------------------------------
# On the corrected cohort every MD-COPD AFL-only interval crosses 1, including
# exacerbations, which previously sat just above it. The reference category is
# now cleanly null on all three outcomes.

# Mortality shows no excess; the exacerbation interval excludes 1. The point
# estimate (1.23) is the same size as MD-COPD's own for this category (1.21),
# so this is a precision difference, not a risk difference. Both halves are
# pinned so neither can drift unnoticed.


# --- COPD major against MD-COPD, Results paragraph on the COPD major group ---
reg("MAJ-01", "COPD major vs MD-COPD",
    "NoCT COPD major relative risks are 18% to 28% higher than MD-COPD's", TRUE, "group_vs_mdcopd.csv",
    'with(x[x$schema == "S3" & x$category == "COPD-major" & x$type == "crude", ], round(100 * (min(ratio_of_ratios) - 1)) == 18 && round(100 * (max(ratio_of_ratios) - 1)) == 28)', TOL_EXACT)
reg("MAJ-02", "COPD major vs MD-COPD",
    "ESI COPD major relative risks are 5% to 9% higher than MD-COPD's", TRUE, "group_vs_mdcopd.csv",
    'with(x[x$schema == "S4" & x$category == "COPD-major" & x$type == "crude", ], round(100 * (min(ratio_of_ratios) - 1)) == 5 && round(100 * (max(ratio_of_ratios) - 1)) == 9)', TOL_EXACT)
reg("MAJ-03", "COPD major vs MD-COPD", "all six COPD major comparisons with MD-COPD have p<0.005", TRUE,
    "group_vs_mdcopd.csv", 'all(x$p_boot[x$category == "COPD-major" & x$type == "crude"] < 0.005)', TOL_EXACT)
reg("MAJ-04", "COPD major vs MD-COPD", "COPD major risk is highest under NoCT on all three outcomes", TRUE,
    "consensus_ref_crude.csv",
    'all(sapply(c("all", "resp", "exac"), function(o) { k <- x$category == "COPD-major" & x$outcome == o; x$rr[k & x$schema == "S3"] == max(x$rr[k]) }))', TOL_EXACT)

# --- rerun with the cardiac rule (2026-09-14): statements now in the text ---
reg("NEW-01", "Agreement", "ESI COPD minor agreement 59%", 59, "agreement_by_group.csv",
    'round(x$pct_esi[x$category == "COPD-minor"])', TOL_EXACT)
reg("NEW-02", "Agreement", "NoCT COPD minor agreement 60%", 60, "agreement_by_group.csv",
    'round(x$pct_noct[x$category == "COPD-minor"])', TOL_EXACT)
reg("NEW-03", "Preserved cross-tab", "74.8% noCOPD by both", 74.8, "discord_counts.csv",
    '100 * x$n[x$group == "Both-noCOPD"] / sum(x$n)', TOL_1DP)
reg("NEW-04", "Preserved cross-tab", "13.8% COPD by both", 13.8, "discord_counts.csv",
    '100 * x$n[x$group == "Both-COPD"] / sum(x$n)', TOL_1DP)
reg("NEW-05", "Preserved cross-tab", "9.7% COPD by ESI alone", 9.7, "discord_counts.csv",
    '100 * x$n[x$group == "ESI-only-COPD"] / sum(x$n)', TOL_1DP)
reg("NEW-06", "Preserved cross-tab", "1.6% COPD by CT alone", 1.6, "discord_counts.csv",
    '100 * x$n[x$group == "CT-only-COPD"] / sum(x$n)', TOL_1DP)
reg("NEW-07", "Preserved profile", "mMRC >= 2 in 84.4% of ESI-only", 84.4, "discord_profile_strata.csv",
    'x$pct_dyspnea[x$stratum == "Preserved spirometry" & x$group == "ESI-only-COPD"]', TOL_1DP)
reg("NEW-08", "Preserved profile", "mMRC >= 2 in 36.5% of CT-only", 36.5, "discord_profile_strata.csv",
    'x$pct_dyspnea[x$stratum == "Preserved spirometry" & x$group == "CT-only-COPD"]', TOL_1DP)
reg("NEW-09", "Preserved profile", "SGRQ >= 25 in 94.0% of ESI-only", 94.0, "discord_profile_strata.csv",
    'x$pct_sgrq[x$stratum == "Preserved spirometry" & x$group == "ESI-only-COPD"]', TOL_1DP)
reg("NEW-10", "Preserved profile", "SGRQ >= 25 in 58.8% of CT-only", 58.8, "discord_profile_strata.csv",
    'x$pct_sgrq[x$stratum == "Preserved spirometry" & x$group == "CT-only-COPD"]', TOL_1DP)
reg("NEW-11", "Preserved profile", "both symptom contrasts p<0.001", TRUE, "discord_profile_tests.csv",
    'all(x$p[x$stratum == "Preserved spirometry" & x$group1 == "CT-only-COPD" & x$group2 == "ESI-only-COPD" & x$measure %in% c("dysp_yn", "qol_yn")] < 0.001)', TOL_EXACT)
reg("NEW-12", "Preserved discordance risk", "all three COPD groups significantly elevated for all-cause and exacerbations", TRUE,
    "discord_crude_strata.csv", 'all(x$lo[x$stratum == "Preserved spirometry" & x$outcome %in% c("all", "exac")] > 1)', TOL_EXACT)
reg("NEW-13", "Preserved discordance risk", "exacerbation risk highest in Both-COPD", TRUE, "discord_crude_strata.csv",
    'with(x[x$stratum == "Preserved spirometry" & x$outcome == "exac", ], group[which.max(rr)] == "Both-COPD")', TOL_EXACT)
reg("NEW-14", "Preserved discordance risk", "all-cause risk highest in CT-only", TRUE, "discord_crude_strata.csv",
    'with(x[x$stratum == "Preserved spirometry" & x$outcome == "all", ], group[which.max(rr)] == "CT-only-COPD")', TOL_EXACT)
reg("NEW-15", "COPD minor", "NoCT and ESI lower than MD-COPD on all three outcomes", TRUE, "group_vs_mdcopd.csv",
    'all(x$ratio_of_ratios[x$category == "COPD-minor" & x$type == "crude"] < 1)', TOL_EXACT)
reg("NEW-16", "COPD minor", "respiratory deaths too few to compare for both", TRUE, "group_vs_mdcopd.csv",
    'all(as.logical(x$few_events[x$category == "COPD-minor" & x$type == "crude" & x$outcome == "resp"]))', TOL_EXACT)

# --- evaluate -------------------------------------------------------------
rows <- lapply(REG, function(e) {
  x <- load_artifact(e$artifact)
  got <- tryCatch(eval(parse(text = e$field), list(x = x), baseenv()),
                  error = function(err) structure(NA, msg = conditionMessage(err)))
  err_msg <- attr(got, "msg")
  status <- if (length(got) != 1 || (is.na(got) && !is.logical(e$expected))) "ERROR"
    else if (is.logical(e$expected)) {
      if (!is.logical(got)) "ERROR" else if (isTRUE(got) == isTRUE(e$expected)) "PASS" else "FAIL"
    } else if (!is.numeric(got)) "ERROR"
    else if (abs(got - e$expected) <= e$tol) "PASS" else "FAIL"
  data.frame(id = e$id, section = e$section, claim = e$claim,
             expected = as.character(e$expected), computed = as.character(got),
             artifact = e$artifact, status = status,
             error = if (is.null(err_msg)) "" else err_msg, stringsAsFactors = FALSE)
})
V <- do.call(rbind, rows)
write.csv(V, file.path(ASSETS, "VERIFICATION.csv"), row.names = FALSE)

if (nrow(V) != REGISTRY_N)
  stop(sprintf("REGISTRY SIZE CHANGED: %d evaluated, %d expected. Update REGISTRY_N if intended.",
               nrow(V), REGISTRY_N))
bad <- V[V$status != "PASS", ]
if (nrow(bad)) {
  print(bad[, c("id", "claim", "expected", "computed", "status", "error")], row.names = FALSE)
  stop(sprintf("VERIFICATION FAILED: %d of %d claims", nrow(bad), nrow(V)))
}
cat(sprintf("VERIFICATION PASSED: %d claims, 0 failed. See %s\n",
            nrow(V), file.path(ASSETS, "VERIFICATION.csv")))
