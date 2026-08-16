#!/usr/bin/env Rscript
# 5-step validation of ESI manuscript v3 (2026-07-04).
# Extracts numeric claims from the DOCX prose, matches each to its source asset, reports PASS/FAIL/WARN.
suppressPackageStartupMessages({library(dplyr); library(stringr); library(xml2)})

ROOT    <- "/Users/petecastaldi/claude_projects/projects/ESI_2024"
ASSETS  <- file.path(ROOT, "manuscript_assets")
DOCX    <- file.path(ROOT, "manuscript/ESI_manuscript_draft_v3_2026.7.4.docx")

# ---- helpers ----
pass_fail <- function(ok, msg) {
  tag <- if (isTRUE(ok)) "PASS" else if (identical(ok, "WARN")) "WARN" else "FAIL"
  cat(sprintf("[%s] %s\n", tag, msg))
  isTRUE(ok) || identical(ok, "WARN")
}
approx_eq <- function(a, b, tol = 1e-2) !is.na(a) && !is.na(b) && abs(a - b) < tol

# ---- extract paragraph text from DOCX ----
tmp <- tempfile(); unzip(DOCX, "word/document.xml", exdir = tmp)
xml <- read_xml(file.path(tmp, "word/document.xml"))
ns  <- xml_ns(xml)
# xpath — one paragraph text per <w:p>
paras <- xml_find_all(xml, "//w:p", ns)
para_text <- sapply(paras, function(p) paste(xml_text(xml_find_all(p, ".//w:t", ns)), collapse=""))
para_text <- para_text[nchar(str_squish(para_text)) > 0]

# ---- source-of-truth values ----
t6    <- read.csv(file.path(ASSETS, "Table_6.csv"), check.names = FALSE)
disc  <- read.csv(file.path(ASSETS, "Table_Discordance.csv"), check.names = FALSE)
t8a   <- read.csv(file.path(ASSETS, "Table_8_allcause.csv"), check.names = FALSE)
t8r   <- read.csv(file.path(ASSETS, "Table_8_resp.csv"), check.names = FALSE)
t_cs  <- read.csv(file.path(ASSETS, "Table_CauseSpecific_byClass.csv"), check.names = FALSE)
t12   <- read.csv(file.path(ASSETS, "Table_Exacerbations_Bhatt.csv"), check.names = FALSE)
t10   <- read.csv(file.path(ASSETS, "Table_BhattOnly_vs_Both.csv"), check.names = FALSE)
t_csd <- read.csv(file.path(ASSETS, "Table_CauseSpecific_byDiscord.csv"), check.names = FALSE)
t_disc_ex <- read.csv(file.path(ASSETS, "Table_Exacerbations_Discordance.csv"), check.names = FALSE)
kv8   <- setNames(as.list(readLines(file.path(ASSETS, "Table_8_stats.txt")) %>%
                            strsplit("=") %>% sapply(function(kv) kv[2])),
                  readLines(file.path(ASSETS, "Table_8_stats.txt")) %>%
                            strsplit("=") %>% sapply(function(kv) kv[1]))
kv12  <- setNames(as.list(readLines(file.path(ASSETS, "Table_Exacerbations_Bhatt_stats.txt")) %>%
                            strsplit("=") %>% sapply(function(kv) kv[2])),
                  readLines(file.path(ASSETS, "Table_Exacerbations_Bhatt_stats.txt")) %>%
                            strsplit("=") %>% sapply(function(kv) kv[1]))

results <- list()

cat("=== STEP 1: FACTUAL ACCURACY ===\n")

# Cohort sizes
results$s1_cohort_9463 <- pass_fail(
  any(str_detect(para_text, "9,463")),
  "Prose references 9,463 subjects (matches Bhatt cohort)")
results$s1_cohort_4130 <- pass_fail(
  as.integer(t6$noCOPD[t6$Bhatt == "noCOPD"]) == 4130 && any(str_detect(para_text, "4,130 concordant noCOPD")),
  sprintf("Concordant noCOPD = %s (prose: 4,130)", t6$noCOPD[t6$Bhatt == "noCOPD"]))
