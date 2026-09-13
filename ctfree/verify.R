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
REGISTRY_N <- 240L
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
    "NoCT moves 579 noCOPD to COPD-minor and 75 the other way", TRUE,
    "reclassification.csv",
    sprintf('%s == 579 && %s == 75', RC("S3","nocopd_to_minor"), RC("S3","minor_to_nocopd")),
    TOL_EXACT)
reg("RECL-08", "Reclassification",
    "NoCT retains all 275 AFL-only, ESI retains 193", TRUE,
    "reclassification.csv",
    sprintf('%s == 275 && %s == 193', RC("S3","aflonly_kept"), RC("S4","aflonly_kept")),
    TOL_EXACT)

CM <- function(sch, o) sprintf('x$rr[x$schema == "%s" & x$category == "COPD-minor" & x$outcome == "%s"]', sch, o)
reg("CRUDE-10", "Crude estimates",
    "COPD-minor crude all-cause 1.77, 1.72 and 1.75", TRUE, "schema_crude.csv",
    sprintf('abs(%s-1.77)<0.005 && abs(%s-1.72)<0.005 && abs(%s-1.75)<0.005',
            CM("S2","all"), CM("S3","all"), CM("S4","all")), TOL_EXACT)
reg("CRUDE-11", "Crude estimates",
    "COPD-minor crude respiratory 3.27, 3.42 and 3.89", TRUE, "schema_crude.csv",
    sprintf('abs(%s-3.27)<0.005 && abs(%s-3.42)<0.005 && abs(%s-3.89)<0.005',
            CM("S2","resp"), CM("S3","resp"), CM("S4","resp")), TOL_EXACT)
reg("CRUDE-12", "Crude estimates",
    "COPD-minor crude exacerbations 3.01, 3.31 and 3.28", TRUE, "schema_crude.csv",
    sprintf('abs(%s-3.01)<0.005 && abs(%s-3.31)<0.005 && abs(%s-3.28)<0.005',
            CM("S2","exac"), CM("S3","exac"), CM("S4","exac")), TOL_EXACT)

DG <- function(g, fld) sprintf('x$%s[x$group == "%s"]', fld, g)
reg("DISC2-10", "Discordance", "Both-COPD all-cause HR 1.94", 1.94,
    "discord_adjusted.csv", DG("Both-COPD","all_HR"), TOL_2DP)
reg("DISC2-11", "Discordance", "Both-COPD respiratory HR 5.10", 5.10,
    "discord_adjusted.csv", DG("Both-COPD","resp_HR"), 0.05)
reg("DISC2-12", "Discordance", "Both-COPD exacerbation IRR 2.10", 2.10,
    "discord_adjusted.csv", DG("Both-COPD","exac_IRR"), TOL_2DP)
reg("DISC2-13", "Discordance", "the group ESI adds has respiratory HR 3.63", 3.63,
    "discord_adjusted.csv", DG("ESI-only-COPD","resp_HR"), 0.05)

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

CE <- function(o, fld) sprintf('x$%s[x$outcome == "%s"]', fld, o)
reg("CONT-01", "Continuous ESI",
    "continuous ESI predicts all-cause mortality beside FEV1/FVC, HR 1.07", 1.073,
    "continuous_esi_mortality.csv", CE("all-cause", "ESI_HR"), TOL_2DP)
reg("CONT-02", "Continuous ESI",
    "and adding it to a FEV1/FVC model improves fit, P < 0.01", TRUE,
    "continuous_esi_mortality.csv",
    sprintf('%s < 0.01', CE("all-cause", "lr_p")), TOL_EXACT)
reg("CONT-03", "Continuous ESI",
    "for respiratory mortality it adds nothing beyond FEV1/FVC", TRUE,
    "continuous_esi_mortality.csv",
    sprintf('%s > 0.05', CE("respiratory", "lr_p")), TOL_EXACT)
reg("CONT-04", "Continuous ESI",
    "in GOLD 0, each ESI unit predicts 4.6 mL/yr more FEV1 decline", -4.59,
    "continuous_esi_gold0_decline.csv", 'x$est_mL_yr', 0.05)
reg("CONT-05", "Continuous ESI", "and that association is significant", TRUE,
    "continuous_esi_gold0_decline.csv", 'x$p < 0.01', TOL_EXACT)
reg("CONT-06", "Continuous ESI",
    "ESI is essentially unchanged by bronchodilator, mean -0.09", -0.09,
    "bronchodilator_delta_esi.csv", 'x$mean_delta', TOL_2DP)
reg("CONT-07", "Continuous ESI",
    "computed on this cohort, 9,234 paired measurements", 9234,
    "bronchodilator_delta_esi.csv", 'x$n_paired', TOL_EXACT)
ET <- function(st, v) sprintf('x$mean_dESI[x$stratum == "%s" & x$visitnum == %d]', st, v)
reg("CONT-08", "Continuous ESI",
    "PRISm gains more ESI over follow-up than GOLD 0", TRUE,
    "esi_trajectory.csv",
    sprintf('%s > %s && %s > %s', ET("PRISm",2), ET("GOLD0",2),
            ET("PRISm",3), ET("GOLD0",3)), TOL_EXACT)

# --- concordant and discordant classification -----------------------------
# MD-COPD against ESI-MD-COPD, pairwise, in preserved spirometry.
DC <- function(g, fld) sprintf('x$%s[x$group == "%s"]', fld, g)
reg("DISC2-01", "Discordance", "ESI misses only 70 of MD-COPD's COPD-minor", 70,
    "discord_counts.csv", DC("CT-only-COPD", "n"), TOL_EXACT)
reg("DISC2-02", "Discordance", "ESI adds 612 the CT framework does not call COPD", 612,
    "discord_counts.csv", DC("ESI-only-COPD", "n"), TOL_EXACT)
reg("DISC2-03", "Discordance", "729 are called COPD by both", 729,
    "discord_counts.csv", DC("Both-COPD", "n"), TOL_EXACT)
reg("DISC2-04", "Discordance",
    "the two agree on 729 of MD-COPD's 799 COPD-minor, or 91.2%", TRUE,
    "discord_counts.csv",
    sprintf('abs(100 * %s / (%s + %s) - 91.2) < 0.1',
            DC("Both-COPD","n"), DC("Both-COPD","n"), DC("CT-only-COPD","n")), TOL_EXACT)
reg("DISC2-05", "Discordance",
    "the group ESI adds carries adjusted all-cause HR 1.59", 1.59,
    "discord_adjusted.csv", DC("ESI-only-COPD", "all_HR"), TOL_2DP)
