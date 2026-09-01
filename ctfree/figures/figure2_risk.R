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

risk <- read.csv(file.path(ASSETS, "schema_risk.csv"),  stringsAsFactors = FALSE)
crd  <- read.csv(file.path(ASSETS, "schema_crude.csv"), stringsAsFactors = FALSE)
SCH <- c(S1 = "1  Fixed ratio", S2 = "2  MD-COPD with CT",
         S3 = "3  without CT", S4 = "4  with ESI")
OUTC <- list(c("all", "All-cause mortality", "Hazard ratio"),
             c("resp", "Respiratory mortality", "Hazard ratio"),
             c("exac", "Exacerbations", "Incidence-rate ratio"))
# Crude and adjusted on one scale. An adjusted estimate is what the
# classification adds beyond the covariates; the crude ratio is what people in
# that category actually experienced, and for the AFL-only-noCOPD label the
# crude value is the one that decides whether the label is honest.
long <- do.call(rbind, lapply(OUTC, function(o) {
  est <- if (o[1] == "exac") "exac_IRR" else paste0(o[1], "_HR")
  d <- risk[!is.na(risk[[est]]) & risk$category != "noCOPD", ]
  adj <- data.frame(schema = SCH[d$schema], category = d$category,
             est = d[[est]], lo = d[[paste0(o[1], "_LCI")]], hi = d[[paste0(o[1], "_UCI")]],
             outcome = o[2], type = "Adjusted", stringsAsFactors = FALSE)
  k <- crd[crd$outcome == o[1] & crd$category != "noCOPD" & !is.na(crd$rr), ]
  cru <- data.frame(schema = SCH[k$schema], category = k$category,
             est = k$rr, lo = k$lo, hi = k$hi,
             outcome = o[2], type = "Crude", stringsAsFactors = FALSE)
  rbind(cru, adj) }))
long$type <- factor(long$type, levels = c("Crude", "Adjusted"))
# A crude lower bound of exactly zero is a real result: it marks a category in
# which a resample can contain no events at all. It cannot be drawn on a log
# axis, so it is clamped to the panel floor and flagged with an arrow rather
# than silently dropped.
long$open_lo <- !is.na(long$lo) & long$lo <= 0
long$lo <- ifelse(long$open_lo, NA_real_, long$lo)
long$outcome  <- factor(long$outcome, levels = vapply(OUTC, `[`, "", 2))
long$schema   <- factor(long$schema, levels = rev(SCH))
long$category <- factor(long$category,
                        levels = c("COPD", "COPD-major", "COPD-minor", "AFL-only"))
PAL <- c("COPD" = "#1F77B4", "AFL-only" = "#9467BD",
         "COPD-minor" = "#FFB000", "COPD-major" = "#D62728")

pd <- position_dodge(width = 0.78)
p <- ggplot(long, aes(x = est, y = schema, color = category,
                      shape = type, group = interaction(category, type))) +
  geom_vline(xintercept = 1, linetype = 2, color = "grey45", linewidth = 0.4) +
  geom_linerange(aes(xmin = lo, xmax = hi), linewidth = 0.5, position = pd,
                 data = subset(long, !open_lo)) +
  geom_segment(aes(x = hi, xend = est / 12, y = schema, yend = schema),
               data = subset(long, open_lo), linewidth = 0.5, position = pd,
               arrow = arrow(length = unit(0.055, "in"), type = "open")) +
  geom_point(size = 2.0, position = pd, fill = "white", stroke = 0.7) +
  scale_shape_manual(values = c(Crude = 21, Adjusted = 19), name = NULL) +
  # A single break vector collides in the respiratory panel, whose range spans
  # two orders of magnitude more than the others. Let each free panel choose.
  scale_x_log10(breaks = scales::breaks_log(n = 5), labels = scales::label_number(drop0trailing = TRUE)) +
  scale_color_manual(values = PAL, name = NULL,
                     breaks = c("COPD", "AFL-only", "COPD-minor", "COPD-major")) +
  guides(color = guide_legend(order = 1), shape = guide_legend(order = 2)) +
  facet_wrap(~ outcome, ncol = 3, scales = "free_x") +
  labs(x = "Ratio versus that schema's own noCOPD reference (log scale)", y = NULL) +
  theme_esi() +
  theme(legend.position = "bottom", legend.box = "vertical",
        legend.margin = margin(0, 0, 0, 0), legend.spacing.y = unit(1, "pt"),
        panel.grid.minor = element_blank(),
        panel.grid.major.y = element_blank(),
        plot.margin = margin(4, 10, 4, 4))

out <- file.path(HERE, "figure2_risk.png")
ggsave(out, p, width = NATIVE_W, height = 4.8, dpi = 300, bg = "white")
cat("wrote", out, "\n")
