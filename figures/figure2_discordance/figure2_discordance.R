#!/usr/bin/env Rscript
# Figure 2 — Discordance-subgroup comparison across seven characteristics.
#
# Three preserved-spirometry subgroups (CT-only-COPD, Both-COPD,
# ESI-only-COPD) compared across seven descriptors: ESI, %LAA-950HU (mean),
# visual emphysema (%), visual airway wall thickening (%), mMRC>=2 (%),
# SGRQ>=25 (%), chronic bronchitis (%).
#
# Data source: manuscript_assets/Table_Discordance.csv (subgroup means +
# percentages) and manuscript_assets/Table_Discordance_pairwise.csv (Wilcoxon
# rank-sum + chi-square pairwise tests written by the analysis Rmd's
# `discordance-pairwise` chunk).
# Output:      figures/figure2_discordance/figure2_discordance.png
#
# Style: sourced from ../style.R (fonts, palette). No fontsize literals here.
#
# Layout choice: axis labels use short subgroup names; the numeric N per
# subgroup appears in a bottom-of-figure legend rather than inside every
# axis label, so 5-facet bottom-row panels have room for readable text.
# Significance-bracket annotations show all three pairwise contrasts per
# panel (Wilcoxon for continuous, chi-square for binary; unadjusted).

suppressPackageStartupMessages({
  library(dplyr); library(ggplot2); library(scales); library(tidyr)
  library(patchwork)
})
source("../style.R")
source("../validate_layout.R")

ASSETS <- "../../manuscript_assets"

# ---- Load + reshape ------------------------------------------------------
disc <- read.csv(file.path(ASSETS, "Table_Discordance.csv"),
                  stringsAsFactors = FALSE, check.names = FALSE)
pw   <- read.csv(file.path(ASSETS, "Table_Discordance_pairwise.csv"),
                  stringsAsFactors = FALSE, check.names = FALSE)

mean_of <- function(x) as.numeric(sub("\\s*\\(.*", "", x))
sd_of   <- function(x) as.numeric(sub(".*\\(([^)]+)\\).*", "\\1", x))
pct_of  <- function(x) as.numeric(sub("%", "", x))

disc_num <- disc %>%
  mutate(
    subgroup_full = grp_5,
    n_subj        = n,
    ESI     = mean_of(ESI),
    ESI_sd  = sd_of(disc$ESI),
    LAA950  = mean_of(LAA950),
    LAA950_sd = sd_of(disc$LAA950),
    emph    = pct_of(pct_emph),
    wall    = pct_of(pct_wall),
    mMRC2p  = pct_of(pct_mMRC2p),
    SGRQ25p = pct_of(pct_SGRQ25p),
    CB      = pct_of(pct_CB)
  ) %>%
  mutate(
    ESI_se    = ESI_sd    / sqrt(n_subj),
    LAA950_se = LAA950_sd / sqrt(n_subj)
  )

# Short axis label per subgroup (no embedded n counts — those go in legend).
grp_full  <- c("CT-only-COPD (ESI missed)", "Both-COPD",
                "ESI-only-COPD (Bhatt missed)")
grp_short <- setNames(c("CT-only", "Both", "ESI-only"), grp_full)
disc_num$group <- factor(grp_short[disc_num$subgroup_full],
                          levels = unname(grp_short))

# Palette from the manuscript-wide framework colors.
grp_palette <- setNames(
  c(unname(PALETTE["CT-based"]), unname(PALETTE["noCOPD"]),
    unname(PALETTE["ESI-based"])),
  levels(disc_num$group))

# Ns for the bottom-of-figure legend line.
n_lookup <- setNames(disc_num$n_subj, disc_num$group)
n_annotation <- sprintf(
  "CT-only n = %d  |  Both n = %d  |  ESI-only n = %d",
  n_lookup["CT-only"], n_lookup["Both"], n_lookup["ESI-only"])

# ---- Significance-bracket helper -----------------------------------------
# x-positions on the discrete axis: CT-only=1, Both=2, ESI-only=3.
grp_x <- setNames(c(1, 2, 3), c("CT-only", "Both", "ESI-only"))