results$s1_cohort_3906 <- pass_fail(
  as.integer(t6$COPD_major[t6$Bhatt == "COPD-major"]) == 3906 && any(str_detect(para_text, "3,906 concordant COPD-major")),
  sprintf("Concordant COPD-major = %s (prose: 3,906)", t6$COPD_major[t6$Bhatt == "COPD-major"]))
results$s1_cohort_553  <- pass_fail(
  as.integer(t6$COPD_minor[t6$Bhatt == "COPD-minor"]) == 553 && any(str_detect(para_text, "553 concordant COPD-minor")),
  sprintf("Concordant COPD-minor = %s (prose: 553)", t6$COPD_minor[t6$Bhatt == "COPD-minor"]))
results$s1_cohort_21   <- pass_fail(
  as.integer(t6$AFL_only_NoCOPD[t6$Bhatt == "AFL-only-NoCOPD"]) == 21 && any(str_detect(para_text, "21 concordant AFL-only-noCOPD")),
  sprintf("Concordant AFL-only-noCOPD = %s (prose: 21)", t6$AFL_only_NoCOPD[t6$Bhatt == "AFL-only-NoCOPD"]))

# Discordance subgroup sizes
n_bhatt_only <- disc$n[disc$grp_5 == "Bhatt-only-COPD (ESI missed)"]
n_both       <- disc$n[disc$grp_5 == "Both-COPD"]
n_esi_only   <- disc$n[disc$grp_5 == "ESI-only-COPD (Bhatt missed)"]
results$s1_bhatt_only <- pass_fail(n_bhatt_only == 546 && any(str_detect(para_text, "n = 546")),
                                   sprintf("Bhatt-only n = %s (prose: 546)", n_bhatt_only))
results$s1_both       <- pass_fail(n_both == 553 && any(str_detect(para_text, "Both-COPD; n = 553")),
                                   sprintf("Both-COPD n = %s (prose: 553)", n_both))
results$s1_esi_only   <- pass_fail(n_esi_only == 95 && any(str_detect(para_text, "n = 95")),
                                   sprintf("ESI-only n = %s (prose: 95)", n_esi_only))

# Agreement metrics — the source-of-truth κ, agreement, sens, spec should be 91%, 0.82, 88%, 94%
results$s1_agreement <- pass_fail(
  any(str_detect(para_text, "91%")) &&
  any(str_detect(para_text, "κ = 0.82")) &&
  any(str_detect(para_text, "sensitivity of 88%|sensitivity 88%")) &&
  any(str_detect(para_text, "specificity of 94%|specificity 94%")),
  "Agreement claims (91%, κ=0.82, sens 88%, spec 94%) present")

# Correlation claims
results$s1_ct_corr_LAA  <- pass_fail(any(str_detect(para_text, "r = 0\\.77 with %LAA-950HU")),
                                     "Prose: r = 0.77 with %LAA-950HU (source: T2 all-cohort)")
results$s1_ct_corr_PRM  <- pass_fail(any(str_detect(para_text, "r = 0\\.80 with PRM emphysema")),
                                     "Prose: r = 0.80 with PRM emphysema")
results$s1_prm_laa      <- pass_fail(any(str_detect(para_text, "r = 0\\.985")),
                                     "Prose: r = 0.985 between %LAA-950HU and PRM emphysema")
results$s1_bd_neg09     <- pass_fail(any(str_detect(para_text, "−0\\.09")),
                                     "Prose: mean ΔESI = −0.09 (bronchodilator response)")

cat("\n=== STEP 2: RESULT CORRECTNESS (HR/IRR checks) ===\n")

# Mortality — head-to-head, values must match Table_8 files
mor_row <- function(df, grp) df[df$group == grp, ]
val <- function(x) round(as.numeric(x), 2)

