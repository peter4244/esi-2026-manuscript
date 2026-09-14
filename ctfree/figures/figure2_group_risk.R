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
SCH  <- c(S2 = "MD-COPD", S4 = "ESI classification", S3 = "NoCT classification")
OUTC <- c(all = "All-cause mortality", resp = "Respiratory mortality", exac = "Exacerbations")
GRPS <- c("AFL-only", "COPD-minor", "COPD-major")
PAL  <- c("AFL-only" = "#9467BD", "COPD-minor" = "#FFB000", "COPD-major" = "#D62728")
stopifnot(nrow(ref) == 1, ref$resp_deaths >= MIN_EVENTS_FIG)

crude <- crd %>% filter(schema %in% names(SCH), category %in% GRPS, outcome %in% names(OUTC)) %>%
  transmute(schema, group = category, outcome, est = rr, lo, hi,
            few = toupper(few_events) %in% c("TRUE", "T"), type = "Crude")
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
                        group = if (both) factor(type, levels = c("Adjusted", "Crude")) else schema)) +
    geom_vline(xintercept = 1, linetype = 2, colour = "grey45", linewidth = 0.4) +
    geom_linerange(aes(xmin = lo, xmax = hi), linewidth = 0.6, position = pd, na.rm = TRUE) +
    scale_colour_manual(values = PAL, guide = "none") +
    scale_x_log10(breaks = c(1, 2, 5, 10, 30, 100),   # each column shows those in its range
                  labels = scales::label_number(drop0trailing = TRUE),
                  expand = expansion(mult = c(0.10, 0.12))) +
    facet_grid(group ~ outcome, scales = "free_x") +
    labs(x = "Crude rate ratio versus the common noCOPD reference (log scale)", y = NULL) +
    theme_esi() +
    theme(panel.grid.minor = element_blank(), panel.grid.major.y = element_blank(),
          plot.margin = margin(4, 6, 2, 4))
  if (both) {
    base + geom_point(aes(shape = type), size = 2.4, position = pd, fill = "white", stroke = 0.9) +
      scale_shape_manual(values = c(Crude = 21, Adjusted = 19), name = NULL,
                         breaks = c("Crude", "Adjusted")) +
      labs(x = "Ratio versus the common noCOPD reference (log scale)") +
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

out_main <- file.path(HERE, "figure2_group_risk.png")
p_main <- plot_risk(main, both = FALSE)
validate_layout(p_main, out_main)
ggsave(out_main, p_main, width = NATIVE_W, height = 6.0, dpi = 300, bg = "white")
writeLines(sprintf("content_width_in=%.2f", CONTENT_W), file.path(HERE, "figure2_group_risk.meta"))

out_supp <- file.path(HERE, "figureS1_group_risk.png")
p_supp <- plot_risk(supp, both = TRUE)
validate_layout(p_supp, out_supp)
ggsave(out_supp, p_supp, width = NATIVE_W, height = 7.4, dpi = 300, bg = "white")
writeLines(sprintf("content_width_in=%.2f", CONTENT_W), file.path(HERE, "figureS1_group_risk.meta"))

common <- paste(
  "for each diagnostic group (rows) under MD-COPD, the ESI classification and the NoCT",
  "classification, for all-cause mortality, respiratory mortality and exacerbations (columns),",
  sprintf("against a common reference of the %s subjects assigned to noCOPD by all three",
          format(ref$n_cohort, big.mark = ",")),
  "classifications. The x axis is on a log scale and differs between columns.")
floor_note <- paste("A point drawn without an interval had fewer than 10 events in that group,",
                    "so no interval was estimated.")
writeLines(c(
  "**Figure 2. Crude risk of each diagnostic group under the three multidimensional classifications.**",
  "",
  paste("Crude rate ratios with 95% confidence intervals", common,
        "The crude rate ratio is the event rate in the group divided by the event rate in the reference.",
        floor_note, "Adjusted estimates are shown in Supplemental Figure S1.",
        "AFL-only = airflow limitation without other criteria.")),
  file.path(HERE, "figure2_group_risk_legend.md"))
writeLines(c(
  "**Supplemental Figure S1. Crude and adjusted risk of each diagnostic group under the three multidimensional classifications.**",
  "",
  paste("Crude rate ratios (open circles) and adjusted estimates (filled circles), with 95% confidence intervals,",
        common,
        "Adjusted estimates are hazard ratios for mortality and incidence rate ratios for exacerbations,",
        "from models carrying age, sex, race, current smoking status, pack-years and body mass index,",
        "with prior exacerbation frequency added for exacerbations.", floor_note,
        "AFL-only = airflow limitation without other criteria.")),
  file.path(HERE, "figureS1_group_risk_legend.md"))
cat("wrote", out_main, "and", out_supp, "\n")
