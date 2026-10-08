# recompute_ctfree.R -- independent recomputation of key statistics for the
# CT-free MD-COPD manuscript (5-step verification, step 1, factual accuracy).
#
# HOW TO RUN (on Channing, from the root of the reproduction clone, where
# config_paths.R defines ESI_PATH, PHE_PATH, VS_PATH, COD_PATH, EX_PATH,
# MDCOPD_PATH and ID_COL):
#
#   LC_ALL=en_US.UTF-8 Rscript recompute_ctfree.R <outdir> [path/to/config_paths.R]
#
# <outdir> is created if absent. The script refuses to start if any rc_*.csv
# already exists there (it never overwrites). The optional second argument
# points to a config file other than ./config_paths.R (used for the synthetic
# test on the laptop).
#
# What it does: re-derives the analytic cohort, the three multidimensional
# classifications (MD-COPD-CT from Bhatt's file, MD-NoCT, MD-COPD-ESI), their
# agreement, Table S1, ESI versus visual CT, crude rates and adjusted HR / IRR
# against the common noCOPD reference, and median follow-up. It is written
# from the definitions in ctfree/METHODS.md and the Rmd's stated rules, and
# does NOT source or copy the analysis code. Output is aggregate only: counts,
# means, ratios. No identifiers or participant rows are written or printed.
#
# Packages: base R, survival, MASS (both are R recommended packages).
# pROC is used only as an optional third AUC computation when installed.
# No bootstrap; single process.

options(warn = 1, stringsAsFactors = FALSE)
t_start <- Sys.time()
args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) stop("usage: Rscript recompute_ctfree.R <outdir> [config_paths.R]")
OUTDIR <- args[1]
CONFIG <- if (length(args) >= 2) args[2] else "config_paths.R"
if (!file.exists(CONFIG)) stop("config file not found: ", CONFIG)
source(CONFIG)
for (v in c("ESI_PATH", "PHE_PATH", "VS_PATH", "COD_PATH", "EX_PATH", "MDCOPD_PATH", "ID_COL"))
  if (!exists(v)) stop("config does not define ", v)

dir.create(OUTDIR, recursive = TRUE, showWarnings = FALSE)
if (length(list.files(OUTDIR, pattern = "^rc_.*\\.csv$")))
  stop("output folder already holds rc_*.csv files; refusing to overwrite: ", OUTDIR)

suppressPackageStartupMessages({
  library(survival)
  library(MASS)
})
HAVE_PROC <- "pROC" %in% rownames(installed.packages())

say <- function(...) cat(sprintf(...), "\n", sep = "")
say("recompute_ctfree.R  started %s", format(t_start))
say("R: %s | locale LC_CTYPE=%s | pROC available: %s",
    R.version.string, Sys.getlocale("LC_CTYPE"), HAVE_PROC)

written <- character(0)
put <- function(df, name) {
  p <- file.path(OUTDIR, paste0("rc_", name, ".csv"))
  if (file.exists(p)) stop("refusing to overwrite ", p)
  write.csv(df, p, row.names = FALSE)
  written <<- c(written, basename(p))
  say("  wrote %s (%d rows)", basename(p), nrow(df))
}

# Diagnostics accumulate as key/value pairs and are written at the end.
DIAG <- list()
note <- function(key, value) {
  DIAG[[length(DIAG) + 1]] <<- data.frame(key = key, value = as.character(value))
  say("  [diag] %s = %s", key, as.character(value))
}

# ---------------------------------------------------------------------------
# Reading. Delimiter decided by counting tabs vs commas in the header line;
# a UTF-8 byte-order mark is stripped (fileEncoding = "UTF-8-BOM") so the
# identifier column is found even when the file starts with one. Only the
# columns needed are kept, to keep memory modest on the 1,032-column
# phenotype file. Empty strings are read as missing.
# ---------------------------------------------------------------------------
read_cols <- function(path, need, optional = character(0)) {
  con <- file(path, encoding = "UTF-8-BOM")
  h <- readLines(con, n = 1, warn = FALSE)
  close(con)
  h <- sub("^﻿", "", h)
  ntab <- nchar(gsub("[^\t]", "", h)); ncom <- nchar(gsub("[^,]", "", h))
  sep <- if (ntab > ncom) "\t" else ","
  hdr <- strsplit(h, sep, fixed = TRUE)[[1]]
  hdr <- gsub('^"|"$', "", hdr)
  # A trailing separator leaves an empty final field that strsplit drops.
  nfields <- length(hdr) + (substring(h, nchar(h)) == sep)
  if (nfields > length(hdr)) hdr <- c(hdr, rep("", nfields - length(hdr)))
  miss <- setdiff(need, hdr)
  if (length(miss)) stop(basename(path), ": missing column(s) ", paste(miss, collapse = ", "))
  keepcols <- c(need, intersect(optional, hdr))
  cc <- ifelse(hdr %in% keepcols, NA_character_, "NULL")
  x <- read.table(path, header = TRUE, sep = sep, quote = "\"", comment.char = "",
                  na.strings = c("", "NA"), fill = TRUE, check.names = FALSE,
                  colClasses = cc, fileEncoding = "UTF-8-BOM", stringsAsFactors = FALSE)
  names(x) <- sub("^﻿", "", names(x))
  say("  read %s: sep=%s, %d header fields, %d rows, kept %d columns",
      basename(path), if (sep == "\t") "TAB" else "COMMA", length(hdr), nrow(x), ncol(x))
  x$pid <- as.character(x[[ID_COL]])
  x
}