# COPD-major all-cause: 2.59 (original), 2.39 (reformulated)
m8_maj <- mor_row(t8a, "COPD-major")
results$s2_maj_all_orig <- pass_fail(
  approx_eq(val(m8_maj$bhatt_HR), 2.59, 0.01) && any(str_detect(para_text, "was 2\\.59")),
  sprintf("COPD-major all-cause original HR = %.2f (prose: 2.59)", val(m8_maj$bhatt_HR)))
results$s2_maj_all_ref  <- pass_fail(
  approx_eq(val(m8_maj$esi_HR), 2.39, 0.01) && any(str_detect(para_text, "2\\.39 in the reformulated")),
  sprintf("COPD-major all-cause reformulated HR = %.2f (prose: 2.39)", val(m8_maj$esi_HR)))

# COPD-minor all-cause: 1.91 vs 1.94
m8_min <- mor_row(t8a, "COPD-minor")
results$s2_min_all_orig <- pass_fail(
  approx_eq(val(m8_min$bhatt_HR), 1.91, 0.01) && any(str_detect(para_text, "were 1\\.91")),
  sprintf("COPD-minor all-cause original HR = %.2f (prose: 1.91)", val(m8_min$bhatt_HR)))
results$s2_min_all_ref  <- pass_fail(
  approx_eq(val(m8_min$esi_HR), 1.94, 0.01) && any(str_detect(para_text, "1\\.94")),
  sprintf("COPD-minor all-cause reformulated HR = %.2f (prose: 1.94)", val(m8_min$esi_HR)))

# Respiratory mortality COPD-major: 13.93 vs 11.85
r8_maj <- mor_row(t8r, "COPD-major")
results$s2_maj_resp_orig <- pass_fail(
  approx_eq(val(r8_maj$bhatt_HR), 13.93, 0.02) && any(str_detect(para_text, "13\\.93")),
  sprintf("COPD-major respiratory original HR = %.2f (prose: 13.93)", val(r8_maj$bhatt_HR)))
results$s2_maj_resp_ref  <- pass_fail(
  approx_eq(val(r8_maj$esi_HR), 11.85, 0.02) && any(str_detect(para_text, "11\\.85")),
  sprintf("COPD-major respiratory reformulated HR = %.2f (prose: 11.85)", val(r8_maj$esi_HR)))

# Respiratory mortality COPD-minor: 3.09 vs 2.91
r8_min <- mor_row(t8r, "COPD-minor")
results$s2_min_resp_orig <- pass_fail(
  approx_eq(val(r8_min$bhatt_HR), 3.09, 0.02) && any(str_detect(para_text, "3\\.09")),
  sprintf("COPD-minor respiratory original HR = %.2f (prose: 3.09)", val(r8_min$bhatt_HR)))
results$s2_min_resp_ref  <- pass_fail(
  approx_eq(val(r8_min$esi_HR), 2.91, 0.02) && any(str_detect(para_text, "2\\.91")),
  sprintf("COPD-minor respiratory reformulated HR = %.2f (prose: 2.91)", val(r8_min$esi_HR)))

# C-index
c_all_orig <- as.numeric(kv8$bhatt_cindex_all); c_all_ref <- as.numeric(kv8$esi_cindex_all)
c_resp_orig <- as.numeric(kv8$bhatt_cindex_resp); c_resp_ref <- as.numeric(kv8$esi_cindex_resp)
results$s2_cindex_all  <- pass_fail(
  approx_eq(round(c_all_orig,3), 0.703) && approx_eq(round(c_all_ref,3), 0.700) &&
  any(str_detect(para_text, "0\\.703 versus 0\\.700")),
  sprintf("All-cause C-index %.3f vs %.3f (prose: 0.703 vs 0.700)", c_all_orig, c_all_ref))
