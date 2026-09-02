#!/usr/bin/env Rscript
# ---------------------------------------------------------------------------
# Four classification schemas for the CT-free reframe, built and scored the
# same way on the same 9,402 participants.
#
#   1  Fixed ratio            FEV1/FVC < 0.70 alone
#   2  MD-COPD with CT        the reference the other schemas approximate
#   3  MD-COPD without CT     symptoms only, count threshold re-optimized
#   4  MD-COPD with ESI       ESI threshold and count threshold re-optimized
#
# Schemas 3 and 4 are fitted to approximate schema 2 by the SAME objective,
# macro-averaged F1 across the four categories. Symmetric across categories,
# as agreed, but balancing precision against recall within each: mean recall
# alone is maximized by labelling 1,119 people AFL-only-noCOPD to capture the
# 170 real ones, a group we have measured at 6.6x respiratory mortality.
# Cohen's kappa and the C-index fail the same way, all three being indifferent
# to over-calling a small category.
#
# Selection is outcome-blind. Thresholds are fitted only against schema 2's
# labels, never against mortality or exacerbations, so the risk profiles in
# Part 3 are an independent check rather than a restatement of the fit.
#
# Artifacts land in ctfree/assets/ and are the only thing the claims
# registry in ctfree/verify.R is allowed to read. Run from the repo root.
# ---------------------------------------------------------------------------
suppressPackageStartupMessages({library(dplyr); library(survival); library(MASS)})
# Locate this script's own directory, so it runs from any working directory.
.b <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
source(file.path(if (length(.b)) dirname(normalizePath(sub("^--file=", "", .b[1])))
                 else "ctfree", "_locate.R"))
OUT <- ASSETS
dir.create(OUT, recursive = TRUE, showWarnings = FALSE)
source(CONFIG)
CV_REPEATS <- 5L; CV_FOLDS <- 5L; CV_SEED <- 20260901L

read_any <- function(p, ...) { h <- readLines(p, n = 1, warn = FALSE)
  read.delim(p, sep = if (grepl("\t", h)) "\t" else ",", stringsAsFactors = FALSE, ...) }
bpid <- function(df, l) { c1 <- c(ID_COL, paste0(ID_COL, ".x"), paste0(ID_COL, ".y"))
  h <- c1[c1 %in% names(df)]; if (!length(h)) stop(l); df$pid <- as.character(df[[h[1]]]); df }

esi <- bpid(read_any(ESI_PATH), "E"); phe <- bpid(read_any(PHE_PATH, na.strings = c("", "NA")), "P")
phe <- phe[!(!is.na(phe$cohort) & trimws(phe$cohort) == "ILD/Brnch"), ]
vs <- bpid(read_any(VS_PATH), "V"); cod <- bpid(read_any(COD_PATH), "C"); ex <- bpid(read_any(EX_PATH), "X")
u <- suppressWarnings(as.integer(cod$Torch_Group_Basic)); cod$UCD_Resp <- as.integer(!is.na(u) & u == 1L)
ev1 <- esi %>% filter(visitnum == 1, PrePost == 1) %>% group_by(pid) %>%
  summarise(ESI = mean(ESI, na.rm = TRUE), .groups = "drop")
d <- ev1 %>% inner_join(phe %>% filter(visitnum == 1), by = "pid") %>%
  mutate(gender = factor(gender), race = factor(race), SmokCigNow = factor(SmokCigNow),
         afl = FEV1_FVC_post < 0.70, emph = CT_Visual_Emph_Severity >= 1,
         wall = CT_Visual_Wall_Thickening == 2, dysp = MMRCDyspneaScor >= 2,
         qol = SGRQ_scoreTotal >= 25, cb = Chronic_Bronchitis == 1) %>%
  filter(!is.na(afl), !is.na(emph), !is.na(wall), !is.na(dysp), !is.na(qol), !is.na(cb), !is.na(ESI))