PHE_NEED <- c(ID_COL, "visitnum", "cohort", "FEV1_FVC_post", "CT_Visual_Emph_Severity",
              "CT_Visual_Wall_Thickening", "MMRCDyspneaScor", "SGRQ_scoreTotal",
              "Chronic_Bronchitis", "gender", "race", "SmokCigNow", "finalgold_visit",
              "age_visit", "ATS_PackYears", "BMI", "FEV1pp_utah", "CoronaryArtery",
              "CongestHeartFail", "Exacerbation_Frequency", "FEV1_post",
              "years_from_baseline", "Height_CM")
say("Reading inputs")
phe <- read_cols(PHE_PATH, PHE_NEED, optional = "ExclusionaryDisease")
esi <- read_cols(ESI_PATH, c(ID_COL, "visitnum", "PrePost", "ESI"))
vs  <- read_cols(VS_PATH,  c(ID_COL, "vital_status", "days_followed"))
cod <- read_cols(COD_PATH, c(ID_COL, "Torch_Group_Basic"),
                 optional = "mortality_survival_vital_status")
ex  <- read_cols(EX_PATH,  c(ID_COL, "Total_Exacerbations", "Years_Followed"))
md  <- read_cols(MDCOPD_PATH, c(ID_COL, "MultiDim_COPD_score"),
                 optional = "MultiDim_COPD_Subtype")

num <- function(x) suppressWarnings(as.numeric(x))
for (v in setdiff(PHE_NEED, c(ID_COL, "cohort", "gender", "race", "SmokCigNow")))
  phe[[v]] <- num(phe[[v]])
esi$visitnum <- num(esi$visitnum); esi$PrePost <- num(esi$PrePost); esi$ESI <- num(esi$ESI)

ndup <- function(p) sum(duplicated(p))
note("phe_rows", nrow(phe))
note("phe_visitnum_NA", sum(is.na(phe$visitnum)))
note("esi_rows", nrow(esi))
note("vs_rows", nrow(vs)); note("vs_dup_ids", ndup(vs$pid))
note("cod_rows", nrow(cod)); note("cod_dup_ids", ndup(cod$pid))
note("ex_rows", nrow(ex)); note("ex_dup_ids", ndup(ex$pid))
note("md_rows", nrow(md)); note("md_dup_ids", ndup(md$pid))
note("phe_has_ExclusionaryDisease", "ExclusionaryDisease" %in% names(phe))

# ---------------------------------------------------------------------------
# 1. Cohort flow
# ---------------------------------------------------------------------------
say("Section 1: cohort flow")
flow <- data.frame(step = character(0), n = integer(0))
addf <- function(step, n) flow <<- rbind(flow, data.frame(step = step, n = n))

v1 <- phe[!is.na(phe$visitnum) & phe$visitnum == 1, ]
note("v1_dup_ids", ndup(v1$pid))
addf("visit 1 in phenotype file", nrow(v1))
if ("ExclusionaryDisease" %in% names(v1)) {
  note("v1_ExclusionaryDisease_nonmissing", sum(!is.na(v1$ExclusionaryDisease)))
  v1 <- v1[is.na(v1$ExclusionaryDisease), ]
}
addf("less interstitial lung disease or bronchiectasis", nrow(v1))
note("v1_cohort_NA", sum(is.na(v1$cohort)))
note("v1_cohort_never_smoked", sum(trimws(v1$cohort) %in% "Never smoked"))
v1 <- v1[!(trimws(v1$cohort) %in% "Never smoked"), ]
addf("less never-smokers", nrow(v1))
v1 <- v1[!is.na(v1$FEV1_FVC_post), ]
addf("less unacceptable spirometry", nrow(v1))

