#!/usr/bin/env Rscript
# Figure 1 — Concordance between the CT-based and ESI-based
# multidimensional-framework diagnostic categories.
#
# Left panel:   Alluvial (Sankey-style) plot of participant flow between
#               CT-based (Bhatt 2025) and ESI-based framework categories.
#               Ribbons colored by CT-based origin so a reader can trace
#               where each CT-based category is reclassified.
# Right panel:  Cross-classification matrix (CT-based rows x ESI-based
#               columns). Diagonal cells = concordant classifications
#               (blue tint), off-diagonal = discordant (red tint). Cell
#               opacity is proportional to count so large flows are
#               visually dominant.
#
# Data source: manuscript_assets/Table_6.csv (4x4 cross-tab; row = CT-based,
# column = ESI-based) + manuscript_assets/Table_Agreement_stats.txt.
# Output:      figures/figure1_agreement/figure1_agreement.png
#
# Style: sourced from ../style.R (fonts, palette). No fontsize literals here.

suppressPackageStartupMessages({
  library(dplyr); library(ggplot2); library(tidyr); library(ggalluvial)
  library(patchwork); library(forcats)
})
source("../style.R")
source("../validate_layout.R")

ASSETS <- "../../manuscript_assets"

# ---- Load ----------------------------------------------------------------
t6 <- read.csv(file.path(ASSETS, "Table_6.csv"),
                stringsAsFactors = FALSE, check.names = FALSE)
stats_lines <- readLines(file.path(ASSETS, "Table_Agreement_stats.txt"))
stats <- setNames(
  as.numeric(sub("^[^=]+=", "", stats_lines)),
  sub("=.*$", "", stats_lines)
)

# ---- Reshape to alluvial-long form ---------------------------------------
category_levels <- c("noCOPD", "AFL-only-noCOPD", "COPD-minor", "COPD-major")

col_map <- c(
  "noCOPD"          = "noCOPD",
  "AFL_only_NoCOPD" = "AFL-only-noCOPD",
  "COPD_minor"      = "COPD-minor",
  "COPD_major"      = "COPD-major"
)
row_map <- c(
  "noCOPD"          = "noCOPD",
  "AFL-only-NoCOPD" = "AFL-only-noCOPD",
  "COPD-minor"      = "COPD-minor",
  "COPD-major"      = "COPD-major"
)

flows <- t6 %>%
  rename(CT = Bhatt) %>%
  pivot_longer(-CT, names_to = "ESI", values_to = "count") %>%
  filter(count > 0) %>%
  mutate(CT  = factor(row_map[CT],  levels = category_levels),
         ESI = factor(col_map[ESI], levels = category_levels))

n_total <- sum(flows$count)
stopifnot(n_total == stats["n_cohort"])

# Wrap every category as a 2-line label so all four column headers have
# the same vertical footprint and their first lines align.
wrap_axis <- function(x) {
  x <- gsub("^noCOPD$",         "\nnoCOPD",       x)
  x <- gsub("AFL-only-noCOPD",  "AFL-only\nnoCOPD", x)
  x <- gsub("COPD-minor",       "COPD\nminor",    x)
  x <- gsub("COPD-major",       "COPD\nmajor",    x)
  x
}

# Stratum labels (inside blocks) also need to fit — abbreviate the two-word
# categories so they don't overflow the 0.42-wide blocks in panel A.
stratum_label <- function(cat) {
  vapply(cat, function(v) switch(as.character(v),
    "noCOPD"          = "noCOPD",
    "AFL-only-noCOPD" = "AFL-only",
    "COPD-minor"      = "minor",
    "COPD-major"      = "major",
    as.character(v)
  ), character(1))
}

# ---- Panel A: alluvial ---------------------------------------------------
LABEL_THRESHOLD <- 0.03 * n_total   # strata below this get no in-block label

p_all <- ggplot(flows,
                aes(axis1 = CT, axis2 = ESI, y = count)) +
  geom_alluvium(aes(fill = CT), width = 0.42, alpha = 0.75,
                curve_type = "sigmoid") +
  geom_stratum(aes(fill = after_stat(stratum)), width = 0.42,
               color = "grey20", linewidth = 0.15) +
  geom_text(stat = "stratum",
            aes(label = ifelse(after_stat(count) >= LABEL_THRESHOLD,
                                stratum_label(after_stat(stratum)), "")),
            family = "Arial", size = BODY_FS_NATIVE * 4.5 / 14,
            color = "white", fontface = "bold") +
  scale_x_discrete(limits = c("CT-based", "ESI-based"),
                   expand = expansion(add = c(0.18, 0.18)),
                   position = "top") +
  scale_fill_manual(values = PALETTE[category_levels], guide = "none",
                    drop = FALSE) +
  scale_y_continuous(expand = expansion(mult = c(0.02, 0.02))) +
  labs(x = NULL, y = NULL) +
  theme_esi() +
  theme(axis.text.x       = element_text(size = HEADER_FS_NATIVE,
                                          face = "plain"),
        axis.ticks.x      = element_blank(),
        axis.ticks.y      = element_blank(),
        axis.text.y       = element_blank(),
        axis.title.y      = element_blank(),
        panel.grid        = element_blank(),
        panel.background  = element_blank(),
        panel.border      = element_blank(),
        legend.position   = "none",
        plot.margin       = margin(4, 6, 4, 4))

