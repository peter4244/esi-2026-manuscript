#!/usr/bin/env Rscript
# Figure 1 (draft) — where participants move when CT is removed.
#
# Two panels rather than one three-axis alluvial, because schema 3 and schema 4
# are alternatives to each other, not sequential steps. Side by side, the
# comparison a reader needs is the one the eye makes automatically: schema 3
# empties a quarter of COPD-major into AFL-only-noCOPD, schema 4 does not.
#
# Ribbons are colored by MD-COPD origin so each source category can be traced.
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

panel <- function(target, right_label, tag) {
  df <- S %>% count(from = factor(S2, levels = O), to = factor(.data[[target]], levels = O))
  kept <- sum(df$n[df$from == df$to]); tot <- sum(df$n)
  ggplot(df, aes(y = n, axis1 = from, axis2 = to)) +
    geom_alluvium(aes(fill = from), width = 0.28, alpha = 0.65, knot.pos = 0.28) +
    geom_stratum(width = 0.28, fill = "white", color = "grey35", linewidth = 0.3) +
    geom_text(stat = "stratum", aes(label = after_stat(stratum)),
              size = BODY_FS_NATIVE / .pt * 0.72, family = "Arial") +
    scale_x_discrete(limits = c("MD-COPD with CT", right_label), expand = c(0.16, 0.05)) +
    scale_fill_manual(values = PAL, guide = "none") +
    labs(tag = tag, y = "Participants",
         subtitle = sprintf("%s of %s unchanged (%.1f%%)",
                            format(kept, big.mark = ","), format(tot, big.mark = ","),
                            100 * kept / tot)) +
    theme_esi() +
    theme(axis.title.x = element_blank(),
          panel.grid.major.x = element_blank(),
          panel.grid.minor = element_blank(),
          # The right-hand axis label overran the panel; give it room rather
          # than shrinking the text below the docx readability floor.
          plot.margin = margin(4, 14, 4, 4))
}

a <- panel("S3", "MD-COPD without CT", "A")
b <- panel("S4", "MD-COPD with ESI",  "B")

# The single number the figure exists to show.
lost <- sum(S$S2 == "COPD-major" & S$S3 == "AFL-only")
kept <- sum(S$S2 == "COPD-major" & S$S4 == "AFL-only")
a <- a + labs(caption = sprintf("%d COPD-major reclassified as AFL-only-noCOPD", lost))
b <- b + labs(caption = sprintf("%d COPD-major reclassified as AFL-only-noCOPD", kept))

p <- a + b + plot_layout(ncol = 2)
out <- file.path(HERE, "figure1_flow.png")
ggsave(out, p, width = NATIVE_W, height = 4.6, dpi = 300, bg = "white")
cat("wrote", out, "  (", lost, "vs", kept, "COPD-major lost )\n")
