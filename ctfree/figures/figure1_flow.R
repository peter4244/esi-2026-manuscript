#!/usr/bin/env Rscript
# Figure 1: reclassification of the MD-COPD categories when chest CT is
# unavailable. Two rows: the participant flow across the full width on top,
# the two cross-classifications side by side beneath it (Pete, 2026-09-10).
#
#   A  Participant flow: NoCT classification | MD-COPD | ESI classification
#   B  NoCT classification cross-classified against MD-COPD (under the NoCT side of A)
#   C  ESI classification cross-classified against MD-COPD (under the ESI side of A)
#
# Coloring follows the v15 Figure 1 (../../figures/figure1_agreement): the
# category palette, matrix diagonals shaded in the category color with depth
# scaled to count, off-diagonal cells white with a light border, strata with
# thin dark borders. Ribbons are colored by MD-COPD origin, solid where the
# participant changes category and pale where it agrees (Pete, 2026-09-10).
#
# Portrait. The flow panel, the busiest element, gets the whole content width,
# and each matrix gets half of it; the script checks that the two matrices and
# their row labels fit side by side. Renders at the project's native width, so
# every font lands at the same docx size as the other figures, and writes the
# content width to figure1_flow.meta for the manuscript builder.
#
# Strata carry no text: the thin AFL-only strata cannot hold "AFL-only" at a
# readable size. Category identity is carried by color, keyed by the labeled
# diagonal cells of B and C.
#
# validate_layout checks theme text only, never geom_text, so every in-plot
# label here is sized from BODY_FS_NATIVE and asserted against the floor.
suppressPackageStartupMessages({
  library(dplyr); library(ggplot2); library(ggalluvial); library(patchwork)
})
.b <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
HERE <- if (length(.b)) dirname(normalizePath(sub("^--file=", "", .b[1]))) else "ctfree/figures"
source(file.path(dirname(dirname(HERE)), "figures", "style.R"))
source(file.path(dirname(dirname(HERE)), "figures", "validate_layout.R"))
ASSETS <- file.path(dirname(HERE), "assets")

S <- readRDS(file.path(ASSETS, "schema_labels.rds"))
N <- nrow(S)
O <- c("noCOPD", "AFL-only", "COPD-minor", "COPD-major")
PAL <- c("noCOPD" = "#7F7F7F", "AFL-only" = "#9467BD",
         "COPD-minor" = "#FFB000", "COPD-major" = "#D62728")
SHORT <- c("noCOPD" = "noCOPD", "AFL-only" = "AFL-only",
           "COPD-minor" = "minor", "COPD-major" = "major")

# ---- Page geometry ----------------------------------------------------------
NATIVE_W_FIG <- NATIVE_W                  # 7.5 in native, 6.5 in (CONTENT_W) in the docx
TXT_PT <- BODY_FS_NATIVE
stopifnot(TXT_PT * CONTENT_W / NATIVE_W_FIG >= DOCX_READABILITY_FLOOR,
          HEADER_FS_NATIVE * CONTENT_W / NATIVE_W_FIG >= DOCX_READABILITY_FLOOR)

# Text extents in inches. Arial is metrically compatible with Helvetica, which
# the null pdf device always has.
text_in <- function(s, pt, bold = FALSE, dim = c("w", "h")) {
  dim <- match.arg(dim)
  grDevices::pdf(NULL); on.exit(grDevices::dev.off(), add = TRUE)
  vapply(s, function(x) {
    g <- grid::textGrob(x, gp = grid::gpar(fontfamily = "Helvetica", fontsize = pt,
                                           fontface = if (bold) 2 else 1))
    if (dim == "w") grid::convertWidth(grid::grobWidth(g), "in", valueOnly = TRUE)
    else            grid::convertHeight(grid::grobHeight(g), "in", valueOnly = TRUE)
  }, numeric(1))
}

xtab <- function(target) {
  d <- as.data.frame(table(md = factor(S$S2, O), alt = factor(S[[target]], O)),
                     stringsAsFactors = FALSE)
  names(d)[3] <- "count"
  d$md <- factor(d$md, O); d$alt <- factor(d$alt, O)
  d$diag <- d$md == d$alt
  d
}
XA <- xtab("S3"); XC <- xtab("S4")
stopifnot(sum(XA$count) == N, sum(XC$count) == N, nrow(XA) == 16, nrow(XC) == 16)
count_lab <- function(x) formatC(x, format = "d", big.mark = ",")

