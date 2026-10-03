#!/usr/bin/env Rscript
# Figure 2 (crude) and Supplemental Figure S1 (crude and adjusted): risk of each
# diagnostic group under each multidimensional classification, against the
# common noCOPD reference. Rows are the diagnostic groups, columns the outcomes.
# Replaces the former Figures 2 to 4, one per group (Pete, 2026-09-13).
#
# The x axis is free per outcome column and shared down it, so within a column
# the three groups sit on one scale. Reference is the common noCOPD group: the
# participants all three multidimensional classifications assign to noCOPD.
# The fixed ratio has no diagnostic pathways and is not shown.
suppressPackageStartupMessages({ library(dplyr); library(ggplot2) })
.b <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
HERE <- if (length(.b)) dirname(normalizePath(sub("^--file=", "", .b[1]))) else "ctfree/figures"
source(file.path(dirname(dirname(HERE)), "figures", "style.R"))
source(file.path(dirname(dirname(HERE)), "figures", "validate_layout.R"))
ASSETS <- file.path(dirname(HERE), "assets")

risk <- read.csv(file.path(ASSETS, "consensus_ref_risk.csv"),  stringsAsFactors = FALSE)
crd  <- read.csv(file.path(ASSETS, "consensus_ref_crude.csv"), stringsAsFactors = FALSE)
ref  <- read.csv(file.path(ASSETS, "consensus_ref_group.csv"), stringsAsFactors = FALSE)
MIN_EVENTS_FIG <- 10     # the analysis event floor (MIN_EVENTS in the Rmd)
SCH  <- c(S2 = "MD-COPD-CT", S4 = "MD-COPD-ESI", S3 = "MD-NoCT")
OUTC <- c(all = "All-cause mortality", resp = "Respiratory mortality", exac = "Exacerbations")
GRPS <- c("AFL-only", "COPD-minor", "COPD-major")
PAL  <- c("AFL-only" = "#9467BD", "COPD-minor" = "#FFB000", "COPD-major" = "#D62728")
stopifnot(nrow(ref) == 1, ref$resp_deaths >= MIN_EVENTS_FIG)

crude <- crd %>% filter(schema %in% names(SCH), category %in% GRPS, outcome %in% names(OUTC)) %>%
  transmute(schema, group = category, outcome, est = rr, lo, hi,
            few = toupper(few_events) %in% c("TRUE", "T"), type = "Unadjusted")
adj <- bind_rows(lapply(names(OUTC), function(o) {
  est <- if (o == "exac") "exac_IRR" else paste0(o, "_HR")
  lo  <- if (o == "exac") "exac_LCI" else paste0(o, "_LCI")
  hi  <- if (o == "exac") "exac_UCI" else paste0(o, "_UCI")
  r <- risk %>% filter(schema %in% names(SCH), category %in% GRPS)
  # exacerbation counts in every group are in the hundreds; the floor concerns deaths
  few <- if (o == "exac") rep(FALSE, nrow(r)) else toupper(r[[paste0(o, "_few_events")]]) %in% c("TRUE", "T")
  data.frame(schema = r$schema, group = r$category, outcome = o, est = r[[est]],
             lo = r[[lo]], hi = r[[hi]], few = few, type = "Adjusted", stringsAsFactors = FALSE)
}))
stopifnot(nrow(crude) == 27, nrow(adj) == 27, !anyNA(crude$est), !anyNA(adj$est))

prep <- function(d) {
  d$lo[d$few] <- NA_real_; d$hi[d$few] <- NA_real_
  stopifnot(!anyNA(d$lo[!d$few]), !anyNA(d$hi[!d$few]))
  d$group   <- factor(d$group, levels = GRPS)
  d$outcome <- factor(OUTC[d$outcome], levels = OUTC)
  d$schema  <- factor(SCH[d$schema], levels = rev(unname(SCH)))   # MD-COPD at the top
  d
}