stopifnot(nrow(d) == 9402L)
d$om <- d$dysp + d$qol + d$cb
d$nb <- d$emph + d$wall + d$om
O <- c("noCOPD", "AFL-only", "COPD-minor", "COPD-major")

label <- function(df, minor, aflo) factor(
  ifelse(df$afl & !aflo, "COPD-major", ifelse(df$afl & aflo, "AFL-only",
  ifelse(!df$afl & minor, "COPD-minor", "noCOPD"))), levels = O)
s2 <- function(df) label(df, df$nb >= 3, df$nb == 0)                       # MD-COPD with CT
s3 <- function(df, k) label(df, df$om >= k, df$om == 0)                    # no CT
s4 <- function(df, k, tl, th) { s <- ifelse(df$ESI >= th, 2, ifelse(df$ESI >= tl, 1, 0))
  label(df, (s + df$om) >= k, (s + df$om) == 0) }                          # ESI

macroF1 <- function(ref, est) mean(vapply(O, function(g) {
  tp <- sum(ref == g & est == g); if (tp == 0) return(0)
  2 * tp / (sum(est == g) + sum(ref == g)) }, numeric(1)))

KS  <- 1:3
TL  <- seq(0.50, 4.00, by = 0.25)
TH  <- seq(1.00, 8.00, by = 0.50)
G4  <- do.call(rbind, lapply(2:4, function(k) {
  g <- expand.grid(t_low = TL, t_high = TH); g <- g[g$t_high >= g$t_low, ]; cbind(k = k, g) }))

fit3 <- function(df) { r <- s2(df); KS[which.max(vapply(KS, function(k) macroF1(r, s3(df, k)), numeric(1)))] }
fit4 <- function(df) { r <- s2(df)
  i <- which.max(vapply(seq_len(nrow(G4)), function(j)
    macroF1(r, s4(df, G4$k[j], G4$t_low[j], G4$t_high[j])), numeric(1))); G4[i, ] }

cat("################ PART 1: fitting schemas 3 and 4 to approximate schema 2 ################\n\n")
ref <- s2(d)
k3 <- fit3(d); p4 <- fit4(d)
cat(sprintf("schema 3 fitted: COPD-minor if >= %d of 3 symptom criteria; macro-F1 %.4f\n",
            k3, macroF1(ref, s3(d, k3))))
cat(sprintf("schema 4 fitted: COPD-minor if >= %d; ESI thresholds %.2f / %.2f; macro-F1 %.4f\n",
            p4$k, p4$t_low, p4$t_high, macroF1(ref, s4(d, p4$k, p4$t_low, p4$t_high))))
cat(sprintf("  (v15 draft rule, k=3 at 1.00 / 2.50, scores %.4f)\n\n",
            macroF1(ref, s4(d, 3, 1.00, 2.50))))

# What the rejected objectives actually select. This is a Results finding, not
# a methods choice, so it is emitted as an artifact rather than asserted in
# prose: kappa and mean per-category sensitivity fail in OPPOSITE directions,
# and describing them as failing the same way would be wrong.
mean_recall <- function(est) mean(vapply(O, function(g) mean(est[ref == g] == g), numeric(1)))
kappa_full  <- function(est) { t <- table(ref, est); n <- sum(t)
  po <- sum(diag(t)) / n; pe <- sum(rowSums(t) * colSums(t)) / n^2; (po - pe) / (1 - pe) }