md$MultiDim_COPD_score <- num(md$MultiDim_COPD_score)
md_ok <- md[!is.na(md$MultiDim_COPD_score), ]
note("md_valid_rows", nrow(md_ok)); note("md_valid_dup_ids", ndup(md_ok$pid))
note("md_valid_ids_not_in_spirometry_set", sum(!(unique(md_ok$pid) %in% v1$pid)))
v1$md_score <- md_ok$MultiDim_COPD_score[match(v1$pid, md_ok$pid)]
if ("MultiDim_COPD_Subtype" %in% names(md_ok))
  v1$md_subtype <- md_ok$MultiDim_COPD_Subtype[match(v1$pid, md_ok$pid)]
v1 <- v1[!is.na(v1$md_score), ]
addf("less no valid MD-COPD classification (Bhatt ground truth)", nrow(v1))
# MD-COPD category counts on this set, before the ESI requirement
# (Bhatt et al. Table 1: noCOPD 4,439, AFL-only 282, COPD-minor 811, COPD-major 3,884).
.c <- ifelse(v1$md_score == 1, "COPD-major", ifelse(v1$md_score == 2, "COPD-minor",
             ifelse(v1$FEV1_FVC_post < 0.70, "AFL-only", "noCOPD")))
.t <- table(factor(.c, c("noCOPD", "AFL-only", "COPD-minor", "COPD-major")))
mdval <- data.frame(category = names(.t), ours = as.integer(.t))

# Baseline post-bronchodilator ESI. PrePost == 1 is taken as post-BD (the
# Rmd's coding). Report means by PrePost so the coding can be checked: ESI
# should fall after bronchodilator.
e1 <- esi[!is.na(esi$visitnum) & esi$visitnum == 1, ]
for (pp in sort(unique(e1$PrePost[!is.na(e1$PrePost)])))
  note(sprintf("esi_v1_PrePost%s_rows_meanESI", pp),
       sprintf("%d | %.4f", sum(e1$PrePost %in% pp), mean(e1$ESI[e1$PrePost %in% pp], na.rm = TRUE)))
e1p <- e1[e1$PrePost %in% 1 & !is.na(e1$ESI), ]
note("esi_v1_post_ids_with_multiple_rows", sum(table(e1p$pid) > 1))
esi_mean <- tapply(e1p$ESI, e1p$pid, mean)
esi_first <- tapply(e1p$ESI, e1p$pid, function(z) z[1])
v1$ESI <- as.numeric(esi_mean[v1$pid])
v1$ESI_first <- as.numeric(esi_first[v1$pid])
v1 <- v1[!is.na(v1$ESI), ]
addf("less no baseline ESI", nrow(v1))
put(mdval, "mdcopd_validation")
note("esi_mean_vs_first_maxabsdiff", max(abs(v1$ESI - v1$ESI_first)))
d <- v1
N <- nrow(d)
put(flow, "cohort_flow")

# Paired pre/post ESI at visit 1 (Methods: mean change, paired t-test).
e1pre <- e1[e1$PrePost %in% 0 & !is.na(e1$ESI), ]
pre_mean <- tapply(e1pre$ESI, e1pre$pid, mean)
pr <- data.frame(pre = as.numeric(pre_mean[d$pid]), post = d$ESI)
pr <- pr[complete.cases(pr), ]
dl <- pr$post - pr$pre
tt <- t.test(pr$post, pr$pre, paired = TRUE)
put(data.frame(n_paired = nrow(pr), mean_delta = mean(dl), sd_delta = sd(dl),
               ci_lo = tt$conf.int[1], ci_hi = tt$conf.int[2], p = tt$p.value),
    "bronchodilator_delta_esi")

# Stratum
d$stratum <- ifelse(d$finalgold_visit %in% -1, "PRISm",
                    ifelse(d$finalgold_visit %in% 0:4, paste0("GOLD", d$finalgold_visit), NA))
note("finalgold_visit_other_or_NA", sum(is.na(d$stratum)))
STRATA <- c("PRISm", paste0("GOLD", 0:4))

