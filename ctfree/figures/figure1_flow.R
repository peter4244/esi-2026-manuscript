#!/usr/bin/env Rscript
# Figure 1 (draft) — what happens to the MD-COPD classification when CT is
# removed, by two different routes.
#
# MD-COPD with CT is the reference and both CT-free schemas derive FROM it, so
# a single three-axis alluvial reads wrongly: its grammar is sequential, and it
# implies without-CT then with-CT then with-ESI. Drawn as two panels sharing a
# central MD-COPD column, with the left panel's flow running right-to-left, the
# reference sits in the middle and both alternatives fan outward from it, which
# is what the analysis actually does.
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

O_REV <- rev(O)   # reversed so the shared middle column stacks identically

panel <- function(target, side) {
  d <- S %>% count(md = factor(S2, levels = O), alt = factor(.data[[target]], levels = O)) %>%
    mutate(moved = md != alt)
  # Left panel puts MD-COPD on its right edge; right panel on its left. Butted
  # together the two middle strata read as one shared column.
  ax <- if (side == "left") aes(y = n, axis1 = alt, axis2 = md)
        else                aes(y = n, axis1 = md,  axis2 = alt)
  # Stratum rectangles, computed rather than left to geom_stratum. Strata stack
  # with the first factor level at the top, so the extents run cumulatively down
  # from the cohort total.
  stack <- function(v) { n <- as.numeric(table(factor(v, levels = O)))
    data.frame(cat = factor(O, levels = O), n = n,
               ymax = sum(n) - c(0, cumsum(n)[-length(n)]),
               ymin = sum(n) - cumsum(n), stringsAsFactors = FALSE) }
  outer_x  <- if (side == "left") 1 else 2
  centre_x <- if (side == "left") 2 else 1
  r_out <- transform(stack(S[[target]]),
                     xmin = outer_x - W_OUT / 2, xmax = outer_x + W_OUT / 2,
                     xlab = outer_x)
  # The left panel draws the whole shared centre column, so the label sits at
  # its true centre instead of being clipped at the join. The right panel draws
  # none, and its expansion is zero on that side, so its ribbons begin exactly
  # where the column ends and the two read as continuous.
  r_out$lab <- ifelse(r_out$n >= LABEL_MIN, STRAT_LAB[as.character(r_out$cat)], "")
  rects <- if (side == "left") {
    r_mid <- transform(stack(S$S2),
                       xmin = centre_x - W_MID / 2, xmax = centre_x + W_MID / 2,
                       xlab = centre_x)
    r_mid$lab <- ifelse(r_mid$n >= LABEL_MIN, STRAT_LAB[as.character(r_mid$cat)], "")
    rbind(r_out, r_mid)
  } else r_out
  labs_x <- if (side == "left") c("MD-COPD without CT", "MD-COPD with CT")
            else               c("", "MD-COPD with ESI")
  ggplot(d, ax) +
    # geom_stratum takes one width for every axis, which forces the shared
    # centre column to twice the width of the outer ones. Drawing the strata as
    # explicit rectangles gives each column its own width: the reference is
    # wider, because it is shared and is what the others are measured against,
    # but not double.
    geom_alluvium(aes(fill = md, alpha = moved), width = W_OUT,
                  curve_type = "sigmoid") +
    geom_rect(data = rects, inherit.aes = FALSE,
              aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, fill = cat)) +
    geom_text(data = subset(rects, lab != ""), inherit.aes = FALSE,
              aes(x = xlab, y = (ymin + ymax) / 2, label = lab),
              size = BODY_FS_NATIVE / .pt * 0.62, family = "Arial",
              colour = "white", fontface = "bold") +
    scale_alpha_manual(values = c(`TRUE` = 0.85, `FALSE` = 0.16), guide = "none") +
    # No expansion on the facing edge, so the two centre strata butt together
    # and read as the single shared reference column they are.
    coord_cartesian(clip = "off") +
    scale_x_discrete(limits = labs_x,
                     expand = if (side == "left") expansion(add = c(0.22, W_MID / 2))
                              else                expansion(add = c(0.00, 0.30))) +
    scale_y_continuous(labels = function(v) format(v, big.mark = ",")) +
    scale_fill_manual(values = PAL, guide = "none") +
    labs(y = if (side == "left") "Participants" else NULL) +
    theme_esi() +
    theme(axis.title.x = element_blank(),
          panel.grid.major.x = element_blank(), panel.grid.minor = element_blank(),
          panel.border = element_blank(),
          # Only the left panel carries the axis line; the right panel would draw
          # its own at the join, cutting through the shared centre column.
          axis.line.y   = if (side == "left") element_line(colour = "grey40") else element_blank(),
          axis.text.y  = if (side == "left") element_text() else element_blank(),
          axis.ticks.y = if (side == "left") element_line() else element_blank(),
          axis.ticks.x = element_blank(),
          plot.margin  = if (side == "left") margin(4, 0, 4, 4) else margin(4, 4, 4, 0))
}

lost_left  <- sum(S$S2 == "COPD-major" & S$S3 == "AFL-only")
lost_right <- sum(S$S2 == "COPD-major" & S$S4 == "AFL-only")
conc_left  <- sum(S$S2 == S$S3); conc_right <- sum(S$S2 == S$S4)
n <- nrow(S)

p <- (panel("S3", "left") | panel("S4", "right")) +
  plot_annotation(
    subtitle = sprintf(
      "Concordant with MD-COPD: %s of %s without CT (%.1f%%), %s with ESI (%.1f%%)",
      format(conc_left, big.mark = ","), format(n, big.mark = ","), 100 * conc_left / n,
      format(conc_right, big.mark = ","), 100 * conc_right / n),
    caption = sprintf(paste(
      "Both CT-free schemas derive from the shared MD-COPD column at the centre.",
      "Solid ribbons change category;\npale ribbons agree.",
      "COPD-major reclassified as AFL-only-noCOPD: %d without CT, %d with ESI."),
      lost_left, lost_right),
    theme = theme_esi() + theme(plot.caption = element_text(hjust = 0.5)))

out <- file.path(HERE, "figure1_flow.png")
ggsave(out, p, width = NATIVE_W, height = 4.8, dpi = 300, bg = "white")
cat(sprintf("wrote %s  (COPD-major lost: %d without CT, %d with ESI)\n",
            out, lost_left, lost_right))