reg("DISC2-06", "Discordance",
    "and its interval excludes 1, so the addition is not noise", TRUE,
    "discord_adjusted.csv", sprintf('%s > 1', DC("ESI-only-COPD", "all_LCI")), TOL_EXACT)
reg("DISC2-07", "Discordance",
    "the group ESI adds has exacerbation IRR 1.82", 1.82,
    "discord_adjusted.csv", DC("ESI-only-COPD", "exac_IRR"), TOL_2DP)
reg("DISC2-08", "Discordance",
    "CT-only-COPD has no respiratory deaths, so its HR is not estimable", TRUE,
    "discord_adjusted.csv",
    sprintf('%s == 0 && is.na(%s)', DC("CT-only-COPD","deaths_resp"),
            DC("CT-only-COPD","resp_HR")), TOL_EXACT)
reg("DISC2-09", "Discordance",
    "prior exacerbation burden is 0.09 in the reference against 0.44 in ESI-only", TRUE,
    "discord_rates.csv",
    sprintf('%s < 0.15 && %s > 0.40', DC("Both-noCOPD","prior_exac_mean"),
            DC("ESI-only-COPD","prior_exac_mean")), TOL_EXACT)

# --- paired comparison between classifications ----------------------------
# The Results previously asserted that ESI-MD-COPD "tracks the reference"
# from two overlapping intervals. These test it.
BD <- function(o, cat, fld)
  sprintf('x$%s[x$outcome == "%s" & x$category == "%s"]', fld, o, cat)
reg("PAIR-01", "Paired comparison",
    "AFL-only does not differ between the two classifications, all-cause", TRUE,
    "schema_diff_bootstrap.csv",
    sprintf('%s > 0.05', BD("all-cause mortality", "AFL-only", "p_two_sided")), TOL_EXACT)
reg("PAIR-02", "Paired comparison",
    "nor COPD-minor, on any of the three outcomes", TRUE,
    "schema_diff_bootstrap.csv",
    sprintf('%s > 0.05 && %s > 0.05 && %s > 0.05',
            BD("all-cause mortality", "COPD-minor", "p_two_sided"),
            BD("respiratory mortality", "COPD-minor", "p_two_sided"),
            BD("exacerbations", "COPD-minor", "p_two_sided")), TOL_EXACT)
reg("PAIR-03", "Paired comparison",
    "COPD-major does differ, on all three", TRUE,
    "schema_diff_bootstrap.csv",
    sprintf('%s < 0.05 && %s < 0.05 && %s < 0.05',
            BD("all-cause mortality", "COPD-major", "p_two_sided"),
            BD("respiratory mortality", "COPD-major", "p_two_sided"),
            BD("exacerbations", "COPD-major", "p_two_sided")), TOL_EXACT)
reg("PAIR-04", "Paired comparison",
    "ESI-MD-COPD assigns 1.15x the all-cause effect in COPD-major", 1.15,
    "schema_diff_bootstrap.csv",
    BD("all-cause mortality", "COPD-major", "ratio_S4_over_S2"), TOL_2DP)
reg("PAIR-05", "Paired comparison",
    "respiratory resamples run at B = 863 because events are sparse", 863,
    "schema_diff_bootstrap.csv",
    BD("respiratory mortality", "COPD-major", "B_eff"), TOL_EXACT)

# --- numbers the opening Results section quotes ---------------------------
# The gate is now reported as P values rather than chi-squares, so the P values
# themselves are pinned; the chi-squares stay registered because the artifact
# still carries them.
G <- function(o, fld) sprintf('x$%s[x$outcome == "%s"]', fld, o)
reg("GATE-01p", "MD-COPD over fixed ratio", "all-cause P < 0.001", TRUE,
    "gate_fixedratio.csv", sprintf('%s < 0.001', G("ALL-CAUSE MORTALITY","lrt_p")), TOL_EXACT)
reg("GATE-02p", "MD-COPD over fixed ratio", "respiratory P < 0.001", TRUE,
    "gate_fixedratio.csv", sprintf('%s < 0.001', G("RESPIRATORY MORTALITY","lrt_p")), TOL_EXACT)
reg("GATE-03p", "MD-COPD over fixed ratio", "exacerbation P < 0.001", TRUE,
    "gate_fixedratio.csv", sprintf('%s < 0.001', G("EXACERBATIONS","lrt_p")), TOL_EXACT)

R2 <- function(cat, fld) sprintf('x$%s[x$schema == "S2" & x$category == "%s"]', fld, cat)
C2 <- function(cat, o, fld)
  sprintf('x$%s[x$schema == "S2" & x$category == "%s" & x$outcome == "%s"]', fld, cat, o)
reg("RISK-01r", "Label meaning", "S2 AFL-only respiratory HR 1.39", 1.39,
    "schema_risk.csv", R2("AFL-only", "resp_HR"), TOL_2DP)
reg("CRUDE-08", "Crude estimates", "S2 AFL-only crude respiratory ratio 1.76", 1.76,
    "schema_crude.csv", C2("AFL-only", "resp", "rr"), TOL_2DP)
reg("CRUDE-09", "Crude estimates", "S2 AFL-only crude exacerbation ratio 1.00", 1.00,
    "schema_crude.csv", C2("AFL-only", "exac", "rr"), TOL_2DP)
reg("LAB-01c", "Labels", "S2 reference COPD-minor n = 799", 799,
    "schema_labels.csv",
    'x$n[x$schema == "S2" & x$category == "COPD-minor"]', TOL_EXACT)
reg("RISK-09", "Label meaning", "S2 COPD-minor all-cause HR 1.83", 1.83,
    "schema_risk.csv", R2("COPD-minor", "all_HR"), TOL_2DP)
reg("RISK-10", "Label meaning", "S2 COPD-minor respiratory HR 3.86", 3.86,
    "schema_risk.csv", R2("COPD-minor", "resp_HR"), TOL_2DP)
reg("RISK-11", "Label meaning", "S2 COPD-minor exacerbation IRR 2.09", 2.09,
    "schema_risk.csv", R2("COPD-minor", "exac_IRR"), TOL_2DP)

# --- ESI against quantitative CT ------------------------------------------
# Cited in Results, Study population, and shown as Supplemental Table S2. These
# were previously unregistered and the table cited for them was a correlation
# matrix among the CT measures, which did not contain them.
XC <- function(stratum, fld) sprintf('x$%s[x$stratum == "%s"]', fld, stratum)
reg("CORR-01", "ESI and CT", "r(ESI, LAA-950) across all strata = 0.78", 0.78,
    "supp_esi_ct.csv", XC("All strata", "r_LAA"), TOL_2DP)
reg("CORR-02", "ESI and CT", "r(ESI, PRM emphysema) across all strata = 0.81", 0.81,
    "supp_esi_ct.csv", XC("All strata", "r_PRM"), TOL_2DP)
