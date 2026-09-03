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
REGISTRY_N <- 63L
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
reg("FIT-03", "Fitting", "S4 second ESI threshold is inert, at or above 6.0",
    TRUE, "schema_fit.csv", sprintf('%s >= 6.0', f("S4", "t_high")), TOL_EXACT)
reg("FIT-04a", "Fitting", "held-out macro-F1, S4 = 0.752", 0.752, "schema_fit.csv",
    f("S4", "macroF1_heldout"), TOL_3DP)
reg("FIT-04b", "Fitting", "held-out macro-F1, S3 = 0.721", 0.721, "schema_fit.csv",
    f("S3", "macroF1_heldout"), TOL_3DP)
reg("FIT-05a", "Fitting", "S4 beats S3 by +0.031 held out", 0.031,
    "schema_fit_cv_diff.csv", 'x$diff_mean', TOL_3DP)
reg("FIT-05b", "Fitting", "the S4 advantage excludes zero across folds",
    TRUE, "schema_fit_cv_diff.csv", 'x$diff_lo > 0', TOL_EXACT)
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
reg("RECL-01", "Reclassification", "833 COPD-major become AFL-only-noCOPD without CT",
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