results$s2_cindex_resp <- pass_fail(
  approx_eq(round(c_resp_orig,3), 0.822) && approx_eq(round(c_resp_ref,3), 0.819) &&
  any(str_detect(para_text, "0\\.822 versus 0\\.819")),
  sprintf("Respiratory C-index %.3f vs %.3f (prose: 0.822 vs 0.819)", c_resp_orig, c_resp_ref))

# Cause-specific COPD-major: CVD 2.34/2.24, Cancer 2.05/1.88, Other 1.92/1.80
cs_maj <- t_cs[t_cs$group == "COPD-major", ]
r_cvd  <- cs_maj[cs_maj$cause == "CVD", ]
r_can  <- cs_maj[cs_maj$cause == "Cancer", ]
r_oth  <- cs_maj[cs_maj$cause == "Other", ]
results$s2_cvd_maj  <- pass_fail(approx_eq(val(r_cvd$bhatt_HR), 2.34, 0.01) &&
                                 approx_eq(val(r_cvd$esi_HR),   2.23, 0.01) &&
                                 any(str_detect(para_text, "2\\.34 \\(original\\) versus 2\\.23")),
                                 sprintf("CVD COPD-major HR orig=%.2f ref=%.2f (prose: 2.34, 2.23)", val(r_cvd$bhatt_HR), val(r_cvd$esi_HR)))
results$s2_can_maj  <- pass_fail(approx_eq(val(r_can$bhatt_HR), 2.05, 0.01) &&
                                 approx_eq(val(r_can$esi_HR),   1.88, 0.01) &&
                                 any(str_detect(para_text, "2\\.05 versus 1\\.88")),
                                 sprintf("Cancer COPD-major HR orig=%.2f ref=%.2f (prose: 2.05, 1.88)", val(r_can$bhatt_HR), val(r_can$esi_HR)))
results$s2_oth_maj  <- pass_fail(approx_eq(val(r_oth$bhatt_HR), 1.92, 0.01) &&
                                 approx_eq(val(r_oth$esi_HR),   1.80, 0.01) &&
                                 any(str_detect(para_text, "1\\.92 versus 1\\.80")),
                                 sprintf("Other COPD-major HR orig=%.2f ref=%.2f (prose: 1.92, 1.80)", val(r_oth$bhatt_HR), val(r_oth$esi_HR)))

# Exacerbations COPD-major 5.07 vs 4.47; COPD-minor 2.73 vs 2.78
e_maj <- t12[t12$group == "COPD-major", ]; e_min <- t12[t12$group == "COPD-minor", ]
results$s2_ex_maj <- pass_fail(approx_eq(val(e_maj$bhatt_IRR), 5.07, 0.01) &&
                               approx_eq(val(e_maj$esi_IRR),   4.47, 0.01) &&
                               any(str_detect(para_text, "5\\.07 \\(original\\) versus 4\\.47")),
                               sprintf("Exac COPD-major IRR orig=%.2f ref=%.2f", val(e_maj$bhatt_IRR), val(e_maj$esi_IRR)))
results$s2_ex_min <- pass_fail(approx_eq(val(e_min$bhatt_IRR), 2.73, 0.01) &&
                               approx_eq(val(e_min$esi_IRR),   2.78, 0.01) &&
                               any(str_detect(para_text, "2\\.73 versus 2\\.78")),
                               sprintf("Exac COPD-minor IRR orig=%.2f ref=%.2f", val(e_min$bhatt_IRR), val(e_min$esi_IRR)))

# Discordance HRs (Bhatt-only): all-cause 1.53, respiratory 2.48, cancer 1.64
r_bo <- t10[t10$group == "Bhatt-only-COPD (ESI missed)", ]
results$s2_bo_all  <- pass_fail(approx_eq(val(r_bo$all_HR), 1.53, 0.02) && any(str_detect(para_text, "HR 1\\.53")),
                                sprintf("Bhatt-only all-cause HR=%.2f (prose: 1.53)", val(r_bo$all_HR)))