# ---- Panel B: cross-classification matrix --------------------------------
# Rows = CT-based, columns = ESI-based. Diagonal cells (concordant) are
# colored using the project PALETTE keyed on the CT-based category — the
# same color a reader saw for that category in Panel A. Off-diagonal cells
# (discordant) are neutral white with a light border so the diagonal reads
# as the "highlighted" agreement structure. Cell fill uses scale_fill_identity
# so each cell can carry a distinct hex string without going through a scale.
#
# Complete the 4x4 grid: `flows` is derived post-`filter(count > 0)`, so
# without this expand_grid step Panel B would have 8 missing cells where
# CT×ESI combinations were absent from the cohort. We add the missing cells
# back with count = 0 so every discordance combination is visible.
matrix_df <- tidyr::expand_grid(
    CT  = factor(category_levels, levels = category_levels),
    ESI = factor(category_levels, levels = category_levels)
  ) %>%
  dplyr::left_join(flows %>% dplyr::select(CT, ESI, count),
                    by = c("CT", "ESI")) %>%
  tidyr::replace_na(list(count = 0)) %>%
  mutate(is_concordant = as.character(CT) == as.character(ESI),
         fill_hex      = ifelse(is_concordant,
                                 PALETTE[as.character(CT)],
                                 "#FFFFFF"))

p_cm <- ggplot(matrix_df,
               aes(x = ESI, y = fct_rev(CT))) +
  # Diagonal cells: colored + alpha ∝ count. Off-diagonal: white with light
  # border. Drawing all cells in one geom_tile keeps the grid layout intact.
  geom_tile(aes(fill = fill_hex,
                alpha = ifelse(is_concordant, count, NA)),
            color = "grey70", linewidth = 0.35) +
  geom_text(aes(label = formatC(count, format = "d", big.mark = ","),
                # Keep the count text readable on any diagonal fill: white on
                # the dark red COPD-major cell, black elsewhere.
                color = ifelse(is_concordant &
                                 as.character(CT) == "COPD-major",
                               "white", "grey15")),
            family = "Arial", size = BODY_FS_NATIVE * 4.5 / 14,
            fontface = "bold") +
  scale_fill_identity(guide = "none") +
  scale_color_identity(guide = "none") +
  scale_alpha_continuous(range = c(0.55, 1), na.value = 1, guide = "none") +
  scale_x_discrete(position = "top", labels = wrap_axis) +
  scale_y_discrete(labels = wrap_axis) +
  labs(x = "ESI-based", y = "CT-based") +
  theme_esi() +
  theme(panel.grid        = element_blank(),
        panel.background  = element_blank(),
        panel.border      = element_blank(),
        legend.position   = "none",
        axis.ticks        = element_blank(),
        axis.text.x       = element_text(size = BODY_FS_NATIVE * 0.92,
                                          lineheight = 0.9, vjust = 0),
        axis.text.y       = element_text(size = BODY_FS_NATIVE * 0.92,
                                          lineheight = 0.9),
        axis.title.x      = element_text(size = BODY_FS_NATIVE,
                                          face = "plain",
                                          margin = margin(t = 2)),
        axis.title.y      = element_text(size = BODY_FS_NATIVE,
                                          face = "plain",
                                          margin = margin(r = 2)),
        plot.margin       = margin(4, 4, 4, 6))

# ---- Compose -------------------------------------------------------------
fig_combined <- p_all + p_cm +
  patchwork::plot_layout(widths = c(1.15, 1)) +
  patchwork::plot_annotation(
    tag_levels = "A",
    theme = theme(plot.tag = element_text(family = "Arial",
                                           size = HEADER_FS_NATIVE,
                                           face = "bold"))
  )

# ---- Validate + save ------------------------------------------------------
OUT <- "figure1_agreement.png"
# validate_layout expects a single ggplot; run it on each panel.
validate_layout(p_all, paste0("_panelA_", OUT))
validate_layout(p_cm,  paste0("_panelB_", OUT))
ggsave(OUT, fig_combined,
       width = NATIVE_W, height = NATIVE_W * 0.55,
       dpi = 300, units = "in")
cat("Wrote:", OUT, "\n")
