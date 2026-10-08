# make_synthetic.R -- fake COPDGene-shaped inputs for testing recompute_ctfree.R.
#
#   Rscript make_synthetic.R <dir>
#
# Writes six files plus a config_paths.R into <dir>. Every value is random; no
# real data is read. Formats mimic the real files as far as the code shows them:
#   ESI   comma-separated, UTF-8 BOM before the header, trailing empty columns
#   PHE   tab-separated long file (visits 1-3), blank = missing
#   VS    comma-separated
#   COD   tab-separated
#   LFU   tab-separated
#   MDCOPD comma-separated (sid, MultiDim_COPD_Subtype, MultiDim_COPD_score, extra)
# This exercises the code paths only; it says nothing about the science.

args <- commandArgs(trailingOnly = TRUE)
DIR <- if (length(args)) args[1] else "synthetic_inputs"
dir.create(DIR, recursive = TRUE, showWarnings = FALSE)
set.seed(1)
n <- 3000
sid <- sprintf("SYN%05d", seq_len(n))

cohort <- sample(c("Smoker", "Never smoked", "ILD"), n, TRUE, c(.95, .03, .02))
excl   <- ifelse(cohort == "ILD", "ILD", "")
cohort[cohort == "ILD"] <- "Smoker"
age <- round(runif(n, 45, 80), 1)
gender <- sample(1:2, n, TRUE)
race <- sample(1:2, n, TRUE, c(.7, .3))
smk <- sample(0:1, n, TRUE)
pky <- round(rgamma(n, 4, 0.09), 1)
bmi <- round(rnorm(n, 28.5, 6), 1)
sev <- pmin(pmax(rnorm(n), -2), 3)                  # latent disease severity
ratio <- round(0.74 - 0.12 * sev + rnorm(n, 0, .05), 3)
ratio[sample(n, 40)] <- NA                           # unacceptable spirometry
fev1pp <- round(pmax(15, 92 - 18 * pmax(sev, 0) + rnorm(n, 0, 10)), 1)
gold <- ifelse(is.na(ratio), NA,
        ifelse(ratio < .7, ifelse(fev1pp >= 80, 1, ifelse(fev1pp >= 50, 2, ifelse(fev1pp >= 30, 3, 4))),
               ifelse(fev1pp < 80, -1, 0)))
emph <- pmin(5, pmax(0, round(1.2 + 1.3 * sev + rnorm(n, 0, 1))))
wall <- pmin(2, pmax(0, round(1 + 0.6 * sev + rnorm(n, 0, .6))))
emph[sample(n, 60)] <- NA; wall[sample(n, 60)] <- NA
mmrc <- pmin(4, pmax(0, round(1 + sev + rnorm(n))))
sgrq <- round(pmin(100, pmax(0, 25 + 15 * sev + rnorm(n, 0, 15))), 1)
cb   <- rbinom(n, 1, plogis(-1.5 + .5 * sev))
cad  <- rbinom(n, 1, .07); chf <- rbinom(n, 1, .03)
exf  <- rpois(n, exp(-1 + .5 * sev)); exf[sample(n, 30)] <- NA
height <- round(rnorm(n, 170, 10), 1)
fev1 <- round(pmax(0.4, 3.2 - 0.6 * sev + rnorm(n, 0, .3)), 3)

phe1 <- data.frame(sid, cohort, ccenter = "X", visitnum = 1, ExclusionaryDisease = excl,
                   FEV1_FVC_post = ratio, CT_Visual_Emph_Severity = emph,
                   CT_Visual_Wall_Thickening = wall, MMRCDyspneaScor = mmrc,
                   SGRQ_scoreTotal = sgrq, Chronic_Bronchitis = cb, gender, race,
                   SmokCigNow = smk, finalgold_visit = gold, age_visit = age,
                   ATS_PackYears = pky, BMI = bmi, FEV1pp_utah = fev1pp,
                   CoronaryArtery = cad, CongestHeartFail = chf,
                   Exacerbation_Frequency = exf, FEV1_post = fev1,
                   years_from_baseline = 0, Height_CM = height, filler1 = "a", filler2 = 1.5)
mk_visit <- function(v, keep, yrs) {
  z <- phe1[keep, ]
  z$visitnum <- v; z$years_from_baseline <- round(yrs[keep], 2)
  z$age_visit <- z$age_visit + z$years_from_baseline
  z$FEV1_post <- round(z$FEV1_post - 0.04 * z$years_from_baseline + rnorm(nrow(z), 0, .1), 3)
  z$CT_Visual_Emph_Severity <- NA; z$CT_Visual_Wall_Thickening <- NA
  z$finalgold_visit <- NA; z$ExclusionaryDisease <- ""
  z
}
phe <- rbind(phe1, mk_visit(2, runif(n) < .6, runif(n, 4.5, 6.5)),
                   mk_visit(3, runif(n) < .4, runif(n, 9, 11)))
phe$FEV1_post[sample(nrow(phe), 50)] <- NA
write.table(phe, file.path(DIR, "syn_pheno_long.txt"), sep = "\t", quote = FALSE,
            row.names = FALSE, na = "")