# ---- Sizes derived from measured text ----------------------------------------
PAD <- 0.07
COL_W <- max(text_in(count_lab(c(XA$count, XC$count)), TXT_PT, bold = TRUE)) + 2 * PAD
MAT_W <- 4 * COL_W
PANEL_H <- 2.6
FLOW_H  <- 2.8
TXT_H <- max(text_in("Xg", TXT_PT, dim = "h"))
stopifnot(PANEL_H / 4 >= 1.5 * TXT_H)
ROWLAB_W <- max(text_in(SHORT, TXT_PT)) + TXT_H + 0.20
GAP <- 0.30
spare <- NATIVE_W_FIG - 2 * (MAT_W + ROWLAB_W) - GAP
cat(sprintf("column %.2f in; matrices with row labels %.2f in each; %.2f in spare\n",
            COL_W, MAT_W + ROWLAB_W, spare))
if (spare < 0) stop("the two matrices do not fit side by side at this width")

# ---- Matrix panels (A, C) ----------------------------------------------------
# One alpha scale across both matrices, so a given count shades the same in each.
DIAG_LIM <- range(c(XA$count[XA$diag], XC$count[XC$diag]))
matrix_panel <- function(d, xname, side, tag) {
  d$fill <- ifelse(d$diag, PAL[as.character(d$md)], "#FFFFFF")
  d$a    <- ifelse(d$diag, d$count, NA)
  d$txt  <- ifelse(d$diag & d$md == "COPD-major", "white", "grey15")
  d$y    <- factor(d$md, levels = rev(O))
  ggplot(d, aes(x = alt, y = y)) +
    geom_tile(aes(fill = fill, alpha = a), colour = "grey70", linewidth = 0.35) +
    geom_text(aes(label = count_lab(count), colour = txt), family = "Arial",
              fontface = "bold", size = TXT_PT / .pt) +
    scale_fill_identity() + scale_colour_identity() +
    scale_alpha_continuous(range = c(0.55, 1), limits = DIAG_LIM, na.value = 1,
                           guide = "none") +
    scale_x_discrete(position = "top", labels = SHORT, expand = c(0, 0)) +
    scale_y_discrete(position = side, labels = SHORT, expand = c(0, 0)) +
    labs(x = xname, y = "MD-COPD", tag = tag) +
    theme_esi() +
    theme(panel.grid = element_blank(), panel.border = element_blank(),
          panel.background = element_blank(), axis.ticks = element_blank(),
          axis.text.x.top = element_text(angle = 45, hjust = 0, vjust = 0),
          plot.margin = margin(4, 4, 4, 4))
}
pA <- matrix_panel(XA, "NoCT classification", "left",  "B")
pC <- matrix_panel(XC, "ESI classification",  "right", "C")

# ---- Flow panel (B) ----------------------------------------------------------
W_OUT <- 0.30; W_MID <- 0.40
Y_EXP <- expansion(mult = c(0.02, 0.02))
stack_of <- function(v) {
  n <- as.numeric(table(factor(v, levels = O)))
  data.frame(cat = factor(O, levels = O), n = n,
             ymax = sum(n) - c(0, cumsum(n)[-length(n)]),
             ymin = sum(n) - cumsum(n))
}
flow_theme <- function() theme_esi() +
  theme(axis.title = element_blank(), panel.grid = element_blank(),
        panel.border = element_blank(), axis.ticks = element_blank(),
        axis.text.y = element_blank(),
        axis.text.x.top = element_text(vjust = 0, lineheight = 0.9),
        plot.margin = margin(4, 0, 4, 0))
ribbons <- function(target, side) {
  d <- S %>% count(md = factor(S2, levels = O), alt = factor(.data[[target]], levels = O)) %>%
    mutate(moved = md != alt)
  ax <- if (side == "left") aes(y = n, axis1 = alt, axis2 = md)
        else                aes(y = n, axis1 = md,  axis2 = alt)
  outer_x <- if (side == "left") 1 else 2
  r <- transform(stack_of(S[[target]]),
                 xmin = outer_x - W_OUT / 2, xmax = outer_x + W_OUT / 2)
  ggplot(d, ax) +
    geom_alluvium(aes(fill = md, alpha = moved), width = W_OUT, curve_type = "sigmoid") +
    geom_rect(data = r, inherit.aes = FALSE,
              aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, fill = cat),
              colour = "grey20", linewidth = 0.15) +
    scale_alpha_manual(values = c(`TRUE` = 0.85, `FALSE` = 0.16), guide = "none") +
    scale_fill_manual(values = PAL, guide = "none") +
    scale_x_discrete(position = "top",
                     limits = if (side == "left") c("NoCT\nclassification", "")
                              else               c("", "ESI\nclassification"),
                     expand = if (side == "left") expansion(add = c(0.45, 0))
                              else               expansion(add = c(0, 0.45))) +
    scale_y_continuous(expand = Y_EXP) +
    labs(tag = if (side == "left") "A" else NULL) +
    flow_theme()
}
reference_panel <- function() {
  ggplot(stack_of(S$S2)) +
    geom_rect(aes(xmin = 0, xmax = 1, ymin = ymin, ymax = ymax, fill = cat),
              colour = "grey20", linewidth = 0.15) +
    scale_fill_manual(values = PAL, guide = "none") +
    scale_x_continuous(limits = c(0, 1), expand = c(0, 0), breaks = 0.5,
                       labels = "MD-COPD", position = "top") +
    scale_y_continuous(expand = Y_EXP) +
    flow_theme()
}
pL <- ribbons("S3", "left"); pM <- reference_panel(); pR <- ribbons("S4", "right")
pB <- (pL | pM | pR) + plot_layout(widths = c(1, W_MID, 1))