# Given per-feature max bar values, build a data frame of brackets (one row
# per pair × feature) and a matching data frame of labels for geom_text.
# Bracket y is staggered so pair 1 (adjacent), pair 2 (adjacent), pair 3
# (spans all three groups) stack cleanly without overlap.
build_bracket_frames <- function(pw_subset, feature_max, feature_col,
                                 y_mult = c(1.10, 1.40, 1.70),
                                 tick_frac = 0.020,
                                 label_lift_frac = 0.025) {
  # Fixed pair order → stable y-lane assignment
  pair_order <- list(
    list(g1 = "CT-only", g2 = "Both",     lane = 1),
    list(g1 = "Both",       g2 = "ESI-only", lane = 2),
    list(g1 = "CT-only", g2 = "ESI-only", lane = 3)
  )
  seg_rows <- list(); lbl_rows <- list()
  for (feat_key in names(feature_max)) {
    ymax   <- feature_max[[feat_key]]
    tick_h <- tick_frac * ymax
    for (po in pair_order) {
      row <- pw_subset %>% filter(descriptor == feat_key,
                                   ((group1 == po$g1 & group2 == po$g2) |
                                    (group1 == po$g2 & group2 == po$g1)))
      if (nrow(row) == 0) next
      x1  <- grp_x[[po$g1]]; x2 <- grp_x[[po$g2]]
      y   <- ymax * y_mult[po$lane]
      # 3 segments per bracket: top horizontal + 2 vertical ticks pointing down
      seg_rows[[length(seg_rows)+1]] <- data.frame(
        feature = feat_key, x = x1, xend = x2, y = y,    yend = y,
        stringsAsFactors = FALSE)
      seg_rows[[length(seg_rows)+1]] <- data.frame(
        feature = feat_key, x = x1, xend = x1, y = y,    yend = y - tick_h,
        stringsAsFactors = FALSE)
      seg_rows[[length(seg_rows)+1]] <- data.frame(
        feature = feat_key, x = x2, xend = x2, y = y,    yend = y - tick_h,
        stringsAsFactors = FALSE)
      lbl_rows[[length(lbl_rows)+1]] <- data.frame(
        feature = feat_key, x = (x1 + x2) / 2,
        y = y + label_lift_frac * ymax, label = row$sig[1],
        stringsAsFactors = FALSE)
    }
  }
  segments_df <- do.call(rbind, seg_rows)
  labels_df   <- do.call(rbind, lbl_rows)
  # Rename to match the plot's facet column
  colnames(segments_df)[colnames(segments_df) == "feature"] <- feature_col
  colnames(labels_df)[colnames(labels_df) == "feature"]     <- feature_col
  list(segments = segments_df, labels = labels_df)
}

# ---- Panel A: continuous descriptors (ESI, %LAA-950HU) -------------------
# Reshape means and SEs together so geom_errorbar can pull whisker positions
# from the same tidy frame that geom_col uses for bar heights.
cont <- disc_num %>%
  dplyr::select(group, ESI, LAA950, ESI_se, LAA950_se) %>%
  pivot_longer(cols = c(ESI, LAA950),
               names_to = "feature_key", values_to = "value") %>%
  mutate(se = ifelse(feature_key == "ESI", ESI_se, LAA950_se)) %>%
  dplyr::select(group, feature_key, value, se) %>%
  mutate(feature = recode(feature_key,
                          ESI    = "ESI",
                          LAA950 = "%LAA-950HU"))
cont$feature <- factor(cont$feature, levels = c("ESI", "%LAA-950HU"))

# Per-facet max value + SE (used for bracket y positioning so brackets clear
# the top of the SE whisker, not just the bar).
cont_max <- cont %>% group_by(feature_key) %>%
  summarise(m = max(value + se, na.rm = TRUE), .groups = "drop") %>%
  { setNames(as.list(.$m), .$feature_key) }