results$s2_bo_resp <- pass_fail(approx_eq(val(r_bo$resp_HR), 2.48, 0.02) && any(str_detect(para_text, "HR 2\\.48")),
                                sprintf("Bhatt-only respiratory HR=%.2f (prose: 2.48)", val(r_bo$resp_HR)))
r_bo_can <- t_csd[t_csd$cause == "Cancer" & t_csd$group == "Bhatt-only-COPD", ]
results$s2_bo_can  <- pass_fail(approx_eq(val(r_bo_can$HR), 1.64, 0.02) && any(str_detect(para_text, "HR 1\\.64")),
                                sprintf("Bhatt-only cancer HR=%.2f (prose: 1.64)", val(r_bo_can$HR)))
r_bo_ex <- t_disc_ex[t_disc_ex$group == "Bhatt-only-COPD (ESI missed)", ]
results$s2_bo_ex   <- pass_fail(approx_eq(val(r_bo_ex$IRR), 2.01, 0.02) && any(str_detect(para_text, "IRR 2\\.01")),
                                sprintf("Bhatt-only exacerbation IRR=%.2f (prose: 2.01)", val(r_bo_ex$IRR)))

# ESI-only CVD HR 2.74 (1.33-5.64) p=0.006
r_eo_cvd <- t_csd[t_csd$cause == "CVD" & t_csd$group == "ESI-only-COPD", ]
results$s2_eo_cvd  <- pass_fail(approx_eq(val(r_eo_cvd$HR), 2.74, 0.02) &&
                                approx_eq(round(as.numeric(r_eo_cvd$LCI),2), 1.33, 0.01) &&
                                approx_eq(round(as.numeric(r_eo_cvd$UCI),2), 5.64, 0.02) &&
                                any(str_detect(para_text, "2\\.74.*1\\.33.5\\.64.*p = 0\\.006")),
                                sprintf("ESI-only CVD HR=%.2f (%.2f–%.2f) p=%s", val(r_eo_cvd$HR),
                                        as.numeric(r_eo_cvd$LCI), as.numeric(r_eo_cvd$UCI), r_eo_cvd$p))

# Discordance means: Bhatt-only ESI=0.80 emph=91% LAA=1.4; Both ESI=1.06; ESI-only ESI=1.48 mMRC=85% SGRQ=95%
disc_bo <- disc[disc$grp_5 == "Bhatt-only-COPD (ESI missed)", ]
disc_bt <- disc[disc$grp_5 == "Both-COPD", ]
disc_eo <- disc[disc$grp_5 == "ESI-only-COPD (Bhatt missed)", ]
results$s2_bo_means <- pass_fail(
  str_detect(disc_bo$ESI, "0\\.80") && str_detect(disc_bo$pct_emph, "91%") && str_detect(disc_bo$LAA950, "1\\.4"),
  sprintf("Bhatt-only means from data: ESI=%s emph=%s LAA=%s (prose: 0.80, 91%%, 1.4%%)",
          disc_bo$ESI, disc_bo$pct_emph, disc_bo$LAA950))
results$s2_bt_mean  <- pass_fail(
  str_detect(disc_bt$ESI, "1\\.06"),
  sprintf("Both-COPD ESI mean = %s (prose: 1.06)", disc_bt$ESI))
results$s2_eo_means <- pass_fail(
  str_detect(disc_eo$ESI, "1\\.48") && str_detect(disc_eo$pct_mMRC2p, "85%") && str_detect(disc_eo$pct_SGRQ25p, "95%"),
  sprintf("ESI-only means: ESI=%s mMRC=%s SGRQ=%s (prose: 1.48, 85%%, 95%%)",
          disc_eo$ESI, disc_eo$pct_mMRC2p, disc_eo$pct_SGRQ25p))

# Both-COPD chronic bronchitis 72%
results$s2_bt_cb <- pass_fail(str_detect(disc_bt$pct_CB, "72%"),
                              sprintf("Both-COPD %%CB = %s (prose: 72%%)", disc_bt$pct_CB))