# ---------------------------------------------------------------------------
# 2. Criteria and the three classifications
# ---------------------------------------------------------------------------
say("Section 2: classifications")
CATS <- c("noCOPD", "AFL-only", "COPD-minor", "COPD-major")
d$afl  <- d$FEV1_FVC_post < 0.70
yes <- function(x) !is.na(x) & x            # missing criterion counts as not met
d$c_emph <- yes(d$CT_Visual_Emph_Severity >= 2)   # mild or worse (0 none, 1 trace, 2 mild ...)
d$c_wall <- yes(d$CT_Visual_Wall_Thickening == 2)  # definite
d$c_dysp <- yes(d$MMRCDyspneaScor >= 2)
d$c_sgrq <- yes(d$SGRQ_scoreTotal >= 25)
d$c_cb   <- yes(num(d$Chronic_Bronchitis) == 1)
for (v in c("CT_Visual_Emph_Severity", "CT_Visual_Wall_Thickening", "MMRCDyspneaScor",
            "SGRQ_scoreTotal", "Chronic_Bronchitis", "CoronaryArtery", "CongestHeartFail"))
  note(paste0("cohort_NA_", v), sum(is.na(d[[v]])))
d$cardiac <- (d$CoronaryArtery %in% 1) | (d$CongestHeartFail %in% 1)
d$n_sym <- d$c_dysp + d$c_sgrq + d$c_cb

assign4 <- function(afl, n_minor, minor_path) factor(
  ifelse(afl, ifelse(n_minor >= 1, "COPD-major", "AFL-only"),
              ifelse(minor_path, "COPD-minor", "noCOPD")), levels = CATS)

# S2: Bhatt's score (1 major, 2 minor, 0 neither) split by airflow limitation.
d$S2 <- factor(ifelse(d$md_score == 1, "COPD-major",
               ifelse(d$md_score == 2, "COPD-minor",
               ifelse(d$afl, "AFL-only", "noCOPD"))), levels = CATS)
note("md_score_other_values", sum(!(d$md_score %in% c(0, 1, 2))))
# Consistency of Bhatt's score with the major criterion (aggregate cross-tab).
xs <- as.data.frame(table(score = d$md_score, afl = d$afl))
put(xs, "mdcopd_score_by_afl")
if ("md_subtype" %in% names(d))
  put(as.data.frame(table(subtype = d$md_subtype, score = d$md_score, afl = d$afl)),
      "mdcopd_subtype_by_score")

# Own reconstruction of MD-COPD-CT from the five minor criteria (>= 3 for
# COPD-minor; cardiac participants need both CT criteria). Not used for any
# result; it tests the criterion coding against Bhatt's assignments.
n5 <- d$c_emph + d$c_wall + d$n_sym
d$S2_rebuilt <- assign4(d$afl, n5, n5 >= 3 & (!d$cardiac | (d$c_emph & d$c_wall)))
put(as.data.frame(table(rebuilt = d$S2_rebuilt, bhatt = d$S2)), "mdcopd_rebuilt_vs_file")
note("mdcopd_rebuilt_agreement", sprintf("%.6f", mean(d$S2_rebuilt == d$S2)))
# Rmd assertion re-checked: every cardiac Bhatt COPD-minor meets both CT criteria
note("cardiac_bhatt_minor_without_both_CT",
     sum(d$cardiac & d$S2 == "COPD-minor" & !(d$c_emph & d$c_wall)))

S3_K <- 2L; S4_K <- 2L; S4_T <- 1.50
s3 <- function(dd, k) assign4(dd$afl, dd$n_sym, dd$n_sym >= k & !dd$cardiac)
s4 <- function(dd, k, t) {
  e <- as.integer(dd$ESI >= t)
  assign4(dd$afl, dd$n_sym + e, (dd$n_sym + e) >= k & (!dd$cardiac | e == 1))
}
d$S1 <- factor(ifelse(d$afl, "COPD", "noCOPD"), levels = c("noCOPD", "COPD"))
d$S3 <- s3(d, S3_K)
d$S4 <- s4(d, S4_K, S4_T)

# Independent re-fit of the thresholds by macro-F1 (in-sample, full cohort).
f1_cat <- function(ref, est) vapply(CATS, function(g) {
  tp <- sum(ref == g & est == g); np <- sum(est == g); nr <- sum(ref == g)
  if (tp == 0) 0 else 2 * tp / (np + nr)
}, numeric(1))
mf1 <- function(ref, est) mean(f1_cat(ref, est))
fitrows <- list()
for (k in 1:3) fitrows[[length(fitrows) + 1]] <-
  data.frame(schema = "S3", k = k, t_low = NA_real_, macroF1 = mf1(d$S2, s3(d, k)))
for (k in 2:4) for (t in seq(0.50, 4.00, by = 0.25)) fitrows[[length(fitrows) + 1]] <-
  data.frame(schema = "S4", k = k, t_low = t, macroF1 = mf1(d$S2, s4(d, k, t)))
