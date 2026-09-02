#!/usr/bin/env Rscript
# Figure 1 (draft) — what happens to the MD-COPD classification when CT is
# removed, by two different routes.
#
# MD-COPD with CT is the reference and both CT-free schemas derive FROM it, so
# a single three-axis alluvial reads wrongly: its grammar is sequential, and it
# implies without-CT then with-CT then with-ESI.
#
# Three panels instead. The reference column is its own middle panel, flanked
# by a ribbon panel on each side, the left one running right to left. That puts
# the reference at the figure's true midpoint with its labels centred in it,
# neither of which is achievable by splitting the column across two panels:
# whichever panel owns the column pulls it off centre, and a label sitting on
# the join is clipped at the panel edge.
#
# The comparison the figure exists to make: the COPD-major ribbon splits
# heavily into AFL-only-noCOPD on the left, where the structural criterion is
# simply dropped, and much less so on the right, where ESI stands in for it.
#
# MOCKUP STAGE: relaxed rigor, no validator gate yet.
suppressPackageStartupMessages({
  library(dplyr); library(ggplot2); library(ggalluvial); library(patchwork)
})
.b <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
HERE <- if (length(.b)) dirname(normalizePath(sub("^--file=", "", .b[1]))) else "ctfree/figures"
source(file.path(dirname(dirname(HERE)), "figures", "style.R"))
ASSETS <- file.path(dirname(HERE), "assets")

S <- readRDS(file.path(ASSETS, "schema_labels.rds"))
O <- c("noCOPD", "AFL-only", "COPD-minor", "COPD-major")
PAL <- c("noCOPD" = "#7F7F7F", "AFL-only" = "#9467BD",
         "COPD-minor" = "#FFB000", "COPD-major" = "#D62728")
# Strata below this height get no label rather than an overflowing one.
LABEL_MIN  <- 0.035 * nrow(S)
W_OUT <- 0.30   # outer column width
W_MID <- 0.40   # shared centre column, wider but not double
STRAT_LAB  <- c("noCOPD" = "noCOPD", "AFL-only" = "AFL-only",
                "COPD-minor" = "minor", "COPD-major" = "major")

# Stratum extents, computed rather than left to geom_stratum, which takes one
# width for every axis and so cannot make the reference column wider than the
# others without doubling it.
stack_of <- function(v) {
  n <- as.numeric(table(factor(v, levels = O)))
  data.frame(cat = factor(O, levels = O), n = n,
             ymax = sum(n) - c(0, cumsum(n)[-length(n)]),
             ymin = sum(n) - cumsum(n), stringsAsFactors = FALSE)
}
Y_EXP <- expansion(mult = c(0.02, 0.02))

ribbons <- function(target, side) {
  d <- S %>% count(md = factor(S2, levels = O), alt = factor(.data[[target]], levels = O)) %>%
    mutate(moved = md != alt)
  ax <- if (side == "left") aes(y = n, axis1 = alt, axis2 = md)
        else                aes(y = n, axis1 = md,  axis2 = alt)
  outer_x <- if (side == "left") 1 else 2
  r <- transform(stack_of(S[[target]]),
                 xmin = outer_x - W_OUT / 2, xmax = outer_x + W_OUT / 2)
  r$lab <- ifelse(r$n >= LABEL_MIN, STRAT_LAB[as.character(r$cat)], "")
  ggplot(d, ax) +
    geom_alluvium(aes(fill = md, alpha = moved), width = W_OUT, curve_type = "sigmoid") +
    geom_rect(data = r, inherit.aes = FALSE,
              aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, fill = cat)) +
    geom_text(data = subset(r, lab != ""), inherit.aes = FALSE,
              aes(x = outer_x, y = (ymin + ymax) / 2, label = lab),
              size = BODY_FS_NATIVE / .pt * 0.62, family = "Arial",
              colour = "white", fontface = "bold") +
    scale_alpha_manual(values = c(`TRUE` = 0.85, `FALSE` = 0.16), guide = "none") +
    scale_fill_manual(values = PAL, guide = "none") +
    # Zero expansion on the side facing the reference panel, so the ribbons
    # meet the column with no gap.
    scale_x_discrete(limits = if (side == "left") c("NoCT-MD-COPD", "")
                              else               c("", "ESI-MD-COPD"),
                     expand = if (side == "left") expansion(add = c(0.26, 0))
                              else               expansion(add = c(0, 0.26))) +
    scale_y_continuous(expand = Y_EXP,
                       labels = function(v) format(v, big.mark = ",")) +
    labs(y = if (side == "left") "Participants" else NULL) +
    theme_esi() +
    theme(axis.title.x = element_blank(),
          panel.grid = element_blank(), panel.border = element_blank(),
          axis.ticks.x = element_blank(),
          axis.line.y  = if (side == "left") element_line(colour = "grey40") else element_blank(),
          axis.text.y  = if (side == "left") element_text() else element_blank(),
          axis.ticks.y = if (side == "left") element_line() else element_blank(),
          # The outer axis labels are wider than their columns; give the outer
          # edges room rather than shrinking text below the readability floor.
          plot.margin  = if (side == "left") margin(4, 0, 4, 4) else margin(4, 26, 4, 0))
}