reg("CORR-03", "ESI and CT", "r(ESI, LAA-950) in GOLD 0 = 0.08", 0.08,
    "supp_esi_ct.csv", XC("GOLD0", "r_LAA"), TOL_2DP)
reg("CORR-04", "ESI and CT", "r(ESI, LAA-950) in GOLD 3 = 0.58", 0.58,
    "supp_esi_ct.csv", XC("GOLD3", "r_LAA"), TOL_2DP)
reg("CORR-05", "ESI and CT",
    "the correlation strengthens with obstruction, GOLD 0 below GOLD 3", TRUE,
    "supp_esi_ct.csv",
    sprintf('%s < %s', XC("GOLD0", "r_LAA"), XC("GOLD3", "r_LAA")), TOL_EXACT)

# --- baseline description --------------------------------------------------
reg("BASE-01", "Cohort", "baseline table totals the analytic cohort, 9,240", 9240,
    "supp_baseline.csv", 'as.numeric(x$n[x$stratum == "Overall"])', TOL_EXACT)
reg("BASE-02", "Cohort", "the cohort has no never-smoker stratum", TRUE,
    "supp_baseline.csv", '!("Never" %in% x$stratum)', TOL_EXACT)

# --- the gate -------------------------------------------------------------
g <- function(o, f) sprintf('x$%s[x$outcome == "%s"]', f, o)
reg("GATE-01", "MD-COPD over fixed ratio", "all-cause LR chi-square 122.1 on 2 df",
    122.1, "gate_fixedratio.csv", g("ALL-CAUSE MORTALITY", "lrt_chisq"), TOL_1DP)
reg("GATE-02", "MD-COPD over fixed ratio", "respiratory LR chi-square 76.1",
    76.1, "gate_fixedratio.csv", g("RESPIRATORY MORTALITY", "lrt_chisq"), TOL_1DP)
reg("GATE-03", "MD-COPD over fixed ratio", "exacerbation LR chi-square 158.9",
    158.9, "gate_fixedratio.csv", g("EXACERBATIONS", "lrt_chisq"), TOL_1DP)
reg("GATE-04", "MD-COPD over fixed ratio", "all-cause C-index gain is only +0.010",
    0.010, "gate_fixedratio.csv",
    'x$c_mdcopd[1] - x$c_fixedratio[1]', TOL_3DP)
# Guard the interpretation, not just the number: the gain must stay small, or
# the paper's "reclassification, not prediction" framing needs revisiting.
reg("GATE-05", "MD-COPD over fixed ratio", "C-index gain stays under 0.02",
    TRUE, "gate_fixedratio.csv",
    '{ dlt <- x$c_mdcopd - x$c_fixedratio; all(dlt[!is.na(dlt)] < 0.02) }', TOL_EXACT)

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
reg("FIT-04a", "Fitting", "held-out macro-F1, S4 = 0.752", 0.752, "schema_fit.csv",
    f("S4", "macroF1_heldout"), TOL_3DP)
reg("FIT-04b", "Fitting", "held-out macro-F1, S3 = 0.721", 0.721, "schema_fit.csv",
    f("S3", "macroF1_heldout"), TOL_3DP)
reg("FIT-05a", "Fitting", "S4 beats S3 by +0.031 held out", 0.031,
    "schema_fit_cv_diff.csv", 'x$diff_mean', TOL_3DP)
reg("FIT-05b", "Fitting", "the S4 advantage excludes zero across folds",
    TRUE, "schema_fit_cv_diff.csv", 'x$diff_lo > 0', TOL_EXACT)
reg("FIT-07a", "Fitting",
    "corrected resampled t-test on the held-out difference gives P < 0.001", 1,
    "schema_fit_cv_test.csv", "as.integer(x$p_value < 0.001)", TOL_EXACT)
reg("FIT-07b", "Fitting",
    "ESI-MD-COPD had the higher macro-F1 in all 25 held-out folds", 25,
    "schema_fit_cv_test.csv", "x$folds_favoring_S4", TOL_EXACT)
reg("FIT-07c", "Fitting",
    "corrected 95% CI for the difference runs 0.0207 to 0.0407", 0.0207,
    "schema_fit_cv_test.csv", "x$ci_lo", TOL_3DP)

reg("FIT-06", "Fitting", "the v15 draft rule scores 0.682 on the same folds",
    0.682, "schema_fit.csv", f("S4_v15draft", "macroF1_heldout"), TOL_3DP)

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
reg("ACC-02", "Reclassification",
    "488 participants are correct under ESI-MD-COPD only", 488,
    "accuracy_test.csv", "x$only_esi_correct", TOL_EXACT)
reg("ACC-03", "Reclassification",
    "115 are correct under NoCT-MD-COPD only", 115,
    "accuracy_test.csv", "x$only_noct_correct", TOL_EXACT)

reg("RECL-09", "Reclassification",
    "ESI-MD-COPD agrees with MD-COPD for 8,126 of 9,240 participants (87.9%)", 8126,
    "reclassification.csv", 'x$concordant[x$schema == "S4"]', TOL_EXACT)
reg("RECL-10", "Reclassification",
    "NoCT-MD-COPD agrees for 7,753 of 9,240 (83.9%)", 7753,
    "reclassification.csv", 'x$concordant[x$schema == "S3"]', TOL_EXACT)
# Results: "At the level of COPD versus no COPD, agreement was 87.9% and 83.9%".
# Equal to the four-group agreement because every disagreement with MD-COPD
# crosses the COPD / no-COPD line; if these ever diverge, the sentence needs rewording.
BIN <- function(sch) sprintf(paste0('with(x[x$schema == "%s", ], 100 * sum(n[(row_cat %%in%% ',
  'c("COPD-minor", "COPD-major")) == (col_cat %%in%% c("COPD-minor", "COPD-major"))]) / sum(n))'), sch)
reg("RECL-11", "Reclassification", "COPD versus no COPD agreement is 87.9% for the ESI classification",
    87.9, "crossclass.csv", BIN("S4"), TOL_1DP)
reg("RECL-12", "Reclassification", "COPD versus no COPD agreement is 83.9% for the NoCT classification",
    83.9, "crossclass.csv", BIN("S3"), TOL_1DP)

# Results fills and the S5 sentence (2026-09-11 13:01 draft).
reg("GRP-01", "Group comparisons", "AFL-only NoCT vs MD-COPD, crude all-cause 1.38", 1.38, "group_vs_mdcopd.csv",
    'x$ratio_of_ratios[x$schema == "S3" & x$category == "AFL-only" & x$type == "crude" & x$outcome == "all"]', TOL_2DP)