obj_rows <- list()
for (nm in c("kappa", "mean_sensitivity", "macro_F1")) {
  scorer <- switch(nm, kappa = kappa_full, mean_sensitivity = mean_recall, macro_F1 = function(e) macroF1(ref, e))
  v <- vapply(seq_len(nrow(G4)), function(j)
    scorer(s4(d, G4$k[j], G4$t_low[j], G4$t_high[j])), numeric(1))
  b <- G4[which.max(v), ]
  est <- s4(d, b$k, b$t_low, b$t_high)
  obj_rows[[length(obj_rows) + 1]] <- data.frame(
    objective = nm, k = b$k, t_low = b$t_low, score = max(v),
    n_aflonly = sum(est == "AFL-only"), n_major = sum(est == "COPD-major"),
    stringsAsFactors = FALSE)
}
objsel <- do.call(rbind, obj_rows)
objsel$ref_aflonly <- sum(ref == "AFL-only")
objsel$ref_major   <- sum(ref == "COPD-major")
# The two rejected objectives must err in opposite directions, or the Results
# sentence describing them is wrong.
stopifnot(objsel$n_aflonly[objsel$objective == "kappa"] < objsel$ref_aflonly[1],
          objsel$n_aflonly[objsel$objective == "mean_sensitivity"] > objsel$ref_aflonly[1])
write.csv(objsel, file.path(OUT, "objective_selection.csv"), row.names = FALSE)

cat("--- repeated stratified cross-validation, thresholds refitted inside every training fold ---\n")
set.seed(CV_SEED); rows <- list()
for (rep in seq_len(CV_REPEATS)) {
  fold <- integer(nrow(d))
  for (lv in O) { ix <- which(ref == lv); fold[ix] <- sample(rep_len(seq_len(CV_FOLDS), length(ix))) }
  for (kf in seq_len(CV_FOLDS)) {
    tr <- d[fold != kf, ]; te <- d[fold == kf, ]; rt <- s2(te)
    a <- fit3(tr); b <- fit4(tr)
    rows[[length(rows) + 1]] <- data.frame(rep = rep, fold = kf,
      k3 = a, f3 = macroF1(rt, s3(te, a)),
      k4 = b$k, tl = b$t_low, th = b$t_high, f4 = macroF1(rt, s4(te, b$k, b$t_low, b$t_high)),
      f_draft = macroF1(rt, s4(te, 3, 1.00, 2.50)))
  }
}
cv <- do.call(rbind, rows); write.csv(cv, file.path(OUT, "cv_schema_fits.csv"), row.names = FALSE)
dd <- cv$f4 - cv$f3
cat(sprintf("  held-out macro-F1: schema 3 %.4f | schema 4 %.4f | v15 draft %.4f\n",
            mean(cv$f3), mean(cv$f4), mean(cv$f_draft)))
cat(sprintf("  schema 4 minus schema 3: %+.4f (%+.4f to %+.4f across folds)\n",
            mean(dd), quantile(dd, .025), quantile(dd, .975)))
write.csv(data.frame(
  schema = c("S3", "S4", "S4_v15draft"),
  k = c(k3, p4$k, 3), t_low = c(NA, p4$t_low, 1.00), t_high = c(NA, p4$t_high, 2.50),
  macroF1_insample = c(macroF1(ref, s3(d, k3)),
                       macroF1(ref, s4(d, p4$k, p4$t_low, p4$t_high)),
                       macroF1(ref, s4(d, 3, 1.00, 2.50))),
  macroF1_heldout = c(mean(cv$f3), mean(cv$f4), mean(cv$f_draft)),
  stringsAsFactors = FALSE), file.path(OUT, "schema_fit.csv"), row.names = FALSE)
write.csv(data.frame(diff_mean = mean(dd), diff_lo = unname(quantile(dd, .025)),
                     diff_hi = unname(quantile(dd, .975)), n_folds = nrow(cv)),
          file.path(OUT, "schema_fit_cv_diff.csv"), row.names = FALSE)
writeLines(c(sprintf("n_cohort=%d", nrow(d)),
             sprintf("n_afl=%d", sum(d$afl)),
             sprintf("n_noafl=%d", sum(!d$afl))),
           file.path(OUT, "cohort.txt"))

cat(sprintf("  parameters selected: k3 %s | k4 %s | T_low %s | T_high %s\n\n",
            paste(unique(cv$k3), collapse = "/"), paste(unique(cv$k4), collapse = "/"),
            paste(names(sort(table(cv$tl), decreasing = TRUE))[1:2], collapse = "/"),
            paste(names(sort(table(cv$th), decreasing = TRUE))[1:2], collapse = "/")))