# ESI: rough function of severity; pre and post rows; a few duplicates/missing.
esi_post <- round(pmax(0, 1.2 + 1.6 * sev + rnorm(n, 0, .6)), 3)
esi_pre  <- round(pmax(0, esi_post + rnorm(n, 0.1, .5)), 3)
E <- rbind(data.frame(sid, visitnum = 1, PrePost = 0, ESI = esi_pre),
           data.frame(sid, visitnum = 1, PrePost = 1, ESI = esi_post),
           data.frame(sid = sid[1:200], visitnum = 2, PrePost = 1, ESI = esi_post[1:200]))
E <- E[!(E$PrePost == 1 & E$visitnum == 1 & E$sid %in% sample(sid, 80)), ]
E <- rbind(E, data.frame(sid = sid[5:9], visitnum = 1, PrePost = 1, ESI = esi_post[5:9] + .01))
E <- E[sample(nrow(E)), ]
E$PEF <- round(runif(nrow(E), 2, 10), 2); E$FVC <- round(runif(nrow(E), 2, 5), 2)
E$FEF25 <- E$FEF50 <- E$FEF75 <- round(runif(nrow(E), .2, 4), 2)
E <- E[, c("sid", "visitnum", "PrePost", "PEF", "FVC", "FEF25", "FEF50", "FEF75", "ESI")]
lines <- c(paste0("﻿", paste(c(names(E), "", ""), collapse = ",")),
           apply(E, 1, function(r) paste(c(trimws(r), "", ""), collapse = ",")))
con <- file(file.path(DIR, "syn_pft_esi.csv"), open = "w", encoding = "UTF-8")
writeLines(lines, con); close(con)

# MD-COPD file: score from the published rule, with noise and exclusions.
afl <- !is.na(ratio) & ratio < .7
nmin <- (emph %in% 2:5) + (wall %in% 2) + (mmrc >= 2) + (sgrq >= 25) + (cb == 1)
card <- cad == 1 | chf == 1
score <- ifelse(afl & nmin >= 1, 1,
         ifelse(!afl & nmin >= 3 & (!card | ((emph %in% 2:5) & (wall %in% 2))), 2, 0))
flip <- sample(n, 30); score[flip] <- sample(0:2, 30, TRUE)
score[sample(n, 150)] <- NA
sub <- ifelse(is.na(score), "", c("None", "Major", "Minor")[score + 1])
md <- data.frame(sid, MultiDim_COPD_Subtype = sub, MultiDim_COPD_score = score, extra = 1)
md <- md[-sample(n, 100), ]
write.csv(md, file.path(DIR, "syn_mdcopd.csv"), row.names = FALSE, na = "")

# Vital status and cause of death.
haz <- 0.012 * exp(0.6 * sev + 0.04 * (age - 60))
tdeath <- rexp(n, haz) * 365.25; tcens <- runif(n, 3, 14) * 365.25
dead <- as.integer(tdeath < tcens); days <- round(pmin(tdeath, tcens))
vsd <- data.frame(sid, Cohort = cohort, vital_status = dead, days_followed = days)
write.csv(vsd[-sample(n, 5), ], file.path(DIR, "syn_vital.csv"), row.names = FALSE)
torch <- ifelse(dead == 1, sample(1:6, n, TRUE, c(.25, .25, .2, .1, .1, .1)), NA)
torch[dead == 1 & sev > 1.2 & runif(n) < .5] <- 1
torch[sample(which(dead == 1), 10)] <- NA
codd <- data.frame(sid, mortality_survival_vital_status = dead, censor_date = "2018-01-01",
                   Torch_Group_Basic = torch, other = "z")
write.table(codd, file.path(DIR, "syn_cod.txt"), sep = "\t", quote = FALSE, row.names = FALSE, na = "")

# LFU exacerbations.
yf <- round(runif(n, 0, 12), 1)
te <- rnbinom(n, mu = yf * exp(-1.6 + .7 * sev), size = 0.8)
lfu <- data.frame(sid, ccenter = "X", Cohort = cohort, Total_Exacerbations = te,
                  Years_Followed = yf, other = 0)
lfu <- lfu[-sample(n, 300), ]
write.table(lfu, file.path(DIR, "syn_lfu.txt"), sep = "\t", quote = FALSE, row.names = FALSE, na = "")

cfg <- normalizePath(DIR)
writeLines(c(
  "# synthetic config written by make_synthetic.R",
  sprintf('ESI_PATH    <- "%s"', file.path(cfg, "syn_pft_esi.csv")),
  sprintf('PHE_PATH    <- "%s"', file.path(cfg, "syn_pheno_long.txt")),
  sprintf('VS_PATH     <- "%s"', file.path(cfg, "syn_vital.csv")),
  sprintf('COD_PATH    <- "%s"', file.path(cfg, "syn_cod.txt")),
  sprintf('EX_PATH     <- "%s"', file.path(cfg, "syn_lfu.txt")),
  sprintf('MDCOPD_PATH <- "%s"', file.path(cfg, "syn_mdcopd.csv")),
  'ID_COL <- "sid"'), file.path(DIR, "config_paths.R"))
cat("synthetic inputs written to", cfg, "\n")
