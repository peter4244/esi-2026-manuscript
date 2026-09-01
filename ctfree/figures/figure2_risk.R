#!/usr/bin/env Rscript
# Figure 2 (draft) — do the category labels mean what they say?
#
# The point of AFL-only-noCOPD is to identify people the fixed ratio calls COPD
# who do not have it. A schema is only usable if that category is genuinely low
# risk. Plotting every schema's categories on one axis makes the failure
# visible: without CT, AFL-only-noCOPD carries clearly elevated respiratory
# mortality and exacerbation risk, so the label is false. With ESI it does not.
#
# MOCKUP STAGE: relaxed rigor, no validator gate yet.
suppressPackageStartupMessages({ library(dplyr); library(ggplot2) })
.b <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
HERE <- if (length(.b)) dirname(normalizePath(sub("^--file=", "", .b[1]))) else "ctfree/figures"
source(file.path(dirname(dirname(HERE)), "figures", "style.R"))
ASSETS <- file.path(dirname(HERE), "assets")

risk <- read.csv(file.path(ASSETS, "schema_risk.csv"), stringsAsFactors = FALSE)
SCH <- c(S1 = "1  Fixed ratio", S2 = "2  MD-COPD with CT",
         S3 = "3  without CT", S4 = "4  with ESI")
OUTC <- list(c("all", "All-cause mortality", "Hazard ratio"),
             c("resp", "Respiratory mortality", "Hazard ratio"),
             c("exac", "Exacerbations", "Incidence-rate ratio"))
long <- do.call(rbind, lapply(OUTC, function(o) {
  est <- if (o[1] == "exac") "exac_IRR" else paste0(o[1], "_HR")
  d <- risk[!is.na(risk[[est]]), ]
  data.frame(schema = SCH[d$schema], category = d$category,
             est = d[[est]], lo = d[[paste0(o[1], "_LCI")]], hi = d[[paste0(o[1], "_UCI")]],
             outcome = o[2], stringsAsFactors = FALSE) }))
long$outcome  <- factor(long$outcome, levels = vapply(OUTC, `[`, "", 2))
long$schema   <- factor(long$schema, levels = rev(SCH))
long$category <- factor(long$category,
                        levels = c("COPD", "COPD-major", "COPD-minor", "AFL-only"))
PAL <- c("COPD" = "#1F77B4", "AFL-only" = "#9467BD",
         "COPD-minor" = "#FFB000", "COPD-major" = "#D62728")

p <- ggplot(long, aes(x = est, y = schema, color = category)) +
  geom_vline(xintercept = 1, linetype = 2, color = "grey45", linewidth = 0.4) +
  geom_errorbarh(aes(xmin = lo, xmax = hi), height = 0.22, linewidth = 0.55,
                 position = position_dodge(width = 0.72)) +
  geom_point(size = 2.1, position = position_dodge(width = 0.72)) +
  # A single break vector collides in the respiratory panel, whose range spans
  # two orders of magnitude more than the others. Let each free panel choose.
  scale_x_log10(breaks = scales::breaks_log(n = 5), labels = scales::label_number(drop0trailing = TRUE)) +
  scale_color_manual(values = PAL, name = NULL,
                     breaks = c("COPD", "AFL-only", "COPD-minor", "COPD-major")) +
  facet_wrap(~ outcome, ncol = 3, scales = "free_x") +
  labs(x = "Ratio versus that schema's own noCOPD reference (log scale)", y = NULL) +
  theme_esi() +
  theme(legend.position = "bottom", panel.grid.minor = element_blank(),
        panel.grid.major.y = element_blank())

out <- file.path(HERE, "figure2_risk.png")
ggsave(out, p, width = NATIVE_W, height = 4.2, dpi = 300, bg = "white")
cat("wrote", out, "\n")