d$S1 <- factor(ifelse(d$afl, "COPD", "noCOPD"), levels = c("noCOPD", "COPD"))
d$S2 <- ref
d$S3 <- s3(d, k3)
d$S4 <- s4(d, p4$k, p4$t_low, p4$t_high)
saveRDS(d[, c("pid", "S1", "S2", "S3", "S4")], file.path(OUT, "schema_labels.rds"))

# Reclassification counts the Results quotes directly, and the share of
# COPD-major that qualifies only through a CT finding, which is the reason a
# CT-free schema can lose that category at all.
reclass <- do.call(rbind, lapply(c("S3", "S4"), function(s) data.frame(
  schema = s,
  major_to_aflonly = sum(d$S2 == "COPD-major" & d[[s]] == "AFL-only"),
  minor_to_nocopd  = sum(d$S2 == "COPD-minor" & d[[s]] == "noCOPD"),
  nocopd_to_minor  = sum(d$S2 == "noCOPD"     & d[[s]] == "COPD-minor"),
  aflonly_kept     = sum(d$S2 == "AFL-only"   & d[[s]] == "AFL-only"),
  concordant       = sum(d$S2 == d[[s]]), stringsAsFactors = FALSE)))
n_major   <- sum(d$S2 == "COPD-major")
ct_only   <- sum(d$S2 == "COPD-major" & d$om == 0)   # no symptom criterion at all
reclass$n_major <- n_major
reclass$ct_only_major <- ct_only
reclass$ct_only_pct <- 100 * ct_only / n_major
write.csv(reclass, file.path(OUT, "reclassification.csv"), row.names = FALSE)

# Full cross-classification of each CT-free schema against the reference, long
# form so the supplement table can be built without recomputing anything.
xtab <- do.call(rbind, lapply(c("S3", "S4"), function(s) {
  tb <- table(factor(d[[s]], levels = O), factor(d$S2, levels = O))
  do.call(rbind, lapply(O, function(rw) data.frame(
    schema = s, row_cat = rw, col_cat = O,
    n = as.integer(tb[rw, O]), stringsAsFactors = FALSE)))
}))
stopifnot(sum(xtab$n) == 2 * nrow(d))
write.csv(xtab, file.path(OUT, "crossclass.csv"), row.names = FALSE)

cat("################ PART 2: how each schema labels the same 9,402 people ################\n\n")
NAMES <- c(S1 = "1  Fixed ratio (FEV1/FVC < 0.70)",
           S2 = "2  MD-COPD with CT  [reference]",
           S3 = "3  MD-COPD without CT",
           S4 = "4  MD-COPD with ESI")
lab_rows <- list()
for (s in c("S1", "S2", "S3", "S4")) {
  cat(sprintf("%-34s", NAMES[[s]])); print(table(d[[s]]))
  tb <- table(d[[s]])
  for (g in names(tb)) lab_rows[[length(lab_rows) + 1]] <-
    data.frame(schema = s, category = g, n = as.integer(tb[[g]]), stringsAsFactors = FALSE)
}
write.csv(do.call(rbind, lab_rows), file.path(OUT, "schema_labels.csv"), row.names = FALSE)

cat("\n################ PART 3: risk within each schema's own categories ################\n")
COV <- "age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI"
mort <- d %>% inner_join(vs %>% dplyr::select(pid, vital_status, days_followed), by = "pid") %>%
  left_join(cod %>% dplyr::select(pid, UCD_Resp), by = "pid") %>%
  mutate(ev_resp = ifelse(vital_status == 1 & !is.na(UCD_Resp) & UCD_Resp == 1, 1, 0),
         py = days_followed / 365.25) %>%
  filter(complete.cases(age_visit, gender, race, SmokCigNow, ATS_PackYears, BMI))
