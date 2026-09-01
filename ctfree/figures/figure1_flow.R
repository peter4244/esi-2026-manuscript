#!/usr/bin/env Rscript
# Figure 1 (draft) — what happens to the MD-COPD classification when CT is
# removed, by two different routes.
#
# MD-COPD with CT sits in the middle as the reference, with the two CT-free
# schemas flowing outward on either side. Ribbons are colored by the middle
# axis, so each MD-COPD category can be traced in both directions at once and
# the two alternatives are compared against the same anchor rather than against
# each other.
#
# The comparison the figure exists to make: the COPD-major ribbon splits
# heavily into AFL-only-noCOPD on the left, where the structural criterion is
# simply dropped, and much less so on the right, where ESI stands in for it.
#
# MOCKUP STAGE: relaxed rigor, no validator gate yet.
suppressPackageStartupMessages({
  library(dplyr); library(ggplot2); library(ggalluvial)
})
.b <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
HERE <- if (length(.b)) dirname(normalizePath(sub("^--file=", "", .b[1]))) else "ctfree/figures"
source(file.path(dirname(dirname(HERE)), "figures", "style.R"))
ASSETS <- file.path(dirname(HERE), "assets")

S <- readRDS(file.path(ASSETS, "schema_labels.rds"))
O <- c("noCOPD", "AFL-only", "COPD-minor", "COPD-major")
PAL <- c("noCOPD" = "#7F7F7F", "AFL-only" = "#9467BD",
         "COPD-minor" = "#FFB000", "COPD-major" = "#D62728")

df <- S %>%
  count(without_CT = factor(S3, levels = O),
        md_copd    = factor(S2, levels = O),
        with_ESI   = factor(S4, levels = O))

lost_left  <- sum(S$S2 == "COPD-major" & S$S3 == "AFL-only")
lost_right <- sum(S$S2 == "COPD-major" & S$S4 == "AFL-only")
conc_left  <- sum(S$S2 == S$S3); conc_right <- sum(S$S2 == S$S4)
n <- nrow(S)

p <- ggplot(df, aes(y = n, axis1 = without_CT, axis2 = md_copd, axis3 = with_ESI)) +
  geom_alluvium(aes(fill = md_copd), width = 0.22, alpha = 0.62, knot.pos = 0.3) +
  geom_stratum(width = 0.22, fill = "white", color = "grey35", linewidth = 0.3) +
  geom_text(stat = "stratum", aes(label = after_stat(stratum)),
            size = BODY_FS_NATIVE / .pt * 0.68, family = "Arial") +
  scale_x_discrete(limits = c("MD-COPD without CT", "MD-COPD with CT",
                              "MD-COPD with ESI"),
                   expand = expansion(mult = c(0.10, 0.10))) +
  scale_y_continuous(labels = function(v) format(v, big.mark = ",")) +
  scale_fill_manual(values = PAL, guide = "none") +
  labs(y = "Participants",
       subtitle = sprintf(
         "Concordant with MD-COPD: %s of %s without CT (%.1f%%), %s with ESI (%.1f%%)",
         format(conc_left, big.mark = ","), format(n, big.mark = ","),
         100 * conc_left / n, format(conc_right, big.mark = ","), 100 * conc_right / n),
       caption = sprintf(
         "COPD-major reclassified as AFL-only-noCOPD: %d without CT, %d with ESI",
         lost_left, lost_right)) +
  theme_esi() +
  theme(axis.title.x = element_blank(),
        panel.grid.major.x = element_blank(),
        panel.grid.minor = element_blank(),
        plot.caption = element_text(hjust = 0.5, size = BODY_FS_NATIVE),
        # The outer axis labels are wider than their strata and were clipping
        # at the panel edge; give the plot room rather than shrinking the text.
        plot.margin = margin(4, 20, 4, 4))

out <- file.path(HERE, "figure1_flow.png")
ggsave(out, p, width = NATIVE_W, height = 5.0, dpi = 300, bg = "white")
cat(sprintf("wrote %s  (COPD-major lost: %d without CT, %d with ESI)\n",
            out, lost_left, lost_right))
