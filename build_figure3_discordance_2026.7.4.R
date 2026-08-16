#!/usr/bin/env Rscript
# Figure 3 — Discordance-subgroup comparison across 7 features (Massimo's ask, 2026-07-04).
# Groups: Bhatt-only-COPD, Both-COPD, ESI-only-COPD.
# Features: ESI, %LAA-950HU, visual emphysema (%), wall thickening (%),
#           mMRC>=2 (%), SGRQ>=25 (%), chronic bronchitis (%).
suppressPackageStartupMessages({library(dplyr); library(ggplot2); library(tidyr); library(scales)})

OUT_DIR <- "/Users/petecastaldi/claude_projects/projects/ESI_2024/manuscript_assets"
disc <- read.csv(file.path(OUT_DIR, "Table_Discordance.csv"), stringsAsFactors = FALSE, check.names = FALSE)

# Numeric extractor for "mean (sd)" cells
mean_of <- function(x) as.numeric(sub("\\s*\\(.*", "", x))
pct_of  <- function(x) as.numeric(sub("%", "", x))

disc_num <- disc %>%
  mutate(
    ESI     = mean_of(ESI),
    LAA950  = mean_of(LAA950),
    emph    = pct_of(pct_emph),
    wall    = pct_of(pct_wall),
    mMRC2p  = pct_of(pct_mMRC2p),
    SGRQ25p = pct_of(pct_SGRQ25p),
    CB      = pct_of(pct_CB)
  )

lvl <- c("Bhatt-only-COPD (ESI missed)","Both-COPD","ESI-only-COPD (Bhatt missed)")
disc_num$grp_5 <- factor(disc_num$grp_5, levels = lvl)
disc_num$grp_short <- recode(as.character(disc_num$grp_5),
  "Bhatt-only-COPD (ESI missed)"       = "Bhatt-only\n(n=546)",
  "Both-COPD"                          = "Both\n(n=553)",
  "ESI-only-COPD (Bhatt missed)"       = "ESI-only\n(n=95)")
disc_num$grp_short <- factor(disc_num$grp_short,
  levels = c("Bhatt-only\n(n=546)","Both\n(n=553)","ESI-only\n(n=95)"))

# Long form for continuous features (ESI, LAA950)
cont <- disc_num %>%
  select(grp_short, ESI, LAA950) %>%
  pivot_longer(-grp_short, names_to = "feature", values_to = "value") %>%
  mutate(feature = recode(feature, ESI = "ESI", LAA950 = "%LAA-950HU"))
cont$feature <- factor(cont$feature, levels = c("ESI","%LAA-950HU"))

# Long form for percentage features
pct <- disc_num %>%
  select(grp_short, emph, wall, mMRC2p, SGRQ25p, CB) %>%
  pivot_longer(-grp_short, names_to = "feature", values_to = "value") %>%
  mutate(feature = recode(feature,
    emph    = "Visual emphysema (any)",
    wall    = "Visual wall thickening",
    mMRC2p  = "mMRC ≥ 2",
    SGRQ25p = "SGRQ ≥ 25",
    CB      = "Chronic bronchitis"))
pct$feature <- factor(pct$feature, levels = c(
  "Visual emphysema (any)","Visual wall thickening",
  "mMRC ≥ 2","SGRQ ≥ 25","Chronic bronchitis"))

# Color palette — three subgroups
pal <- c("Bhatt-only\n(n=546)" = "#1F77B4",
         "Both\n(n=553)"       = "#7F7F7F",
         "ESI-only\n(n=95)"    = "#D62728")

p_cont <- ggplot(cont, aes(x = grp_short, y = value, fill = grp_short)) +
  geom_col(width = 0.7, color = "grey20", linewidth = 0.3) +
  geom_text(aes(label = sprintf("%.2f", value)),
            vjust = -0.4, size = 3.1, family = "Arial") +
  facet_wrap(~ feature, ncol = 2, scales = "free_y") +
  scale_fill_manual(values = pal, guide = "none") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.18))) +
  labs(x = NULL, y = "Mean") +
  theme_bw(base_family = "Arial", base_size = 10) +
  theme(strip.background = element_blank(),
        strip.text = element_text(face = "plain", size = 10),
        panel.grid.minor = element_blank(),
        panel.grid.major.x = element_blank(),
        axis.text.x = element_text(size = 8.5))

p_pct <- ggplot(pct, aes(x = grp_short, y = value, fill = grp_short)) +
  geom_col(width = 0.7, color = "grey20", linewidth = 0.3) +
  geom_text(aes(label = sprintf("%.0f%%", value)),
            vjust = -0.4, size = 3.1, family = "Arial") +
  facet_wrap(~ feature, ncol = 5, scales = "fixed") +
  scale_fill_manual(values = pal, guide = "none") +
  scale_y_continuous(limits = c(0, 105), expand = expansion(mult = c(0, 0))) +
  labs(x = NULL, y = "% of subgroup") +
  theme_bw(base_family = "Arial", base_size = 10) +
  theme(strip.background = element_blank(),
        strip.text = element_text(face = "plain", size = 10),
        panel.grid.minor = element_blank(),
        panel.grid.major.x = element_blank(),
        axis.text.x = element_text(size = 8.5))

# Combine — use cowplot if available, otherwise patchwork, otherwise save separately.
combined <- tryCatch({
  library(patchwork)
  (p_cont / p_pct) + plot_layout(heights = c(1, 1.15))
}, error = function(e) NULL)

if (!is.null(combined)) {
  ggsave(file.path(OUT_DIR, "Figure_3_Discordance.png"),
         combined, width = 11, height = 7, dpi = 300)
  cat("Wrote: Figure_3_Discordance.png (combined)\n")
} else {
  ggsave(file.path(OUT_DIR, "Figure_3_Discordance_cont.png"),
         p_cont, width = 6, height = 3.2, dpi = 300)
  ggsave(file.path(OUT_DIR, "Figure_3_Discordance_pct.png"),
         p_pct,  width = 11, height = 3.5, dpi = 300)
  cat("Wrote: Figure_3_Discordance_cont.png + Figure_3_Discordance_pct.png\n")
}
