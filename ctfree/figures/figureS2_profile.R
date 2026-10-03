#!/usr/bin/env Rscript
# Figure 4: structural, spirometric and symptom profile of the groups on which
# MD-COPD and the ESI classification agree or disagree, within each stratum.
#
# Updated from v15 Figure 2 (../../figures/figure2_discordance), which showed the
# preserved-spirometry stratum only. Bars for group means with standard errors and
# for the share meeting each criterion. All bars are black and each group is named
# under its bar: a color per group carried no information (Pete, 2026-09-26). One bracket per panel, for the contrast the Results
# make (CT-only against ESI-only); the other pairwise tests are in the artifact.
#
# Rows are strata. Each measure keeps one y axis across both strata, so a column
# compares the same quantity in the two. Landscape: seven measures side by side
# need the 9 in content width.
suppressPackageStartupMessages({ library(dplyr); library(ggplot2); library(patchwork) })
.b <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
HERE <- if (length(.b)) dirname(normalizePath(sub("^--file=", "", .b[1]))) else "ctfree/figures"
source(file.path(dirname(dirname(HERE)), "figures", "style.R"))
source(file.path(dirname(dirname(HERE)), "figures", "validate_layout.R"))
ASSETS <- file.path(dirname(HERE), "assets")

CONTENT_W <- 9.0
NATIVE_W_FIG <- CONTENT_W / DOCX_SCALE
TXT_PT <- BODY_FS_NATIVE
stopifnot(TXT_PT * CONTENT_W / NATIVE_W_FIG >= DOCX_READABILITY_FLOOR)

prof  <- read.csv(file.path(ASSETS, "discord_profile_strata.csv"), stringsAsFactors = FALSE)
tests <- read.csv(file.path(ASSETS, "discord_profile_tests.csv"),  stringsAsFactors = FALSE)
stopifnot(nrow(prof) == 8, nrow(tests) == 42)
# Bar order: Both-COPD leftmost (Pete, 2026-09-14), then the two discordant groups.
SHOWN <- c("Both-COPD" = "Both-COPD", "CT-only-COPD" = "CT-only", "ESI-only-COPD" = "ESI-only")
STR   <- c("Preserved spirometry" = "Without airflow\nlimitation",
           "Airflow limitation"   = "Airflow\nlimitation")
MEAS <- list(
  list(test = "ESI",                       col = "mean_ESI",        se = "se_ESI",    title = "ESI"),
  list(test = "Insp_LAA950_total_Thirona", col = "mean_LAA950",     se = "se_LAA950", title = "%LAA-950HU"),
  list(test = "emph_yn", col = "pct_visual_emph", title = "Emphysema\n(visual)"),
  list(test = "wall_yn", col = "pct_wall_thick",  title = "Wall thick.\n(visual)"),
  list(test = "dysp_yn", col = "pct_dyspnea",     title = "mMRC ≥ 2"),
  list(test = "qol_yn",  col = "pct_sgrq",        title = "SGRQ ≥ 25"),
  list(test = "cb_yn",   col = "pct_cb",          title = "Chronic\nbronchitis"))
stars <- function(p) ifelse(p < 0.001, "***", ifelse(p < 0.01, "**", ifelse(p < 0.05, "*", "ns")))

d0 <- prof[prof$group %in% names(SHOWN), ]
d0$grp <- factor(SHOWN[d0$group], levels = SHOWN)
d0$stratum <- factor(d0$stratum, levels = names(STR))
stopifnot(nrow(d0) == 6)