reg("GRP-02", "Group comparisons", "its lower bound 1.09", 1.09, "group_vs_mdcopd.csv",
    'x$lo[x$schema == "S3" & x$category == "AFL-only" & x$type == "crude" & x$outcome == "all"]', TOL_2DP)
reg("GRP-03", "Group comparisons", "its upper bound 1.78", 1.78, "group_vs_mdcopd.csv",
    'x$hi[x$schema == "S3" & x$category == "AFL-only" & x$type == "crude" & x$outcome == "all"]', TOL_2DP)
reg("GRP-04", "Group comparisons", "its p = 0.004", 0.004, "group_vs_mdcopd.csv",
    'x$p_boot[x$schema == "S3" & x$category == "AFL-only" & x$type == "crude" & x$outcome == "all"]', TOL_3DP)
reg("GRP-05", "Group comparisons", "AFL-only NoCT vs MD-COPD, crude exacerbations 1.42", 1.42, "group_vs_mdcopd.csv",
    'x$ratio_of_ratios[x$schema == "S3" & x$category == "AFL-only" & x$type == "crude" & x$outcome == "exac"]', TOL_2DP)
reg("GRP-06", "Group comparisons", "its lower bound 1.14", 1.14, "group_vs_mdcopd.csv",
    'x$lo[x$schema == "S3" & x$category == "AFL-only" & x$type == "crude" & x$outcome == "exac"]', TOL_2DP)
reg("GRP-07", "Group comparisons", "its upper bound 1.80", 1.8, "group_vs_mdcopd.csv",
    'x$hi[x$schema == "S3" & x$category == "AFL-only" & x$type == "crude" & x$outcome == "exac"]', TOL_2DP)
reg("GRP-08", "Group comparisons", "its p < 0.005", 1, "group_vs_mdcopd.csv",
    'as.integer(x$p_boot[x$schema == "S3" & x$category == "AFL-only" & x$type == "crude" & x$outcome == "exac"] < 0.005)', TOL_EXACT)
reg("GRP-09", "Group comparisons", "AFL-only ESI vs MD-COPD, crude all-cause p = 0.25", 0.25, "group_vs_mdcopd.csv",
    'x$p_boot[x$schema == "S4" & x$category == "AFL-only" & x$type == "crude" & x$outcome == "all"]', TOL_2DP)