reference_panel <- function() {
  r <- stack_of(S$S2)
  r$lab <- ifelse(r$n >= LABEL_MIN, STRAT_LAB[as.character(r$cat)], "")
  ggplot(r) +
    geom_rect(aes(xmin = 0, xmax = 1, ymin = ymin, ymax = ymax, fill = cat)) +
    geom_text(data = subset(r, lab != ""),
              aes(x = 0.5, y = (ymin + ymax) / 2, label = lab),
              size = BODY_FS_NATIVE / .pt * 0.62, family = "Arial",
              colour = "white", fontface = "bold") +
    scale_fill_manual(values = PAL, guide = "none") +
    scale_x_continuous(limits = c(0, 1), expand = c(0, 0),
                       breaks = 0.5, labels = "MD-COPD") +
    scale_y_continuous(expand = Y_EXP) +
    labs(y = NULL) +
    theme_esi() +
    theme(axis.title = element_blank(), axis.text.y = element_blank(),
          axis.ticks = element_blank(), panel.grid = element_blank(),
          panel.border = element_blank(), plot.margin = margin(4, 0, 4, 0))
}

lost_left  <- sum(S$S2 == "COPD-major" & S$S3 == "AFL-only")
lost_right <- sum(S$S2 == "COPD-major" & S$S4 == "AFL-only")
conc_left  <- sum(S$S2 == S$S3); conc_right <- sum(S$S2 == S$S4)
n <- nrow(S)

source(file.path(dirname(dirname(HERE)), "figures", "validate_layout.R"))
validate_layout(ribbons("S3", "left"), file.path(HERE, "figure1_flow.png"))

p <- (ribbons("S3", "left") | reference_panel() | ribbons("S4", "right")) +
  plot_layout(widths = c(1, W_MID, 1)) +
  plot_annotation(
    theme = theme_esi() + theme(plot.caption = element_text(hjust = 0.5)))

out <- file.path(HERE, "figure1_flow.png")
ggsave(out, p, width = NATIVE_W, height = 4.8, dpi = 300, bg = "white")
# The legend is written to a sibling .md rather than drawn into the figure:
# a manuscript legend lives in the document, and baking it into the raster is
# also what kept pushing text into the canvas edge.
writeLines(c(
  "**Figure 1. Reclassification of the MD-COPD categories when chest CT is unavailable.**",
  "",
  sprintf(paste("Participants are shown under MD-COPD (centre)",
                "and under each CT-free alternative: NoCT-MD-COPD (left) and ESI-MD-COPD",
                "(right). Both derive from the central reference. Ribbons are coloured by",
                "MD-COPD category; solid ribbons change category under that alternative",
                "and pale ribbons agree. %s of %s",
                "participants (%.1f%%) keep their category without CT and %s (%.1f%%) with",
                "ESI. The difference is concentrated in COPD-major, of whom %d are",
                "reclassified as AFL-only-noCOPD without CT against %d with ESI. Strata",
                "smaller than 3.5%% of the cohort are left unlabelled."),
          format(conc_left, big.mark = ","), format(n, big.mark = ","), 100 * conc_left / n,
          format(conc_right, big.mark = ","), 100 * conc_right / n, lost_left, lost_right)),
  file.path(HERE, "figure1_flow_legend.md"))

cat(sprintf("wrote %s  (COPD-major lost: %d without CT, %d with ESI)\n",
            out, lost_left, lost_right))