plot_risk <- function(d, both) {
  pd <- position_dodge(width = if (both) 0.6 else 0)
  base <- ggplot(d, aes(x = est, y = schema, colour = group,
                        group = if (both) factor(type, levels = c("Adjusted", "Unadjusted")) else schema)) +
    geom_vline(xintercept = 1, linetype = 2, colour = "grey45", linewidth = 0.4) +
    geom_linerange(aes(xmin = lo, xmax = hi), linewidth = 0.6, position = pd, na.rm = TRUE) +
    scale_colour_manual(values = PAL, guide = "none") +
    scale_x_log10(breaks = c(1, 2, 5, 10, 30, 100),   # each column shows those in its range
                  labels = scales::label_number(drop0trailing = TRUE),
                  expand = expansion(mult = c(0.10, 0.12))) +
    facet_grid(group ~ outcome, scales = "free_x") +
    labs(x = "Unadjusted rate ratio versus the common noCOPD reference (log scale)", y = NULL) +
    theme_esi() +
    theme(panel.grid.minor = element_blank(), panel.grid.major.y = element_blank(),
          plot.margin = margin(4, 6, 2, 4))
  if (both) {
    base + geom_point(aes(shape = type), size = 2.4, position = pd, fill = "white", stroke = 0.9) +
      scale_shape_manual(values = c(Unadjusted = 21, Adjusted = 19), name = NULL,
                         breaks = c("Unadjusted", "Adjusted")) +
      labs(x = "Rate ratio or hazard ratio versus the common noCOPD reference (log scale)") +
      theme(legend.position = "bottom", legend.margin = margin(t = -2, b = 0))
  } else {
    base + geom_point(size = 2.4)
  }
}

main <- prep(crude)
supp <- prep(bind_rows(crude, adj))
stopifnot(nrow(main) == 27, nrow(supp) == 54)
# every panel must have points: an empty facet renders without error
stopifnot(all(table(main$group, main$outcome) == 3), all(table(supp$group, supp$outcome) == 6))

out_main <- file.path(HERE, "figure3_group_risk.png")
p_main <- plot_risk(main, both = FALSE)
validate_layout(p_main, out_main)
ggsave(out_main, p_main, width = NATIVE_W, height = 6.0, dpi = 300, bg = "white")
writeLines(sprintf("content_width_in=%.2f", CONTENT_W), file.path(HERE, "figure3_group_risk.meta"))

out_supp <- file.path(HERE, "figureS1_group_risk.png")
p_supp <- plot_risk(supp, both = TRUE)
validate_layout(p_supp, out_supp)
ggsave(out_supp, p_supp, width = NATIVE_W, height = 7.4, dpi = 300, bg = "white")
writeLines(sprintf("content_width_in=%.2f", CONTENT_W), file.path(HERE, "figureS1_group_risk.meta"))

ref_n <- format(ref$n_cohort, big.mark = ",")
writeLines(c(
  "**Figure 3. Unadjusted risk of clinical outcomes by diagnostic group under the three multidimensional classifications.**",
  "",
  paste("Unadjusted rate ratios with 95% confidence intervals for all-cause mortality, respiratory",
        "mortality, and respiratory exacerbations (columns) according to diagnostic group (rows) under",
        "MD-COPD-CT, MD-NoCT, and MD-COPD-ESI. The common reference was the", ref_n, "participants",
        "classified as noCOPD by all three classifications. The x-axis is on a logarithmic scale and",
        "differs among columns. Rate ratios were calculated as the event rate in each group divided by",
        "that in the common reference. Estimates based on fewer than 10 events are shown without",
        "confidence intervals; corresponding adjusted estimates are shown in Figure S1 in the Online",
        "Supplement. AFL-only = airflow limitation without other criteria; ESI = Emphysema Severity Index.")),
  file.path(HERE, "figure3_group_risk_legend.md"))
writeLines(c(
  "**Supplemental Figure S1. Unadjusted and adjusted risk of clinical outcomes by diagnostic group under the three multidimensional classifications.**",
  "",
  paste("Unadjusted rate ratios (open circles) and adjusted estimates (filled circles), with 95%",
        "confidence intervals, are shown for each diagnostic group (rows) under MD-COPD-CT, MD-NoCT,",
        "and MD-COPD-ESI for all-cause mortality, respiratory mortality, and respiratory exacerbations",
        "(columns), relative to a common reference comprising the", ref_n, "participants classified as",
        "noCOPD by all three classifications. The x-axis is on a logarithmic scale and differs among",
        "columns. Adjusted estimates are hazard ratios for mortality and incidence rate ratios for",
        "exacerbations from models adjusted for age, sex, race, current smoking status, pack-years,",
        "and body mass index; exacerbation models were additionally adjusted for baseline exacerbation",
        "frequency. Estimates based on fewer than 10 events are shown without confidence intervals.",
        "AFL-only = airflow limitation without other criteria; HR = hazard ratio; IRR = incidence rate",
        "ratio; ESI = Emphysema Severity Index.")),
  file.path(HERE, "figureS1_group_risk_legend.md"))
cat("wrote", out_main, "and", out_supp, "\n")
