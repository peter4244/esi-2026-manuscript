#!/usr/bin/env Rscript
# Figure 1: ESI across the two visual CT criteria of MD-COPD. Mean ESI at each
# level of the Fleischner visual emphysema scale (A) and of visual airway wall
# thickening (B), with the MD-COPD threshold marked and the discrimination of
# each criterion by ESI given as an inset.
#
# Content follows Massimo's 2026-09-20 draft: points with group sizes, a dashed
# line at the level where the MD-COPD criterion is met, and an AUC inset. His
# panels sit side by side, which at this project's font size clipped panel B's
# title and hid its Definite point behind the inset, so the panels are stacked.
# Each keeps its own y range because the two criteria span different ESI ranges.
suppressPackageStartupMessages({ library(dplyr); library(ggplot2); library(patchwork) })
.b <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
HERE <- if (length(.b)) dirname(normalizePath(sub("^--file=", "", .b[1]))) else "ctfree/figures"
source(file.path(dirname(dirname(HERE)), "figures", "style.R"))
source(file.path(dirname(dirname(HERE)), "figures", "validate_layout.R"))
ASSETS <- file.path(dirname(HERE), "assets")

CONTENT_W_FIG <- CONTENT_W
NATIVE_W_FIG  <- CONTENT_W_FIG / DOCX_SCALE
TXT_PT        <- BODY_FS_NATIVE
stopifnot(TXT_PT * CONTENT_W_FIG / NATIVE_W_FIG >= DOCX_READABILITY_FLOOR)

lv <- read.csv(file.path(ASSETS, "esi_ct_levels.csv"), stringsAsFactors = FALSE)
au <- read.csv(file.path(ASSETS, "esi_ct_auc.csv"),    stringsAsFactors = FALSE)
stopifnot(nrow(lv) == 9, nrow(au) == 6)

TITLES <- c("Visual emphysema" = "Visual emphysema",
            "Airway wall thickening" = "Visual airway wall thickening")
XLAB   <- c("Visual emphysema" = "Visual emphysema category",
            "Airway wall thickening" = "Visual airway wall thickening category")
# The level at which MD-COPD counts the criterion as met.
MET    <- c("Visual emphysema" = 2, "Airway wall thickening" = 2)
MET_TXT <- c("Visual emphysema" = "MD-COPD-CT criterion: mild or greater",
             "Airway wall thickening" = "MD-COPD-CT criterion: definite")
SHOWN  <- c("none" = "None", "trace" = "Trace", "mild" = "Mild",
            "moderate" = "Moderate", "confluent" = "Confluent",
            "advanced destructive" = "Advanced\ndestructive",
            "absent" = "Absent", "borderline" = "Borderline", "definite" = "Definite")
STRATA <- c("All participants" = "Overall", "Airflow limitation" = "Airflow limitation",
            "Preserved spirometry" = "Without airflow limitation")
stopifnot(all(lv$label %in% names(SHOWN)), all(au$stratum %in% names(STRATA)),
          all(names(TITLES) %in% lv$criterion), all(names(TITLES) %in% au$criterion))
# Every participant with a visual score appears once per criterion, and the two
# criteria cover the same participants.
n_scored <- tapply(lv$n, lv$criterion, sum)
stopifnot(length(unique(n_scored)) == 1)
N_SCORED <- unname(n_scored[1])

panel <- function(crit) {
  d <- lv[lv$criterion == crit, ]
  d <- d[order(d$level), ]
  # A monotone rise is what the panel asserts; a break would make the legend wrong.
  stopifnot(all(diff(d$mean_ESI) > 0))
  d$x   <- factor(SHOWN[d$label], levels = SHOWN[d$label])
  d$lab <- paste0("n=", formatC(d$n, format = "d", big.mark = ","))
  a <- au[au$criterion == crit, ]
  a <- a[match(names(STRATA), a$stratum), ]
  stopifnot(!anyNA(a$auc_ESI))
  auc_txt <- paste(c("AUC", sprintf("%s %.2f", STRATA, a$auc_ESI)), collapse = "\n")
  cut_at  <- which(d$level == MET[[crit]]) - 0.5
  stopifnot(length(cut_at) == 1)
  top <- max(d$mean_ESI) * 1.28
  ggplot(d, aes(x = x, y = mean_ESI)) +
    geom_vline(xintercept = cut_at, linetype = 2, colour = "grey45", linewidth = 0.4) +
    geom_point(size = 2.6, colour = PALETTE[["CT-based"]]) +
    geom_text(aes(label = lab), vjust = -1.1, size = TXT_PT / .pt, family = "Arial") +
    annotate("label", x = 0.5, y = top, hjust = 0, vjust = 1, label = auc_txt,
             size = TXT_PT / .pt, family = "Arial", fill = "white", lineheight = 1.05) +
    scale_y_continuous(limits = c(0, top), expand = expansion(mult = c(0.02, 0.02))) +
    labs(title = TITLES[[crit]], subtitle = MET_TXT[[crit]], x = XLAB[[crit]], y = "Mean ESI") +
    theme_esi() +
    theme(panel.grid.major.x = element_blank(),
          plot.title = element_text(hjust = 0.5),
          plot.subtitle = element_text(hjust = 0.5),
          plot.margin = margin(3, 8, 3, 3))
}

panels <- lapply(names(TITLES), panel)
out <- file.path(HERE, "figure1_esi_ct.png")
for (p in panels) validate_layout(p, basename(out), native_w = NATIVE_W_FIG)
fig <- wrap_plots(panels, ncol = 1) + plot_annotation(tag_levels = "A")
ggsave(out, fig, width = NATIVE_W_FIG, height = 6.2, dpi = 300, bg = "white")
writeLines(sprintf("content_width_in=%.2f", CONTENT_W_FIG), file.path(HERE, "figure1_esi_ct.meta"))

writeLines(c(
  "**Figure 1. Relationship of ESI to the visual CT criteria of MD-COPD-CT.**",
  "",
  paste("Mean ESI according to visual emphysema severity (A) and visual airway wall thickening",
        "category (B). Dashed vertical lines indicate the thresholds defining the corresponding CT",
        "criteria in MD-COPD-CT: mild or greater emphysema and definite airway wall thickening. Insets",
        "show the area under the receiver operating characteristic curve (AUC) for discrimination of",
        "each visual CT criterion by ESI in the overall cohort and separately among participants with",
        "and without airflow limitation. Numbers adjacent to the points indicate the",
        sprintf("number of participants in each CT category; %s participants had a visual score for each",
                formatC(N_SCORED, format = "d", big.mark = ",")),
        "criterion. Panels keep separate y axes because the two criteria span different ESI ranges.",
        "ESI = Emphysema Severity Index; AUC = area under the receiver operating characteristic curve.")),
  file.path(HERE, "figure1_esi_ct_legend.md"))
cat(sprintf("wrote %s (%s participants scored per criterion)\n", out,
            formatC(N_SCORED, format = "d", big.mark = ",")))