pr <- phe %>% filter(visitnum == 1) %>%
  transmute(pid, prior_exac = suppressWarnings(as.numeric(Exacerbation_Frequency))) %>%
  distinct(pid, .keep_all = TRUE)
exa <- d %>% inner_join(ex %>% dplyr::select(pid, Total_Exacerbations, Years_Followed), by = "pid") %>%
  left_join(pr, by = "pid") %>%
  filter(!is.na(Total_Exacerbations), Years_Followed > 0, !is.na(prior_exac),
         complete.cases(age_visit, gender, race, SmokCigNow, ATS_PackYears, BMI))
risk_rows <- list(); disc_rows <- list()
for (s in c("S1", "S2", "S3", "S4")) {
  cat(sprintf("\n=== %s ===\n", NAMES[[s]]))
  m1 <- coxph(as.formula(sprintf("Surv(py, vital_status) ~ %s + %s", s, COV)), data = mort)
  m2 <- coxph(as.formula(sprintf("Surv(py, ev_resp) ~ %s + %s", s, COV)), data = mort)
  n1 <- glm.nb(as.formula(paste("Total_Exacerbations ~", s, "+", COV,
       "+ prior_exac + offset(log(Years_Followed))")), data = exa)
  cm <- summary(m1)$conf.int; cr <- summary(m2)$conf.int; ce <- summary(n1)$coef
  cat(sprintf("  %-12s %6s %7s %22s %24s %22s\n", "category", "n", "deaths",
              "all-cause HR", "resp HR", "exac IRR"))
  for (g in levels(d[[s]])) {
    r <- paste0(s, g); ix <- mort[[s]] == g
    f <- function(M) if (r %in% rownames(M)) sprintf("%.2f (%.2f-%.2f)", M[r,1], M[r,3], M[r,4]) else "reference"
    fe <- if (r %in% rownames(ce)) sprintf("%.2f (%.2f-%.2f)", exp(ce[r,1]),
            exp(ce[r,1]-1.96*ce[r,2]), exp(ce[r,1]+1.96*ce[r,2])) else "reference"
    cat(sprintf("  %-12s %6d %7d %22s %24s %22s\n", g, sum(ix), sum(mort$vital_status[ix]), f(cm), f(cr), fe))
  }
  for (g in levels(d[[s]])) {
    r <- paste0(s, g); ix <- mort[[s]] == g
    gv <- function(M, j) if (r %in% rownames(M)) M[r, j] else NA_real_
    risk_rows[[length(risk_rows) + 1]] <- data.frame(
      schema = s, category = g,
      n_mort = sum(ix), n_exac = sum(exa[[s]] == g),
      n_cohort = sum(d[[s]] == g), deaths = sum(mort$vital_status[ix]),
      all_HR = gv(cm, 1), all_LCI = gv(cm, 3), all_UCI = gv(cm, 4),
      resp_HR = gv(cr, 1), resp_LCI = gv(cr, 3), resp_UCI = gv(cr, 4),
      exac_IRR = if (r %in% rownames(ce)) exp(ce[r, 1]) else NA_real_,
      exac_LCI = if (r %in% rownames(ce)) exp(ce[r, 1] - 1.96 * ce[r, 2]) else NA_real_,
      exac_UCI = if (r %in% rownames(ce)) exp(ce[r, 1] + 1.96 * ce[r, 2]) else NA_real_,
      stringsAsFactors = FALSE)
  }
  disc_rows[[length(disc_rows) + 1]] <- data.frame(
    schema = s, c_allcause = summary(m1)$concordance[1],
    c_resp = summary(m2)$concordance[1], exac_AIC = AIC(n1), stringsAsFactors = FALSE)
  cat(sprintf("  C-index all-cause %.4f | respiratory %.4f | exacerbation AIC %.1f\n",
              summary(m1)$concordance[1], summary(m2)$concordance[1], AIC(n1)))
}
# ---------------------------------------------------------------------------
# Crude rate ratios, on the same scale as the adjusted estimates.
#
# An adjusted hazard ratio is what the classification contributes beyond the
# covariates; the crude rate ratio is what participants in that category
# actually experienced. Both belong in the table, and putting them on one
# scale, each against its own schema's noCOPD reference, is what makes the
# effect of adjustment readable rather than a change of units.
#
# Interval convention: a resample in which a category contributes no events is
# a legitimate draw with a rate ratio of zero, not a failed one. Dropping such
# draws truncates the interval from below and can push a lower bound above 1 on
# the strength of a single event. Only a resample in which the REFERENCE has no
# events leaves the ratio undefined, and only those are cut.
CRUDE_B <- 1000L
set.seed(CV_SEED)