panel <- function(i) {
  m <- MEAS[[i]]; is_mean <- !is.null(m$se)
  d <- data.frame(stratum = d0$stratum, grp = d0$grp, y = d0[[m$col]],
                  se = if (is_mean) d0[[m$se]] else 0)
  top <- d %>% group_by(stratum) %>% summarise(ymax = max(y + se), .groups = "drop")
  span <- max(top$ymax)
  tt <- tests[tests$measure == m$test & tests$group1 == "CT-only-COPD" &
              tests$group2 == "ESI-only-COPD", ]
  stopifnot(nrow(tt) == 2)
  br <- merge(top, data.frame(stratum = factor(tt$stratum, levels = names(STR)),
                              lab = stars(tt$p)), by = "stratum")
  # No bracket where neither group meets the criterion: the classification
  # rules force that, and a test of two zeros says nothing.
  both_zero <- d %>% filter(grp %in% c("CT-only", "ESI-only")) %>%
    group_by(stratum) %>% summarise(z = all(y == 0), .groups = "drop")
  br <- br[!br$stratum %in% both_zero$stratum[both_zero$z], ]
  br$yb <- br$ymax + 0.08 * span; br$yl <- br$yb + 0.05 * span
  # Bracket ends sit on the CT-only and ESI-only bars wherever the bar order puts them.
  xa <- match("CT-only", levels(d$grp)); xb <- match("ESI-only", levels(d$grp))
  stopifnot(!is.na(xa), !is.na(xb))
  br$xa <- xa; br$xb <- xb; br$xm <- (xa + xb) / 2
  ylim_top <- max(c(br$yl, span)) + 0.12 * span
  p <- ggplot(d, aes(x = grp, y = y)) +
    geom_col(width = 0.72, fill = "black") +
    { if (is_mean) geom_errorbar(aes(ymin = y, ymax = y + se), width = 0.25,
                                 linewidth = 0.35) } +
    geom_segment(data = br, inherit.aes = FALSE, aes(x = xa, xend = xb, y = yb, yend = yb),
                 linewidth = 0.3) +
    geom_segment(data = br, inherit.aes = FALSE, aes(x = xa, xend = xa, y = yb, yend = yb - 0.03 * span),
                 linewidth = 0.3) +
    geom_segment(data = br, inherit.aes = FALSE, aes(x = xb, xend = xb, y = yb, yend = yb - 0.03 * span),
                 linewidth = 0.3) +
    geom_text(data = br, inherit.aes = FALSE, aes(x = xm, y = yl, label = lab),
              size = TXT_PT / .pt, family = "Arial", vjust = 0) +
    scale_y_continuous(limits = c(0, ylim_top), expand = expansion(mult = c(0, 0)),
                       breaks = if (is_mean) scales::breaks_extended(n = 3)
                                else c(0, 25, 50, 75, 100)) +
    facet_grid(stratum ~ ., labeller = labeller(stratum = STR)) +
    labs(title = m$title, x = NULL,
         y = if (i == 1) "Mean" else if (i == 3) "% of group" else NULL) +
    theme_esi() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1),
          panel.grid.major.x = element_blank(), panel.grid.minor = element_blank(),
          plot.title = element_text(hjust = 0.5, lineheight = 0.9),
          strip.text.y = if (i == length(MEAS)) element_text() else element_blank(),
          strip.background = element_blank(),
          plot.margin = margin(2, 3, 2, 3))
  p
}
panels <- lapply(seq_along(MEAS), panel)
for (p in panels) validate_layout(p, "figureS2_profile.png", native_w = NATIVE_W_FIG)
fig <- wrap_plots(panels, nrow = 1)
out <- file.path(HERE, "figureS2_profile.png")
ggsave(out, fig, width = NATIVE_W_FIG, height = 4.6, dpi = 300, bg = "white")
writeLines(sprintf("content_width_in=%.2f", CONTENT_W), file.path(HERE, "figureS2_profile.meta"))

# Group sizes as "Both-COPD, n = 714; CT-only, n = 85; and ESI-only, n = 501", from the data.
nn <- function(s) {
  k <- formatC(d0$n[d0$stratum == s][match(names(SHOWN), d0$group[d0$stratum == s])], format = "d", big.mark = ",")
  sprintf("%s, n = %s; %s, n = %s; and %s, n = %s", SHOWN[1], k[1], SHOWN[2], k[2], SHOWN[3], k[3])
}
writeLines(c(
  "**Supplemental Figure S2. Clinical, physiological, and CT characteristics according to concordance and discordance between MD-COPD-CT and MD-COPD-ESI classifications.**",
  "",
  paste("Characteristics are shown for participants classified as COPD by both approaches",
        "(Both-COPD), by MD-COPD-CT only (CT-only), or by MD-COPD-ESI only (ESI-only), separately",
        "among participants with and without airflow limitation. Bars show group means with",
        "standard errors for ESI and %LAA-950HU and the percentage of participants meeting each",
        "criterion for visual emphysema, definite airway wall thickening, mMRC \u22652, SGRQ \u226525,",
        "and chronic bronchitis. Comparisons between CT-only and ESI-only used Wilcoxon rank-sum",
        "tests for ESI and %LAA-950HU and Fisher's exact tests for categorical variables.",
        "* P < 0.05; ** P < 0.01; *** P < 0.001; ns = not significant. Comparisons fixed by the",
        "classification definitions are shown without statistical testing. Group sizes without",
        paste0("airflow limitation were ", nn("Preserved spirometry"), "; with airflow limitation, ",
               nn("Airflow limitation"), "."),
        "%LAA-950HU = percentage of lung below \u2212950 Hounsfield units at inspiration;",
        "mMRC = modified Medical Research Council dyspnea scale; SGRQ = St. George's Respiratory",
        "Questionnaire; ESI = Emphysema Severity Index.")),
  file.path(HERE, "figureS2_profile_legend.md"))
cat("wrote", out, "\n")