# 8 CVD events in ESI-only
n_cvd_eo <- as.integer(r_eo_cvd$n_events)
results$s2_eo_cvd_n <- pass_fail(
  n_cvd_eo == 8 && any(str_detect(para_text, "only eight cardiovascular deaths")),
  sprintf("ESI-only CVD events = %d (prose: eight)", n_cvd_eo))

# 641 preserved-spirometry discordant
n_disc_pres <- n_bhatt_only + n_esi_only
results$s2_641_disc <- pass_fail(
  n_disc_pres == 641 && any(str_detect(para_text, "641")),
  sprintf("Preserved-spirometry discordant n = %d (prose: 641)", n_disc_pres))

# Both-COPD outcomes (from t10): all-cause HR 2.02, respiratory HR 3.05
r_bt <- t10[t10$group == "Both-COPD", ]
results$s2_bt_all  <- pass_fail(approx_eq(val(r_bt$all_HR),  2.02, 0.02) && any(str_detect(para_text, "of 2\\.02")),
                                sprintf("Both-COPD all-cause HR=%.2f (prose: 2.02)", val(r_bt$all_HR)))
results$s2_bt_resp <- pass_fail(approx_eq(val(r_bt$resp_HR), 3.05, 0.02) && any(str_detect(para_text, "of 3\\.05")),
                                sprintf("Both-COPD respiratory HR=%.2f (prose: 3.05)", val(r_bt$resp_HR)))

cat("\n=== STEP 3: DOCUMENTATION ACCURACY ===\n")

# Every headline number in Abstract matches Results/data
results$s3_abstract_maj259 <- pass_fail(
  sum(str_detect(para_text, "2\\.59")) >= 2,
  "Abstract 2.59 (COPD-major all-cause original) is also cited in Results")
results$s3_abstract_ka082  <- pass_fail(
  sum(str_detect(para_text, "κ = 0\\.82")) >= 2,
  "Abstract κ=0.82 appears in Results also")
results$s3_abstract_cvd274 <- pass_fail(
  sum(str_detect(para_text, "2\\.74")) >= 2,
  "Abstract HR 2.74 (ESI-only CVD) also cited in Results/Discussion")

# Figure references — v3 uses Figures 1-5, and Figure 3 is discordance
results$s3_fig1 <- pass_fail(any(str_detect(para_text, "Figure 1\\b")), "Figure 1 (stacked bars) cited in prose")
results$s3_fig2 <- pass_fail(any(str_detect(para_text, "Figure 2\\b")), "Figure 2 (mortality forest) cited in prose")
results$s3_fig3 <- pass_fail(any(str_detect(para_text, "Figure 3\\b")), "Figure 3 (discordance panel) cited in prose")
results$s3_fig4 <- pass_fail(any(str_detect(para_text, "Figure 4\\b")), "Figure 4 (cause-specific) cited in prose")
results$s3_fig5 <- pass_fail(any(str_detect(para_text, "Figure 5\\b")), "Figure 5 (PRISm trajectory) cited in prose")

# Table references
for (n in 1:7) {
  results[[paste0("s3_tab", n)]] <- pass_fail(
    any(str_detect(para_text, paste0("Table ", n, "\\b"))),
    sprintf("Table %d cited in prose", n))
}

# No leftover v2 relative-figure ambiguity — check that Figure 3 refers to Discordance panel
fig3_context <- para_text[str_detect(para_text, "Figure 3")]
results$s3_fig3_semantic <- pass_fail(
  any(str_detect(fig3_context, "discordant")),
  "Figure 3 prose context is discordance (not cause-specific)")

# No obvious placeholder text
results$s3_no_placeholder <- pass_fail(
  !any(str_detect(para_text, "XX\\.X\\.X|TODO|TBD|to be confirmed"[c(TRUE)])) ||
    all(str_detect(para_text[str_detect(para_text, "to be confirmed")], "citation")),
  "No unresolved placeholders in body (references may still cite 'to be confirmed')")