fitg <- do.call(rbind, fitrows)
best <- do.call(rbind, lapply(c("S3", "S4"), function(s) {
  z <- fitg[fitg$schema == s, ]; z[which.max(z$macroF1), ]
}))
best$n_ties_at_max <- sapply(c("S3", "S4"), function(s) {
  z <- fitg$macroF1[fitg$schema == s]; sum(abs(z - max(z)) < 1e-12) })
put(best, "fit_selected")
put(fitg, "fit_grid")
if (!(best$k[1] == S3_K && best$k[2] == S4_K && isTRUE(all.equal(best$t_low[2], S4_T))))
  say("  NOTE: independent macro-F1 fit selects different parameters than the paper's (k3=2; k4=2, t=1.50)")

# Category counts
lab <- do.call(rbind, lapply(c("S1", "S2", "S3", "S4"), function(s) {
  tb <- table(d[[s]]); data.frame(schema = s, category = names(tb), n = as.integer(tb))
}))
put(lab, "schema_labels")

# Cross-classification: rows = modified classification, cols = MD-COPD-CT
xc <- do.call(rbind, lapply(c("S3", "S4"), function(s) {
  tb <- table(factor(d[[s]], CATS), factor(d$S2, CATS))
  do.call(rbind, lapply(CATS, function(r) data.frame(schema = s, row_cat = r, col_cat = CATS,
                                                     n = as.integer(tb[r, CATS]))))
}))
put(xc, "crossclass")

agr <- list()
for (s in c("S3", "S4")) {
  tb <- table(factor(d[[s]], CATS), factor(d$S2, CATS))
  for (g in CATS) agr[[length(agr) + 1]] <- data.frame(
    schema = s, category = g, n_ref = sum(tb[, g]), n_assigned = sum(tb[g, ]),
    n_agree = tb[g, g],
    sensitivity_pct = 100 * tb[g, g] / sum(tb[, g]),
    ppv_pct = 100 * tb[g, g] / sum(tb[g, ]),
    f1 = 2 * tb[g, g] / (sum(tb[, g]) + sum(tb[g, ])))
  agr[[length(agr) + 1]] <- data.frame(
    schema = s, category = "overall", n_ref = N, n_assigned = N, n_agree = sum(diag(tb)),
    sensitivity_pct = 100 * sum(diag(tb)) / N, ppv_pct = NA_real_, f1 = mf1(d$S2, d[[s]]))
}
agr <- do.call(rbind, agr)
put(agr, "agreement")
c3 <- d$S3 == d$S2; c4 <- d$S4 == d$S2
b <- sum(c3 & !c4); cc <- sum(!c3 & c4)
put(data.frame(n = N, correct_noct = sum(c3), correct_esi = sum(c4),
               only_esi_correct = cc, only_noct_correct = b,
               mcnemar_chisq_uncorrected = (b - cc)^2 / (b + cc),
               p_value = pchisq((b - cc)^2 / (b + cc), 1, lower.tail = FALSE)),
    "accuracy_test")

# Reclassification counts quoted in Results
put(do.call(rbind, lapply(c("S3", "S4"), function(s) data.frame(
  schema = s,
  major_to_aflonly = sum(d$S2 == "COPD-major" & d[[s]] == "AFL-only"),
  pct_of_major = 100 * sum(d$S2 == "COPD-major" & d[[s]] == "AFL-only") / sum(d$S2 == "COPD-major"),
  minor_to_nocopd = sum(d$S2 == "COPD-minor" & d[[s]] == "noCOPD"),
  nocopd_to_minor = sum(d$S2 == "noCOPD" & d[[s]] == "COPD-minor")))), "reclassification")