reg("GRP-10", "Group comparisons", "AFL-only ESI vs MD-COPD, crude exacerbations p = 0.71", 0.71, "group_vs_mdcopd.csv",
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
reg("MINOR-07", "COPD-minor comparison", "NoCT crude exacerbation ratio is 0.92 of MD-COPD\u2019s", 0.92,
    "group_vs_mdcopd.csv", 'x$ratio_of_ratios[x$category == "COPD-minor" & x$schema == "S3" & x$type == "crude" & x$outcome == "exac"]', TOL_2DP)
reg("MINOR-08", "COPD-minor comparison", "its p = 0.064, so both CT-free ratios are borderline", 0.064,
    "group_vs_mdcopd.csv", 'x$p_boot[x$category == "COPD-minor" & x$schema == "S3" & x$type == "crude" & x$outcome == "exac"]', TOL_3DP)
reg("MINOR-01", "COPD-minor comparison", "ESI crude exacerbation ratio is 0.90 of MD-COPD\u2019s", 0.90,
    "group_vs_mdcopd.csv", 'x$ratio_of_ratios[x$category == "COPD-minor" & x$schema == "S4" & x$type == "crude" & x$outcome == "exac"]', TOL_2DP)
reg("MINOR-02", "COPD-minor comparison", "its lower bound 0.83", 0.83,
    "group_vs_mdcopd.csv", 'x$lo[x$category == "COPD-minor" & x$schema == "S4" & x$type == "crude" & x$outcome == "exac"]', TOL_2DP)
reg("MINOR-03", "COPD-minor comparison", "its upper bound 1.00", 1.00,
    "group_vs_mdcopd.csv", 'x$hi[x$category == "COPD-minor" & x$schema == "S4" & x$type == "crude" & x$outcome == "exac"]', TOL_2DP)
reg("MINOR-04", "COPD-minor comparison", "its p = 0.04", 0.04,
    "group_vs_mdcopd.csv", 'x$p_boot[x$category == "COPD-minor" & x$schema == "S4" & x$type == "crude" & x$outcome == "exac"]', TOL_2DP)
reg("MINOR-05", "COPD-minor comparison", "every adjusted comparison has p > 0.38", 1,
    "group_vs_mdcopd.csv", 'as.integer(min(x$p_boot[x$category == "COPD-minor" & x$type == "adjusted"], na.rm = TRUE) > 0.38)', TOL_EXACT)
reg("MINOR-06", "COPD-minor comparison", "no other crude comparison is significant", 1,
    "group_vs_mdcopd.csv",
    'as.integer(sum(x$p_boot[x$category == "COPD-minor" & x$type == "crude"] < 0.05, na.rm = TRUE) == 1)', TOL_EXACT)
reg("FILL-30", "Discussion", "mean change in ESI after bronchodilation -0.09", -0.09,
    "bronchodilator_delta_esi.csv", 'x$mean_delta', TOL_2DP)
reg("FILL-31", "Discussion", "9,234 participants with paired ESI measurements", 9234,
    "bronchodilator_delta_esi.csv", 'x$n_paired', TOL_EXACT)
reg("FILL-23", "Fills 2026-09-11", "obstructed CT-only: 77.7% visual emphysema", 77.7,
    "discord_profile_strata.csv", 'x$pct_visual_emph[x$stratum == "Airflow limitation" & x$group == "CT-only-COPD"]', TOL_1DP)
reg("FILL-24", "Fills 2026-09-11", "obstructed CT-only: 47.4% wall thickening", 47.4,
    "discord_profile_strata.csv", 'x$pct_wall_thick[x$stratum == "Airflow limitation" & x$group == "CT-only-COPD"]', TOL_1DP)
reg("FILL-25", "Discussion", "ESI-only crude all-cause rate ratio 1.57 (preserved spirometry)", 1.57,
    "discord_crude_strata.csv", 'x$rr[x$stratum == "Preserved spirometry" & x$group == "ESI-only-COPD" & x$outcome == "all"]', TOL_2DP)
reg("FILL-26", "Discussion", "its lower bound 1.29", 1.29,
    "discord_crude_strata.csv", 'x$lo[x$stratum == "Preserved spirometry" & x$group == "ESI-only-COPD" & x$outcome == "all"]', TOL_2DP)
reg("FILL-27", "Discussion", "its upper bound 1.91", 1.91,
    "discord_crude_strata.csv", 'x$hi[x$stratum == "Preserved spirometry" & x$group == "ESI-only-COPD" & x$outcome == "all"]', TOL_2DP)
reg("FILL-28", "Discussion", "Both-COPD crude all-cause rate ratio 1.94 (preserved spirometry)", 1.94,
    "discord_crude_strata.csv", 'x$rr[x$stratum == "Preserved spirometry" & x$group == "Both-COPD" & x$outcome == "all"]', TOL_2DP)
reg("FILL-29", "Discussion", "its upper bound 2.31", 2.31,
    "discord_crude_strata.csv", 'x$hi[x$stratum == "Preserved spirometry" & x$group == "Both-COPD" & x$outcome == "all"]', TOL_2DP)
reg("FILL-20", "Fills 2026-09-11", "AFL-only FEV1 decline -5.0 mL/yr under the NoCT classification",
    -5.0, "fev1_noct_vs_esi.csv", 'x$est_noct[x$category == "AFL-only"]', TOL_1DP)
reg("FILL-21", "Fills 2026-09-11", "AFL-only FEV1 decline -4.5 mL/yr under the ESI classification",
    -4.5, "fev1_noct_vs_esi.csv", 'x$est_esi[x$category == "AFL-only"]', TOL_1DP)
reg("FILL-22", "Fills 2026-09-11", "the NoCT minus ESI difference in AFL-only decline is p=0.68",
    0.68, "fev1_noct_vs_esi.csv", 'x$p_boot[x$category == "AFL-only"]', TOL_2DP)
reg("FILL-01", "Fills 2026-09-11", "common noCOPD reference n=3,745", 3745, "consensus_ref_group.csv",
    'x$n_cohort', TOL_EXACT)
reg("FILL-02", "Fills 2026-09-11", "preserved: visual emphysema 100% in CT-only", 100, "discord_profile_strata.csv",
    'x$pct_visual_emph[x$stratum == "Preserved spirometry" & x$group == "CT-only-COPD"]', TOL_1DP)
reg("FILL-03", "Fills 2026-09-11", "preserved: visual emphysema 5.2% in ESI-only", 5.2, "discord_profile_strata.csv",
    'x$pct_visual_emph[x$stratum == "Preserved spirometry" & x$group == "ESI-only-COPD"]', TOL_1DP)
reg("FILL-04", "Fills 2026-09-11", "preserved: visual emphysema contrast p<0.001", 1, "discord_profile_tests.csv",
    'as.integer(x$p[x$stratum == "Preserved spirometry" & x$measure == "emph_yn" & x$group1 == "CT-only-COPD" & x$group2 == "ESI-only-COPD"] < 0.001)', TOL_EXACT)
reg("FILL-05", "Fills 2026-09-11", "preserved: mean %LAA-950 1.68 in CT-only", 1.68, "discord_profile_strata.csv",
    'x$mean_LAA950[x$stratum == "Preserved spirometry" & x$group == "CT-only-COPD"]', TOL_2DP)
reg("FILL-06", "Fills 2026-09-11", "preserved: mean %LAA-950 1.25 in ESI-only", 1.25, "discord_profile_strata.csv",
    'x$mean_LAA950[x$stratum == "Preserved spirometry" & x$group == "ESI-only-COPD"]', TOL_2DP)
reg("FILL-07", "Fills 2026-09-11", "preserved: %LAA-950 contrast p=0.008", 0.008, "discord_profile_tests.csv",
    'x$p[x$stratum == "Preserved spirometry" & x$measure == "Insp_LAA950_total_Thirona" & x$group1 == "CT-only-COPD" & x$group2 == "ESI-only-COPD"]', TOL_3DP)
reg("FILL-08", "Fills 2026-09-11", "preserved: wall thickening 100% in CT-only", 100, "discord_profile_strata.csv",
    'x$pct_wall_thick[x$stratum == "Preserved spirometry" & x$group == "CT-only-COPD"]', TOL_1DP)
reg("FILL-09", "Fills 2026-09-11", "preserved: wall thickening 4.7% in ESI-only", 4.7, "discord_profile_strata.csv",
    'x$pct_wall_thick[x$stratum == "Preserved spirometry" & x$group == "ESI-only-COPD"]', TOL_1DP)
reg("FILL-10", "Fills 2026-09-11", "preserved: wall thickening contrast p<0.001", 1, "discord_profile_tests.csv",
    'as.integer(x$p[x$stratum == "Preserved spirometry" & x$measure == "wall_yn" & x$group1 == "CT-only-COPD" & x$group2 == "ESI-only-COPD"] < 0.001)', TOL_EXACT)
reg("FILL-11", "Fills 2026-09-11", "preserved: mean ESI 0.90 in CT-only", 0.9, "discord_profile_strata.csv",
    'x$mean_ESI[x$stratum == "Preserved spirometry" & x$group == "CT-only-COPD"]', TOL_2DP)
reg("FILL-12", "Fills 2026-09-11", "preserved: mean ESI 0.94 in ESI-only", 0.94, "discord_profile_strata.csv",
    'x$mean_ESI[x$stratum == "Preserved spirometry" & x$group == "ESI-only-COPD"]', TOL_2DP)
reg("FILL-13", "Fills 2026-09-11", "preserved: ESI contrast p=0.14", 0.14, "discord_profile_tests.csv",
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
reg("S5-20", "Fills 2026-09-11", "S5 vs MD-COPD, ESI exacerbations: ratio 1.19", 1.19, "binary_vs_mdcopd.csv",
    'x$ratio_of_ratios[x$schema == "S4" & x$outcome == "exac"]', TOL_2DP)
reg("S5-21", "Fills 2026-09-11", "S5 vs MD-COPD, ESI exacerbations: lower bound 1.12", 1.12, "binary_vs_mdcopd.csv",
    'x$lo[x$schema == "S4" & x$outcome == "exac"]', TOL_2DP)
reg("S5-22", "Fills 2026-09-11", "S5 vs MD-COPD, ESI exacerbations: upper bound 1.27", 1.27, "binary_vs_mdcopd.csv",
    'x$hi[x$schema == "S4" & x$outcome == "exac"]', TOL_2DP)
reg("S5-23", "Fills 2026-09-11", "S5 vs MD-COPD, NoCT respiratory mortality: ratio 0.45", 0.45, "binary_vs_mdcopd.csv",
    'x$ratio_of_ratios[x$schema == "S3" & x$outcome == "resp"]', TOL_2DP)
reg("S5-24", "Fills 2026-09-11", "S5 vs MD-COPD, NoCT respiratory mortality: lower bound 0.27", 0.27, "binary_vs_mdcopd.csv",
    'x$lo[x$schema == "S3" & x$outcome == "resp"]', TOL_2DP)
reg("S5-25", "Fills 2026-09-11", "S5 vs MD-COPD, NoCT respiratory mortality: upper bound 0.68", 0.68, "binary_vs_mdcopd.csv",
    'x$hi[x$schema == "S3" & x$outcome == "resp"]', TOL_2DP)
reg("S5-26", "Fills 2026-09-11", "S5 vs MD-COPD, NoCT exacerbations: ratio 1.13", 1.13, "binary_vs_mdcopd.csv",
    'x$ratio_of_ratios[x$schema == "S3" & x$outcome == "exac"]', TOL_2DP)
reg("S5-27", "Fills 2026-09-11", "S5 vs MD-COPD, NoCT exacerbations: lower bound 1.04", 1.04, "binary_vs_mdcopd.csv",
    'x$lo[x$schema == "S3" & x$outcome == "exac"]', TOL_2DP)
reg("S5-28", "Fills 2026-09-11", "S5 vs MD-COPD, NoCT exacerbations: upper bound 1.23", 1.23, "binary_vs_mdcopd.csv",
    'x$hi[x$schema == "S3" & x$outcome == "exac"]', TOL_2DP)
reg("S5-29", "Fills 2026-09-11", "S5 vs MD-COPD, fixed ratio all-cause mortality: ratio 0.93", 0.93, "binary_vs_mdcopd.csv",
    'x$ratio_of_ratios[x$schema == "S1" & x$outcome == "all"]', TOL_2DP)
reg("S5-30", "Fills 2026-09-11", "S5 vs MD-COPD, fixed ratio all-cause mortality: lower bound 0.88", 0.88, "binary_vs_mdcopd.csv",
    'x$lo[x$schema == "S1" & x$outcome == "all"]', TOL_2DP)
reg("S5-31", "Fills 2026-09-11", "S5 vs MD-COPD, fixed ratio all-cause mortality: upper bound 0.98", 0.98, "binary_vs_mdcopd.csv",
    'x$hi[x$schema == "S1" & x$outcome == "all"]', TOL_2DP)
reg("S5-32", "Fills 2026-09-11", "S5 vs MD-COPD, fixed ratio exacerbations: ratio 0.78", 0.78, "binary_vs_mdcopd.csv",
    'x$ratio_of_ratios[x$schema == "S1" & x$outcome == "exac"]', TOL_2DP)
reg("S5-33", "Fills 2026-09-11", "S5 vs MD-COPD, fixed ratio exacerbations: lower bound 0.72", 0.72, "binary_vs_mdcopd.csv",
    'x$lo[x$schema == "S1" & x$outcome == "exac"]', TOL_2DP)
reg("S5-34", "Fills 2026-09-11", "S5 vs MD-COPD, fixed ratio exacerbations: upper bound 0.84", 0.84, "binary_vs_mdcopd.csv",
    'x$hi[x$schema == "S1" & x$outcome == "exac"]', TOL_2DP)
reg("S5-35", "Fills 2026-09-11", "S5 vs MD-COPD, ESI all-cause: not different (P >= 0.05)", 1, "binary_vs_mdcopd.csv",
    'as.integer(x$p_boot[x$schema == "S4" & x$outcome == "all"] >= 0.05)', TOL_EXACT)
reg("S5-36", "Fills 2026-09-11", "S5 vs MD-COPD, ESI respiratory: not different (P >= 0.05)", 1, "binary_vs_mdcopd.csv",
    'as.integer(x$p_boot[x$schema == "S4" & x$outcome == "resp"] >= 0.05)', TOL_EXACT)
reg("S5-37", "Fills 2026-09-11", "S5 vs MD-COPD, NoCT all-cause: not different (P >= 0.05)", 1, "binary_vs_mdcopd.csv",
    'as.integer(x$p_boot[x$schema == "S3" & x$outcome == "all"] >= 0.05)', TOL_EXACT)
reg("S5-38", "Fills 2026-09-11", "S5 vs MD-COPD, fixed ratio respiratory: not different (P >= 0.05)", 1, "binary_vs_mdcopd.csv",
    'as.integer(x$p_boot[x$schema == "S1" & x$outcome == "resp"] >= 0.05)', TOL_EXACT)

reg("RECL-01", "Reclassification", "833 COPD-major become AFL-only without CT",
    833, "reclassification.csv", RC("S3", "major_to_aflonly"), TOL_EXACT)
reg("RECL-02", "Reclassification", "350 do so with ESI", 350,
    "reclassification.csv", RC("S4", "major_to_aflonly"), TOL_EXACT)
reg("RECL-03", "Reclassification",
    "21.9% of COPD-major qualify only through a CT finding", 21.9,
    "reclassification.csv", 'x$ct_only_pct[1]', TOL_1DP)
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
    "common reference holds 3,745 participants", 3745,
    "consensus_ref_group.csv", "x$n_cohort", TOL_EXACT)
reg("CONSREF-01", "Common reference",
    "MD-COPD AFL-only all-cause HR 0.94 against the common reference", 0.94,
    "consensus_ref_risk.csv", CN("S2", "AFL-only", "all_HR"), TOL_2DP)
reg("CONSREF-02", "Common reference",
    "ESI-MD-COPD AFL-only all-cause HR 0.96", 0.96,
    "consensus_ref_risk.csv", CN("S4", "AFL-only", "all_HR"), TOL_2DP)
reg("CONSREF-03", "Common reference",
    "NoCT-MD-COPD AFL-only all-cause HR 1.14", 1.14,
    "consensus_ref_risk.csv", CN("S3", "AFL-only", "all_HR"), TOL_2DP)
reg("CONSREF-04", "Common reference",
    "NoCT-MD-COPD AFL-only crude respiratory rate ratio 10.00", 10.00,
    "consensus_ref_crude.csv", CNC("S3", "AFL-only", "resp", "rr"), TOL_2DP)
reg("CONSREF-05", "Common reference",
    "MD-COPD AFL-only crude respiratory rate ratio 2.23", 2.23,
    "consensus_ref_crude.csv", CNC("S2", "AFL-only", "resp", "rr"), TOL_2DP)
reg("CONSREF-06", "Common reference",
    "ESI-MD-COPD AFL-only crude respiratory rate ratio 2.34", 2.34,
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
    "MD-COPD COPD-minor all-cause HR 2.02", 2.02,
    "consensus_ref_risk.csv", CN("S2", "COPD-minor", "all_HR"), TOL_2DP)
reg("CONSREF-11", "Common reference",
    "NoCT-MD-COPD COPD-minor all-cause HR 2.01", 2.01,
    "consensus_ref_risk.csv", CN("S3", "COPD-minor", "all_HR"), TOL_2DP)
reg("CONSREF-12", "Common reference",
    "ESI-MD-COPD COPD-minor all-cause HR 1.97", 1.97,
    "consensus_ref_risk.csv", CN("S4", "COPD-minor", "all_HR"), TOL_2DP)
reg("CONSREF-13", "Common reference",
    "MD-COPD COPD-major all-cause HR 2.75", 2.75,
    "consensus_ref_risk.csv", CN("S2", "COPD-major", "all_HR"), TOL_2DP)
reg("CONSREF-14", "Common reference",
    "NoCT-MD-COPD COPD-major all-cause HR 3.38", 3.38,
    "consensus_ref_risk.csv", CN("S3", "COPD-major", "all_HR"), TOL_2DP)
reg("CONSREF-15", "Common reference",
    "ESI-MD-COPD COPD-major all-cause HR 2.94", 2.94,
    "consensus_ref_risk.csv", CN("S4", "COPD-major", "all_HR"), TOL_2DP)

reg("CONSREF-16", "Common reference",
    "NoCT-MD-COPD AFL-only adjusted respiratory HR 6.80", 6.80,
    "consensus_ref_risk.csv", CN("S3", "AFL-only", "resp_HR"), TOL_2DP)
reg("CONSREF-17", "Common reference",
    "NoCT-MD-COPD AFL-only adjusted all-cause upper bound 1.33 covers 1", 1.33,
    "consensus_ref_risk.csv", CN("S3", "AFL-only", "all_UCI"), TOL_2DP)
reg("CONSREF-18", "Common reference",
    "ESI-MD-COPD AFL-only crude all-cause rate ratio 1.29", 1.29,
    "consensus_ref_crude.csv", CNC("S4", "AFL-only", "all", "rr"), TOL_2DP)
reg("CONSREF-19", "Common reference",
    "ESI-MD-COPD AFL-only crude all-cause lower bound 1.04 excludes 1", 1.04,
    "consensus_ref_crude.csv", CNC("S4", "AFL-only", "all", "lo"), TOL_2DP)

reg("CONSREF-20", "Common reference",
    "NoCT-MD-COPD AFL-only crude respiratory lower bound 4.95", 4.95,
    "consensus_ref_crude.csv", CNC("S3", "AFL-only", "resp", "lo"), TOL_2DP)
reg("CONSREF-21", "Common reference",
    "NoCT-MD-COPD AFL-only crude respiratory upper bound 21.87", 21.87,
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
    "MD-COPD AFL-only adjusted exacerbation IRR 1.36", 1.36,
    "consensus_ref_risk.csv", CN("S2", "AFL-only", "exac_IRR"), TOL_2DP)
reg("CONSREF-25", "Common reference",
    "MD-COPD AFL-only exacerbation lower bound 1.08 excludes 1", 1.08,
    "consensus_ref_risk.csv", CN("S2", "AFL-only", "exac_LCI"), TOL_2DP)
reg("CONSREF-26", "Common reference",
    "ESI-MD-COPD AFL-only adjusted exacerbation IRR 1.25", 1.25,
    "consensus_ref_risk.csv", CN("S4", "AFL-only", "exac_IRR"), TOL_2DP)
reg("CONSREF-27", "Common reference",
    "ESI-MD-COPD AFL-only exacerbation lower bound 1.05 excludes 1", 1.05,
    "consensus_ref_risk.csv", CN("S4", "AFL-only", "exac_LCI"), TOL_2DP)
reg("CONSREF-28", "Common reference",
    "MD-COPD AFL-only crude all-cause rate ratio 1.13", 1.13,
    "consensus_ref_crude.csv", CNC("S2", "AFL-only", "all", "rr"), TOL_2DP)
reg("CONSREF-29", "Common reference",
    "NoCT-MD-COPD AFL-only crude all-cause rate ratio 1.57", 1.57,
    "consensus_ref_crude.csv", CNC("S3", "AFL-only", "all", "rr"), TOL_2DP)
reg("CONSREF-30", "Common reference",
    "NoCT-MD-COPD AFL-only adjusted exacerbation IRR 1.81", 1.81,
    "consensus_ref_risk.csv", CN("S3", "AFL-only", "exac_IRR"), TOL_2DP)
reg("CONSREF-31", "Common reference",
    "MD-COPD AFL-only adjusted respiratory HR 1.84", 1.84,
    "consensus_ref_risk.csv", CN("S2", "AFL-only", "resp_HR"), TOL_2DP)
reg("CONSREF-32", "Common reference",
    "ESI-MD-COPD AFL-only adjusted respiratory HR 1.75", 1.75,
    "consensus_ref_risk.csv", CN("S4", "AFL-only", "resp_HR"), TOL_2DP)

# FEV1 decline is now adjusted for baseline FEV1, as the source report did.
# Every estimate is negative; the unadjusted model gave positive estimates for
# COPD-major, so these are pinned in the new direction.
reg("FEV1-01", "FEV1 decline",
    "MD-COPD COPD-major declines 5.5 mL/yr faster than the common reference", -5.52,
    "fev1_decline.csv", FD("S2", "COPD-major", "est_mL_yr"), 0.05)
reg("FEV1-02", "FEV1 decline",
    "NoCT-MD-COPD COPD-major, -5.3 mL/yr", -5.25,
    "fev1_decline.csv", FD("S3", "COPD-major", "est_mL_yr"), 0.05)
reg("FEV1-03", "FEV1 decline",
    "ESI-MD-COPD COPD-major, -5.1 mL/yr", -5.13,
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
CR <- function(sch, cat, out, fld)
  sprintf('x$%s[x$schema == "%s" & x$category == "%s" & x$outcome == "%s"]',
          fld, sch, cat, out)
reg("CRUDE-01", "Crude estimates",
    "without CT, AFL-only crude all-cause rate ratio 1.54", 1.54,
    "schema_crude.csv", CR("S3", "AFL-only", "all", "rr"), TOL_2DP)
reg("CRUDE-02", "Crude estimates",
    "and its interval excludes 1, so the label is false unadjusted too",
    TRUE, "schema_crude.csv",
    sprintf('%s > 1', CR("S3", "AFL-only", "all", "lo")), TOL_EXACT)
reg("CRUDE-03", "Crude estimates",
    "without CT, AFL-only crude respiratory rate ratio 9.38", 9.38,
    "schema_crude.csv", CR("S3", "AFL-only", "resp", "rr"), TOL_2DP)
reg("CRUDE-04", "Crude estimates",
    "with ESI, AFL-only crude all-cause rate ratio 1.29", 1.29,
    "schema_crude.csv", CR("S4", "AFL-only", "all", "rr"), TOL_2DP)
# On the corrected cohort this interval no longer includes 1. The estimate is
# unchanged in size; ESI-MD-COPD's AFL-only category is twice the size of
# MD-COPD's, so the interval is narrower. Pinned in the new direction so a
# revert would fail rather than pass silently.
reg("CRUDE-05", "Crude estimates",
    "and its interval excludes 1", TRUE, "schema_crude.csv",
    sprintf('%s > 1', CR("S4", "AFL-only", "all", "lo")), TOL_EXACT)
reg("CRUDE-06", "Crude estimates",
    "with CT, AFL-only crude all-cause rate ratio 1.05", 1.05,
    "schema_crude.csv", CR("S2", "AFL-only", "all", "rr"), TOL_2DP)

# --- risk: do the labels mean what they say -------------------------------
R <- function(s, cat, fld) sprintf('x$%s[x$schema == "%s" & x$category == "%s"]', fld, s, cat)
reg("RISK-01", "Label meaning", "S2 AFL-only all-cause HR 0.87", 0.87,
    "schema_risk.csv", R("S2", "AFL-only", "all_HR"), TOL_2DP)
reg("RISK-01b", "Label meaning", "S2 AFL-only interval crosses 1", TRUE,
    "schema_risk.csv", sprintf('%s > 1', R("S2", "AFL-only", "all_UCI")), TOL_EXACT)
# On the corrected cohort every MD-COPD AFL-only interval crosses 1, including
# exacerbations, which previously sat just above it. The reference category is
# now cleanly null on all three outcomes.
reg("RISK-01c", "Label meaning",
    "the CT schema's AFL-only exacerbation interval crosses 1",
    TRUE, "schema_risk.csv",
    'x$exac_LCI[x$schema == "S2" & x$category == "AFL-only"] < 1', TOL_EXACT)
reg("CRUDE-07", "Crude estimates",
    "and its crude exacerbation ratio crosses 1", TRUE, "schema_crude.csv",
    'x$lo[x$schema == "S2" & x$category == "AFL-only" & x$outcome == "exac"] < 1',
    TOL_EXACT)

reg("RISK-02", "Label meaning", "S3 AFL-only respiratory HR 6.37", 6.37,
    "schema_risk.csv", R("S3", "AFL-only", "resp_HR"), TOL_2DP)
reg("RISK-02b", "Label meaning",
    "S3 AFL-only respiratory risk is significantly elevated, so the label is false",
    TRUE, "schema_risk.csv", sprintf('%s > 1', R("S3", "AFL-only", "resp_LCI")), TOL_EXACT)
reg("RISK-03", "Label meaning", "S3 AFL-only exacerbation IRR 1.78", 1.78,
    "schema_risk.csv", R("S3", "AFL-only", "exac_IRR"), TOL_2DP)
reg("RISK-04", "Label meaning", "S4 AFL-only all-cause HR 0.96", 0.96,
    "schema_risk.csv", R("S4", "AFL-only", "all_HR"), TOL_2DP)
# Mortality shows no excess; the exacerbation interval excludes 1. The point
# estimate (1.23) is the same size as MD-COPD's own for this category (1.21),
# so this is a precision difference, not a risk difference. Both halves are
# pinned so neither can drift unnoticed.
reg("RISK-04b", "Label meaning",
    "S4 AFL-only shows no excess in either mortality outcome", TRUE, "schema_risk.csv",
    sprintf('%s > 1 && %s < 1',
            R("S4", "AFL-only", "all_UCI"), R("S4", "AFL-only", "resp_LCI")), TOL_EXACT)
reg("RISK-04c", "Label meaning",
    "but its exacerbation interval excludes 1", TRUE, "schema_risk.csv",
    sprintf('%s > 1', R("S4", "AFL-only", "exac_LCI")), TOL_EXACT)
reg("RISK-04d", "Label meaning",
    "S4 AFL-only exacerbation IRR 1.23 matches S2's 1.21", 1.23,
    "schema_risk.csv", R("S4", "AFL-only", "exac_IRR"), TOL_2DP)
reg("RISK-04e", "Label meaning",
    "S2 AFL-only exacerbation IRR 1.21", 1.21,
    "schema_risk.csv", R("S2", "AFL-only", "exac_IRR"), TOL_2DP)
reg("RISK-05", "Label meaning", "S4 COPD-minor HR 1.96 tracks S2's 1.83", 1.96,
    "schema_risk.csv", R("S4", "COPD-minor", "all_HR"), TOL_2DP)
reg("RISK-06", "Label meaning", "S4 COPD-major HR 2.93", 2.93,
    "schema_risk.csv", R("S4", "COPD-major", "all_HR"), TOL_2DP)

reg("RISK-07", "Label meaning", "the CT schema's COPD-major all-cause HR is 2.54",
    2.54, "schema_risk.csv",
    'x$all_HR[x$schema == "S2" & x$category == "COPD-major"]', TOL_2DP)
reg("RISK-08", "Label meaning",
    "without CT the same category's HR rises to 3.34, being smaller and more severe",
    3.34, "schema_risk.csv",
    'x$all_HR[x$schema == "S3" & x$category == "COPD-major"]', TOL_2DP)

# --- discrimination -------------------------------------------------------
D <- function(s, fld) sprintf('x$%s[x$schema == "%s"]', fld, s)
reg("DISC-01", "Discrimination", "S3 has the best all-cause C-index, 0.721",
    0.721, "schema_discrimination.csv", D("S3", "c_allcause"), TOL_3DP)
reg("DISC-01b", "Discrimination",
    "S3 out-discriminates every other schema, which the paper must state",
    TRUE, "schema_discrimination.csv",
    'x$c_allcause[x$schema == "S3"] == max(x$c_allcause)', TOL_EXACT)
reg("DISC-02", "Discrimination", "S4 discriminates better than S2 on all-cause",
    TRUE, "schema_discrimination.csv",
    'x$c_allcause[x$schema == "S4"] > x$c_allcause[x$schema == "S2"]', TOL_EXACT)
reg("DISC-03", "Discrimination", "S4 discriminates better than S2 on respiratory",
    TRUE, "schema_discrimination.csv",
    'x$c_resp[x$schema == "S4"] > x$c_resp[x$schema == "S2"]', TOL_EXACT)

# --- bronchodilator stability, quoted in the Discussion -------------------
reg("BD-01", "Discussion", "mean ESI change on bronchodilation is -0.09", -0.09,
    "Supp_Bronchodilator_deltaESI.txt", 'as.numeric(x[["mean_delta"]])', TOL_2DP)
reg("BD-02", "Discussion", "on 10,160 paired measurements", 10160,
    "Supp_Bronchodilator_deltaESI.txt", 'as.numeric(x[["n_paired"]])', TOL_EXACT)

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
