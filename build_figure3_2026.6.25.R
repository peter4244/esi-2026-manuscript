#!/usr/bin/env Rscript
# Figure 3 — Cause-specific mortality forest plot by classification × schema.
suppressPackageStartupMessages({
  library(dplyr); library(ggplot2); library(scales)
})

OUT_DIR <- "/Users/petecastaldi/claude_projects/projects/ESI_2024/manuscript_assets"

# Load already-computed table
t_cs <- read.csv(file.path(OUT_DIR, "Table_CauseSpecific_byClass.csv"),
                 stringsAsFactors = FALSE, check.names = FALSE)

# Reshape: one row per (cause, group, schema)
forest_df <- bind_rows(
  t_cs %>% transmute(cause, group, schema = "Bhatt (with CT)",
                     HR = bhatt_HR, LCI = bhatt_LCI, UCI = bhatt_UCI,
                     n_events = n_events_bhatt, p = bhatt_p),
  t_cs %>% transmute(cause, group, schema = "ESI-substituted (no CT)",
                     HR = esi_HR, LCI = esi_LCI, UCI = esi_UCI,
                     n_events = n_events_esi, p = esi_p)
)

# Order groups: AFL-only at bottom (small), COPD-minor middle, COPD-major top
forest_df$group <- factor(forest_df$group,
                          levels = rev(c("COPD-major","COPD-minor","AFL-only-NoCOPD")))
forest_df$cause <- factor(forest_df$cause, levels = c("CVD","Cancer","Other"))

# Cap UCI for AFL-only-NoCOPD to keep the plot readable (note in caption)
forest_df$UCI_plot <- pmin(forest_df$UCI, 12, na.rm = TRUE)
forest_df$LCI_plot <- pmax(forest_df$LCI, 0.1, na.rm = TRUE)

fig3 <- ggplot(forest_df,
               aes(x = HR, y = group, color = schema)) +
  geom_vline(xintercept = 1, linetype = "dashed", color = "grey60") +
  geom_errorbarh(aes(xmin = LCI_plot, xmax = UCI_plot),
                 position = position_dodge(width = 0.5),
                 height = 0.25, linewidth = 0.6) +
  geom_point(position = position_dodge(width = 0.5), size = 2.7) +
  facet_wrap(~ cause, ncol = 3, scales = "fixed") +
  scale_x_log10(breaks = c(0.5, 1, 2, 5, 10),
                limits = c(0.3, 12)) +
  scale_color_manual(values = c("Bhatt (with CT)" = "#1F77B4",
                                "ESI-substituted (no CT)" = "#D62728"),
                     name = NULL) +
  labs(x = "Cause-specific mortality HR (95% CI, log scale)",
       y = NULL,
       title = "Cause-specific mortality by Bhatt category: head-to-head Bhatt vs ESI-substituted",
       subtitle = "Reference category: noCOPD.  Covariates: age, sex, race, current smoking, pack-years, BMI.") +
  theme_bw(base_family = "Arial", base_size = 10) +
  theme(legend.position = "bottom",
        panel.grid.minor = element_blank(),
        strip.background = element_blank(),
        strip.text = element_text(face = "plain", size = 11),
        plot.subtitle = element_text(size = 9, color = "grey30"))

ggsave(file.path(OUT_DIR, "Figure_CauseSpecific_byClass.png"),
       fig3, width = 12, height = 4.5, dpi = 300)

cat("Wrote: Figure_CauseSpecific_byClass.png\n")