# ---------------------------------------------------------------------------
# 3. Table S1 by stratum (numeric, unformatted)
# ---------------------------------------------------------------------------
say("Section 3: Table S1")
ms <- function(x) c(mean(x, na.rm = TRUE), sd(x, na.rm = TRUE), sum(!is.na(x)))
s1row <- function(dd, label) {
  a <- ms(dd$age_visit); p <- ms(dd$ATS_PackYears); b <- ms(dd$BMI)
  f <- ms(dd$FEV1pp_utah); r <- ms(dd$FEV1_FVC_post); e <- ms(dd$ESI)
  data.frame(stratum = label, n = nrow(dd),
             age_mean = a[1], age_sd = a[2],
             pct_female = 100 * sum(as.character(dd$gender) == "2", na.rm = TRUE) / sum(!is.na(dd$gender)),
             pct_current = 100 * sum(as.character(dd$SmokCigNow) == "1", na.rm = TRUE) / sum(!is.na(dd$SmokCigNow)),
             packyears_mean = p[1], packyears_sd = p[2], packyears_n = p[3],
             BMI_mean = b[1], BMI_sd = b[2],
             FEV1pp_mean = f[1], FEV1pp_sd = f[2], FEV1pp_n = f[3],
             FEV1FVC_mean = r[1], FEV1FVC_sd = r[2],
             ESI_mean = e[1], ESI_sd = e[2],
             pct_mMRC2 = 100 * mean(dd$c_dysp), pct_SGRQ25 = 100 * mean(dd$c_sgrq),
             pct_CB = 100 * mean(dd$c_cb))
}
# Percentages use the non-missing denominator; gender 2 = female, SmokCigNow 1 = current.
tS1 <- do.call(rbind, c(lapply(STRATA, function(s) s1row(d[d$stratum %in% s, ], s)),
                        list(s1row(d, "Overall"))))
put(tS1, "supp_baseline")

# ---------------------------------------------------------------------------
# 4. ESI against the visual CT criteria
# ---------------------------------------------------------------------------
say("Section 4: ESI vs visual CT")
lv <- list()
EL <- c("none", "trace", "mild", "moderate", "confluent", "advanced destructive")
for (k in 0:5) { i <- d$CT_Visual_Emph_Severity %in% k
  lv[[length(lv) + 1]] <- data.frame(criterion = "Visual emphysema", level = k, label = EL[k + 1],
                                     n = sum(i), mean_ESI = mean(d$ESI[i])) }
WL <- c("absent", "borderline", "definite")
for (k in 0:2) { i <- d$CT_Visual_Wall_Thickening %in% k
  lv[[length(lv) + 1]] <- data.frame(criterion = "Airway wall thickening", level = k, label = WL[k + 1],
                                     n = sum(i), mean_ESI = mean(d$ESI[i])) }
lv[[length(lv) + 1]] <- data.frame(criterion = "Visual emphysema", level = NA, label = "missing",
  n = sum(is.na(d$CT_Visual_Emph_Severity)), mean_ESI = mean(d$ESI[is.na(d$CT_Visual_Emph_Severity)]))
lv[[length(lv) + 1]] <- data.frame(criterion = "Airway wall thickening", level = NA, label = "missing",
  n = sum(is.na(d$CT_Visual_Wall_Thickening)), mean_ESI = mean(d$ESI[is.na(d$CT_Visual_Wall_Thickening)]))
put(do.call(rbind, lv), "esi_ct_levels")

# AUC by counting, for each positive, negatives scoring lower plus half the ties
# (a different algorithm from the rank-sum formula).
auc_count <- function(score, y) {
  pos <- score[y]; neg <- sort(score[!y])
  if (!length(pos) || !length(neg)) return(NA_real_)
  lt <- findInterval(pos, neg, left.open = TRUE)
  le <- findInterval(pos, neg)
  sum(lt + 0.5 * (le - lt)) / (length(pos) * length(neg))
}
auc_proc <- function(score, y) {
  if (!HAVE_PROC || length(unique(y)) < 2) return(NA_real_)
  as.numeric(pROC::auc(pROC::roc(y, score, levels = c(FALSE, TRUE), direction = "<", quiet = TRUE)))
}
au <- list()
STR <- list("All participants" = rep(TRUE, N), "Airflow limitation" = d$afl,
            "Preserved spirometry" = !d$afl)
CRI <- list("Visual emphysema" = list(y = d$c_emph, raw = d$CT_Visual_Emph_Severity),
            "Airway wall thickening" = list(y = d$c_wall, raw = d$CT_Visual_Wall_Thickening))
for (sn in names(STR)) for (cn in names(CRI)) for (hd in c("missing_as_negative", "complete_case")) {
  i <- STR[[sn]]
  if (hd == "complete_case") i <- i & !is.na(CRI[[cn]]$raw)
  y <- CRI[[cn]]$y[i]
  au[[length(au) + 1]] <- data.frame(
    stratum = sn, criterion = cn, missing_handling = hd, n = sum(i),
    prevalence = 100 * mean(y),
    auc_ESI = auc_count(d$ESI[i], y), auc_ESI_pROC = auc_proc(d$ESI[i], y),
    auc_FEV1FVC = auc_count(-d$FEV1_FVC_post[i], y))
}
put(do.call(rbind, au), "esi_ct_auc")