crude_ratio <- function(sch, ev, py, dat) {
  g   <- dat[[sch]]
  num <- rowsum(dat[[ev]], g, reorder = FALSE)
  den <- rowsum(dat[[py]], g, reorder = FALSE)
  r   <- setNames(as.vector(num) / as.vector(den), rownames(num))
  ref <- r[["noCOPD"]]
  if (!is.finite(ref) || ref <= 0) return(setNames(rep(NA_real_, length(r)), names(r)))
  r / ref
}

crude_rows <- list()
for (spec in list(list("all",  "vital_status",        "py",             mort),
                  list("resp", "ev_resp",             "py",             mort),
                  list("exac", "Total_Exacerbations", "Years_Followed", exa))) {
  key <- spec[[1]]; ev <- spec[[2]]; py <- spec[[3]]; dat <- spec[[4]]
  boot <- vector("list", CRUDE_B)
  for (b in seq_len(CRUDE_B)) {
    idx <- sample.int(nrow(dat), nrow(dat), replace = TRUE)
    dd  <- dat[idx, , drop = FALSE]
    boot[[b]] <- lapply(c("S1","S2","S3","S4"), function(s) crude_ratio(s, ev, py, dd))
  }
  for (si in seq_along(c("S1","S2","S3","S4"))) {
    s   <- c("S1","S2","S3","S4")[si]
    est <- crude_ratio(s, ev, py, dat)
    for (g in names(est)) {
      v <- vapply(boot, function(bb) { z <- bb[[si]]
        if (g %in% names(z)) z[[g]] else NA_real_ }, numeric(1))
      v <- v[is.finite(v)]
      crude_rows[[length(crude_rows) + 1]] <- data.frame(
        schema = s, category = g, outcome = key, rr = unname(est[[g]]),
        lo = if (length(v) > 1) unname(quantile(v, .025)) else NA_real_,
        hi = if (length(v) > 1) unname(quantile(v, .975)) else NA_real_,
        B_eff = sum(v > 0), stringsAsFactors = FALSE)
    }
  }
}
crude <- do.call(rbind, crude_rows)
# The reference category's ratio is 1 by construction; drift means the
# numerator and denominator were computed off different rows.
stopifnot(all(abs(crude$rr[crude$category == "noCOPD"] - 1) < 1e-12))
write.csv(crude, file.path(OUT, "schema_crude.csv"), row.names = FALSE)

.rk <- do.call(rbind, risk_rows)
# Mortality and exacerbation models are fitted on different participant sets,
# so a table reporting one n per category for all three outcomes overstates the
# exacerbation denominators. Guard the distinction rather than trusting it.
stopifnot(sum(.rk$n_exac[.rk$schema == "S2"]) == nrow(exa),
          sum(.rk$n_mort[.rk$schema == "S2"]) == nrow(mort),
          sum(.rk$n_cohort[.rk$schema == "S2"]) == nrow(d))
write.csv(.rk, file.path(OUT, "schema_risk.csv"), row.names = FALSE)
write.csv(do.call(rbind, disc_rows), file.path(OUT, "schema_discrimination.csv"), row.names = FALSE)
cat(sprintf("\nwrote %s\n", normalizePath(OUT)))