# CSV pw rows for ESI + LAA950
cont_pw <- pw %>% filter(descriptor %in% c("ESI", "LAA950"))
cont_bracket <- build_bracket_frames(
  cont_pw, cont_max, feature_col = "feature_key")
# Map feature_key → labelled facet ("ESI", "%LAA-950HU") for the plot
key_to_lbl <- c(ESI = "ESI", LAA950 = "%LAA-950HU")
cont_bracket$segments$feature <- factor(
  key_to_lbl[cont_bracket$segments$feature_key],
  levels = c("ESI", "%LAA-950HU"))
cont_bracket$labels$feature <- factor(
  key_to_lbl[cont_bracket$labels$feature_key],
  levels = c("ESI", "%LAA-950HU"))

p_cont <- ggplot(cont, aes(x = group, y = value, fill = group)) +
  geom_col(width = 0.7, color = "grey20", linewidth = 0.3) +
  geom_errorbar(aes(ymin = value - se, ymax = value + se),
                width = 0.20, linewidth = 0.35, color = "grey20") +
  geom_segment(data = cont_bracket$segments, inherit.aes = FALSE,
               aes(x = x, xend = xend, y = y, yend = yend),
               linewidth = 0.35, color = "grey20") +
  geom_text(data = cont_bracket$labels, inherit.aes = FALSE,
            aes(x = x, y = y, label = label),
            family = "Arial", size = BODY_FS_NATIVE * 0.28,
            vjust = 0) +
  facet_wrap(~ feature, ncol = 2, scales = "free_y") +
  scale_fill_manual(values = grp_palette, guide = "none") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.20))) +
  labs(x = NULL, y = "Mean") +
  theme_esi() +
  theme(panel.grid.major.x = element_blank(),
        panel.grid.minor   = element_blank(),
        legend.position    = "none",
        axis.text.x        = element_text(angle = 45, hjust = 1))

# ---- Panel B: percentage descriptors -------------------------------------
# Short strip labels so 5 facets fit at the target width without clipping.
pct <- disc_num %>%
  dplyr::select(group, emph, wall, mMRC2p, SGRQ25p, CB) %>%
  pivot_longer(-group, names_to = "feature_key", values_to = "value") %>%
  mutate(feature = recode(feature_key,
    # Emphysema and wall thickening here are the Fleischner VISUAL
    # assessment (CT_Visual_Emph_Severity ≥ mild; CT_Visual_Wall_Thickening
    # = definite), NOT Pi10 / Wall Area % / %LAA-950HU. The "(visual)"
    # suffix disambiguates for a reader familiar with quantitative CT.
    # Strip labels wrap onto two lines so "(visual)" fits in the narrow
    # 5-facet layout. Cap ≈ 14 characters per line at BODY_FS_NATIVE=12 in
    # a NATIVE_W=7.5 / ncol=5 grid — see validate_layout strip-length check.
    emph    = "Emphysema\n(visual)",
    wall    = "Wall thick.\n(visual)",
    mMRC2p  = "mMRC ≥ 2",
    SGRQ25p = "SGRQ ≥ 25",
    CB      = "Bronchitis"))
pct_levels <- c("Emphysema\n(visual)", "Wall thick.\n(visual)",
                "mMRC ≥ 2", "SGRQ ≥ 25", "Bronchitis")
pct$feature <- factor(pct$feature, levels = pct_levels)

# Percentages share a fixed 0-100 scale, so use a common max of 100.
pct_keys <- c("emph","wall","mMRC2p","SGRQ25p","CB")
pct_max  <- setNames(as.list(rep(100, length(pct_keys))), pct_keys)
pct_pw   <- pw %>% filter(descriptor %in% pct_keys)
pct_bracket <- build_bracket_frames(
  pct_pw, pct_max, feature_col = "feature_key")
key_to_pct_lbl <- setNames(pct_levels, pct_keys)
pct_bracket$segments$feature <- factor(
  key_to_pct_lbl[pct_bracket$segments$feature_key], levels = pct_levels)
pct_bracket$labels$feature <- factor(
  key_to_pct_lbl[pct_bracket$labels$feature_key], levels = pct_levels)