# ---------------------------------------------------------------------------
# 5-6. Outcomes against the common reference
# ---------------------------------------------------------------------------
say("Section 5-6: outcomes")
vs$vital_status <- num(vs$vital_status); vs$days_followed <- num(vs$days_followed)
cod$torch <- suppressWarnings(as.integer(cod$Torch_Group_Basic))
COVS <- c("age_visit", "gender", "race", "SmokCigNow", "ATS_PackYears", "BMI")
d$cons <- d$S2 == "noCOPD" & d$S3 == "noCOPD" & d$S4 == "noCOPD"

m <- merge(d, vs[, c("pid", "vital_status", "days_followed")], by = "pid")
note("mort_after_vs_join", nrow(m))
note("mort_vital_status_NA", sum(is.na(m$vital_status)))
note("mort_days_followed_NA_or_nonpositive", sum(is.na(m$days_followed) | m$days_followed <= 0))
m$torch <- cod$torch[match(m$pid, cod$pid)]
note("mort_cod_dup_rows_would_add", sum(duplicated(cod$pid) & cod$pid %in% m$pid))
m$dead <- m$vital_status
m$resp <- as.integer(m$vital_status %in% 1 & m$torch %in% 1)
m <- m[complete.cases(m[, COVS]), ]
m$py <- m$days_followed / 365.25
note("mort_n", nrow(m))
note("mort_deaths", sum(m$dead)); note("mort_resp_deaths", sum(m$resp))
note("deaths_without_torch_code", sum(m$dead %in% 1 & is.na(m$torch)))
note("alive_with_torch_code", sum(m$dead %in% 0 & !is.na(m$torch)))
tt <- table(torch = m$torch[m$dead %in% 1], useNA = "ifany")
put(data.frame(torch_group_basic = names(tt), deaths = as.integer(tt)), "torch_codes_among_deaths")
if ("mortality_survival_vital_status" %in% names(cod)) {
  m$cod_vs <- cod$mortality_survival_vital_status[match(m$pid, cod$pid)]
  put(as.data.frame(table(vs_file = m$vital_status, cod_file = m$cod_vs, useNA = "ifany")),
      "vital_status_vs_cod_file")
}

d$prior_exac <- num(d$Exacerbation_Frequency)
x <- merge(d, ex[, c("pid", "Total_Exacerbations", "Years_Followed")], by = "pid")
x$Total_Exacerbations <- num(x$Total_Exacerbations); x$Years_Followed <- num(x$Years_Followed)
note("exac_after_lfu_join", nrow(x))
x <- x[!is.na(x$Total_Exacerbations) & !is.na(x$Years_Followed) & x$Years_Followed > 0 &
       !is.na(x$prior_exac), ]
x <- x[complete.cases(x[, COVS]), ]
note("exac_n", nrow(x))

GRP <- c("AFL-only", "COPD-minor", "COPD-major")
cr <- list()
ref_m <- m[m$cons, ]; ref_x <- x[x$cons, ]
put(data.frame(n_cohort = sum(d$cons), n_mort = nrow(ref_m), n_exac = nrow(ref_x),
               deaths = sum(ref_m$dead), resp_deaths = sum(ref_m$resp),
               exac_events = sum(ref_x$Total_Exacerbations),
               person_yrs = sum(ref_m$py), fu_yrs = sum(ref_x$Years_Followed)),
    "consensus_ref_group")
for (s in c("S2", "S3", "S4")) for (g in GRP) {
  gm <- m[m[[s]] == g & !m$cons, ]; gx <- x[x[[s]] == g & !x$cons, ]
  for (o in c("all", "resp", "exac")) {
    if (o == "exac") {
      e1 <- sum(gx$Total_Exacerbations); t1 <- sum(gx$Years_Followed)
      e0 <- sum(ref_x$Total_Exacerbations); t0 <- sum(ref_x$Years_Followed)
      n1 <- nrow(gx)
    } else {
      ev <- if (o == "all") "dead" else "resp"
      e1 <- sum(gm[[ev]]); t1 <- sum(gm$py); e0 <- sum(ref_m[[ev]]); t0 <- sum(ref_m$py)
      n1 <- nrow(gm)
    }
    ci <- if (o != "exac" && e1 > 0) poisson.test(c(e1, e0), c(t1, t0))$conf.int else c(NA, NA)
    cr[[length(cr) + 1]] <- data.frame(
      schema = s, category = g, outcome = o, n = n1, events = e1, time = t1,
      rate_100py = 100 * e1 / t1, ref_events = e0, ref_time = t0,
      ref_rate_100py = 100 * e0 / t0, rr = (e1 / t1) / (e0 / t0),
      lo = ci[1], hi = ci[2])
  }
}
put(do.call(rbind, cr), "consensus_ref_crude")