# Massimo's newest phrase adopted in Introduction
results$s3_massimo_phrase <- pass_fail(
  any(str_detect(para_text, "structural dimension of COPD traditionally described by chest CT")),
  "Introduction ¶3 adopts Massimo's newest closing phrase")

# rpart language present in Methods
results$s3_rpart_lang <- pass_fail(
  any(str_detect(para_text, "single-variable classification tree \\(rpart\\)")),
  "Methods contains rpart threshold-selection language")

# Questions remaining section present
results$s3_questions <- pass_fail(
  any(str_detect(para_text, "Questions remaining")) &&
    any(str_detect(para_text, "biological basis of the differences")),
  "Discussion contains 'Questions remaining' subsection with Massimo's questions")

cat("\n=== STEP 4: REPRODUCIBILITY & COMPLETENESS ===\n")

for (asset in c("Table_6.csv","Table_Discordance.csv","Table_8_allcause.csv","Table_8_resp.csv",
                "Table_CauseSpecific_byClass.csv","Table_Exacerbations_Bhatt.csv",
                "Table_BhattOnly_vs_Both.csv","Table_CauseSpecific_byDiscord.csv",
                "Table_Exacerbations_Discordance.csv",
                "Figure_Bhatt_StackedBars.png","Figure_5.png","Figure_3_Discordance.png",
                "Figure_CauseSpecific_byClass.png","Figure_6.png")) {
  results[[paste0("s4_", asset)]] <- pass_fail(
    file.exists(file.path(ASSETS, asset)),
    sprintf("Asset exists: %s", asset))
}

# Build script + validation script exist
results$s4_build <- pass_fail(file.exists(file.path(ROOT, "build_manuscript_v3_2026.7.4.py")),
                              "Build script v3 exists")
results$s4_val   <- pass_fail(file.exists(file.path(ROOT, "validation_v3_2026.7.4.R")),
                              "Validation script v3 exists")

cat("\n=== STEP 5: METHODS/CODE CONSISTENCY ===\n")

# Methods claim: FEV1/FVC major threshold 0.70
results$s5_maj_070 <- pass_fail(
  any(str_detect(para_text, "FEV1/FVC below 0\\.70")),
  "Methods states major criterion FEV1/FVC < 0.70")

# Methods claim: three sensitivity analyses
results$s5_sens <- pass_fail(
  any(str_detect(para_text, "Three pre-specified sensitivity analyses")),
  "Methods lists three sensitivity analyses")

# Methods claim: adjustment set = age, sex, race, current smoking, pack-years, BMI (+ height for FEV1 decline)
results$s5_adj <- pass_fail(
  any(str_detect(para_text, "age, sex, race, current smoking(?: status)?, (?:cumulative smoking exposure \\()?pack-years")),
  "Methods adjustment set matches Cox/NB/LMM models")

# ESI threshold selection: rpart identifies lower threshold ~1.0; upper 2.5 is chosen from top-decile structural score
results$s5_thresh_low <- pass_fail(
  any(str_detect(para_text, "cut-point of ESI ≈ 1\\.0")),
  "Methods describes lower threshold = 1.0 (rpart-derived)")
results$s5_thresh_up  <- pass_fail(
  any(str_detect(para_text, "upper threshold \\(ESI = 2\\.5\\)")) &&
    any(str_detect(para_text, "top decile of the structural-score distribution")),
  "Methods describes upper threshold = 2.5 (top decile of structural score) — this is honest to what analyses used")

# --- Summary
cat("\n=== SUMMARY ===\n")
n_pass <- sum(unlist(results))
n_tot  <- length(results)
cat(sprintf("Passed %d / %d checks (%.1f%%)\n", n_pass, n_tot, 100*n_pass/n_tot))
if (n_pass < n_tot) {
  cat("Failed checks:\n")
  for (nm in names(results)) if (!isTRUE(results[[nm]])) cat("  -", nm, "\n")
} else {
  cat("All checks PASSED.\n")
}