p_pct <- ggplot(pct, aes(x = group, y = value, fill = group)) +
  geom_col(width = 0.7, color = "grey20", linewidth = 0.3) +
  geom_segment(data = pct_bracket$segments, inherit.aes = FALSE,
               aes(x = x, xend = xend, y = y, yend = yend),
               linewidth = 0.35, color = "grey20") +
  geom_text(data = pct_bracket$labels, inherit.aes = FALSE,
            aes(x = x, y = y, label = label),
            family = "Arial", size = BODY_FS_NATIVE * 0.28,
            vjust = 0) +
  facet_wrap(~ feature, ncol = 5, scales = "fixed") +
  scale_fill_manual(values = grp_palette, guide = "none") +
  scale_y_continuous(limits = c(0, 205),
                     breaks = c(0, 25, 50, 75, 100),
                     expand = expansion(mult = c(0, 0.02))) +
  labs(x = NULL, y = "% of subgroup") +
  theme_esi() +
  theme(panel.grid.major.x = element_blank(),
        panel.grid.minor   = element_blank(),
        legend.position    = "none",
        axis.text.x        = element_text(angle = 45, hjust = 1))

# ---- Combine + single N annotation at bottom -----------------------------
# plot_annotation applies the caption once to the composite (not per subplot
# as `&` would).
fig <- (p_cont / p_pct) +
  plot_layout(heights = c(1, 1.1)) +
  plot_annotation(
    caption = paste0(n_annotation,
                     "\nSignificance: * p<0.05, ** p<0.01, *** p<0.001, ns = not significant.",
                     "\nTests: Wilcoxon rank-sum (continuous), chi-square (binary); unadjusted."),
    theme = theme(plot.caption = element_text(
      hjust = 0.5, family = "Arial",
      size = BODY_FS_NATIVE, face = "plain")))

OUT <- "figure2_discordance.png"
# Validate each sub-plot's readability floor.
validate_layout(p_cont, "figure2_discordance_A.png")
validate_layout(p_pct,  "figure2_discordance_B.png")

# Validate stacked-bracket geometry (label vs. next-tier line collision).
# Panel-height estimates account for the composite layout: total figure
# height NATIVE_W * 0.78 = 5.85 in, patchwork heights = c(1, 1.1), minus
# axis chrome (~1.0 in shared top/bottom). Top row = 1 facet-row tall,
# bottom row = 1 facet-row tall, both with y-scale that reaches the ymax
# passed to the validator (post-expansion).
CONT_YMAX <- list(
  ESI    = max((cont$value + cont$se)[cont$feature_key == "ESI"],    na.rm = TRUE) * 1.70 * 1.20,
  LAA950 = max((cont$value + cont$se)[cont$feature_key == "LAA950"], na.rm = TRUE) * 1.70 * 1.20)
PCT_YMAX  <- setNames(as.list(rep(205, length(pct_keys))), pct_keys)
# Approximate per-panel drawn height in inches (composite is 5.85 in tall,
# heights = c(1, 1.1) → top row ≈ 2.30 in tall including axis, bottom row
# ≈ 2.55 in; subtract ~0.80 in axis/labels chrome per row).
validate_significance_brackets(
  cont_bracket$segments, cont_bracket$labels,
  text_size_mm = BODY_FS_NATIVE * 0.28,
  facet_col = "feature_key",
  y_max_lookup = CONT_YMAX,
  panel_height_in = 1.50,
  out_path = "figure2_discordance_A.png")
validate_significance_brackets(
  pct_bracket$segments, pct_bracket$labels,
  text_size_mm = BODY_FS_NATIVE * 0.28,
  facet_col = "feature_key",
  y_max_lookup = PCT_YMAX,
  panel_height_in = 1.75,
  out_path = "figure2_discordance_B.png")

# Native aspect matched to a 7-panel layout with room for readable labels.
ggsave(OUT, fig, width = NATIVE_W, height = NATIVE_W * 0.78,
       dpi = 300, units = "in")
cat("Wrote:", OUT, "\n")