fcov <- "age_visit + factor(gender) + factor(race) + factor(SmokCigNow) + ATS_PackYears + BMI"
fit_set <- function(s, cats) {
  mm <- m[m$cons | m[[s]] %in% cats, ]; xx <- x[x$cons | x[[s]] %in% cats, ]
  mm$grp <- factor(ifelse(mm$cons, "REF", as.character(mm[[s]])), c("REF", cats))
  xx$grp <- factor(ifelse(xx$cons, "REF", as.character(xx[[s]])), c("REF", cats))
  if (any(mm$cons & mm[[s]] != "noCOPD")) stop("reference overlaps a category")
  ca <- coxph(as.formula(paste("Surv(py, dead) ~ grp +", fcov)), data = mm)
  cr <- coxph(as.formula(paste("Surv(py, resp) ~ grp +", fcov)), data = mm)
  nb <- glm.nb(as.formula(paste("Total_Exacerbations ~ grp +", fcov,
                                "+ prior_exac + offset(log(Years_Followed))")), data = xx)
  z <- qnorm(0.975)
  rr <- function(fit, g) {
    nm <- paste0("grp", g)
    b <- coef(fit)[nm]; se <- sqrt(diag(vcov(fit)))[nm]
    c(exp(b), exp(b - z * se), exp(b + z * se))
  }
  do.call(rbind, lapply(cats, function(g) {
    a <- rr(ca, g); r <- rr(cr, g); e <- rr(nb, g)
    data.frame(schema = s, category = g,
               n_mort = sum(mm$grp == g), n_exac = sum(xx$grp == g),
               deaths = sum(mm$dead[mm$grp == g]), resp_deaths = sum(mm$resp[mm$grp == g]),
               all_HR = a[1], all_LCI = a[2], all_UCI = a[3],
               resp_HR = r[1], resp_LCI = r[2], resp_UCI = r[3],
               exac_IRR = e[1], exac_LCI = e[2], exac_UCI = e[3],
               nb_theta = nb$theta, n_model_mort = ca$n, n_model_exac = nrow(xx),
               row.names = NULL)
  }))
}
say("  fitting joint models (one per classification)")
joint <- do.call(rbind, lapply(c("S2", "S3", "S4"), function(s) fit_set(s, GRP)))
joint$model <- "joint: REF + 3 categories"
put(joint, "consensus_ref_risk")
say("  fitting pairwise models (REF + one category; sensitivity only)")
pairw <- do.call(rbind, lapply(c("S2", "S3", "S4"), function(s)
  do.call(rbind, lapply(GRP, function(g) fit_set(s, g)))))
pairw$model <- "pairwise: REF + 1 category"
put(pairw, "consensus_ref_risk_pairwise")

# ---------------------------------------------------------------------------
# 7. Median follow-up
# ---------------------------------------------------------------------------
say("Section 7: follow-up")
L <- phe[!is.na(phe$visitnum) & phe$visitnum %in% 1:3 & !is.na(phe$FEV1_post) &
         !is.na(phe$years_from_baseline), c("pid", "visitnum", "years_from_baseline",
                                            "FEV1_post", "age_visit", "SmokCigNow")]
basef <- L[L$visitnum == 1, ]
L <- L[L$pid %in% d$pid[!is.na(d$Height_CM)] & L$pid %in% basef$pid &
       !is.na(L$age_visit) & !is.na(L$SmokCigNow), ]
last <- tapply(L$years_from_baseline, L$pid, max)
nvis <- tapply(L$visitnum, L$pid, function(z) length(unique(z)))
fu <- function(lbl, v) data.frame(outcome = lbl, n = length(v), median_yr = median(v),
                                  q1_yr = unname(quantile(v, .25)), q3_yr = unname(quantile(v, .75)))
put(rbind(fu("mortality (all-cause and respiratory)", m$py),
          fu("exacerbations", x$Years_Followed),
          fu("FEV1 decline, everyone in the decline data", as.numeric(last)),
          fu("FEV1 decline, participants with a follow-up visit", as.numeric(last[nvis > 1]))),
    "followup_medians")

# ---------------------------------------------------------------------------
put(do.call(rbind, DIAG), "diagnostics")
say("Done in %.1f s. Files written: %d", as.numeric(difftime(Sys.time(), t_start, units = "secs")),
    length(written))