# ---- Cross-checks against the analysis artifacts -----------------------------
rc  <- read.csv(file.path(ASSETS, "reclassification.csv"))
acc <- read.csv(file.path(ASSETS, "accuracy_test.csv"))
lost_left  <- sum(S$S2 == "COPD-major" & S$S3 == "AFL-only")
lost_right <- sum(S$S2 == "COPD-major" & S$S4 == "AFL-only")
conc_left  <- sum(XA$count[XA$diag]); conc_right <- sum(XC$count[XC$diag])
stopifnot(lost_left  == rc$major_to_aflonly[rc$schema == "S3"],
          lost_right == rc$major_to_aflonly[rc$schema == "S4"],
          conc_left  == rc$concordant[rc$schema == "S3"],
          conc_right == rc$concordant[rc$schema == "S4"],
          conc_left  == acc$correct_noct, conc_right == acc$correct_esi)

# ---- Compose, validate, save -------------------------------------------------
for (p in list(pA, pC, pL, pM, pR)) validate_layout(p, "figure1_flow.png", native_w = NATIVE_W_FIG)
bottom <- (pA | plot_spacer() | pC) +
  plot_layout(widths = unit(c(MAT_W, 1, MAT_W), c("in", "null", "in")))
fig <- (pB / bottom) + plot_layout(heights = unit(c(FLOW_H, PANEL_H), "in"))
HEIGHT <- FLOW_H + PANEL_H + 1.9
out <- file.path(HERE, "figure1_flow.png")
ggsave(out, fig, width = NATIVE_W_FIG, height = HEIGHT, dpi = 300, bg = "white")
writeLines(sprintf("content_width_in=%.2f", CONTENT_W), file.path(HERE, "figure1_flow.meta"))

p_txt <- if (acc$p_value < 0.001) "P < 0.001" else sprintf("P = %.3f", acc$p_value)
writeLines(c(
  "**Figure 1. Reclassification of the MD-COPD categories when chest CT is unavailable.**",
  "",
  sprintf(paste(
    "(A) Participant flow from MD-COPD (center) to the NoCT classification (left) and",
    "the ESI classification (right). Column heights and ribbon widths are proportional",
    "to participant counts. Ribbons are colored by MD-COPD category, solid where the",
    "participant changes category and pale where it agrees; colors are gray for noCOPD,",
    "purple for AFL-only, yellow for COPD-minor and red for COPD-major, as in the",
    "diagonal cells of (B) and (C). (B) The NoCT classification cross-classified against",
    "MD-COPD. Rows are MD-COPD categories and columns the NoCT classification; diagonal",
    "cells, which agree, are shaded in the category color with depth proportional to",
    "count, and off-diagonal cells are white. (C) The ESI classification cross-classified",
    "against MD-COPD, laid out as in (B). Overall, the",
    "ESI classification agreed with MD-COPD for %s of %s participants (%.1f%%) and the",
    "NoCT classification for %s (%.1f%%) (McNemar %s). The difference is concentrated",
    "in COPD-major, of whom %d are reclassified as AFL-only without CT against %d with",
    "ESI. AFL-only, airflow limitation without other criteria."),
    count_lab(conc_right), count_lab(N), 100 * conc_right / N,
    count_lab(conc_left), 100 * conc_left / N, p_txt, lost_left, lost_right)),
  file.path(HERE, "figure1_flow_legend.md"))
cat(sprintf("wrote %s  (%.2f x %.2f in native; agreement ESI %d, NoCT %d; COPD-major lost %d / %d)\n",
            out, NATIVE_W_FIG, HEIGHT, conc_right, conc_left, lost_left, lost_right))
