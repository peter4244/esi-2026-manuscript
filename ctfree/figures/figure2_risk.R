#!/usr/bin/env Rscript
# Figures 2 to 4 — one per outcome, faceted by diagnostic category.
#
# A single figure holding every classification, every category and both
# estimate types was unreadable: 32 intervals per panel. These split it.
#
# Cut by OUTCOME rather than by category so that each figure answers one
# clinical question across all four categories at once, and so the three
# figures are directly comparable to each other: same panels, same rows, only
# the outcome changes. Cutting by category instead put the three outcomes on
# different x scales within a figure, which invited comparisons across panels
# that the scales did not support.
#
# Reference is that classification's own noCOPD group throughout. The fixed
# ratio has a single COPD category, so it appears only in the COPD-major
# facet, the category it corresponds to.
suppressPackageStartupMessages({ library(dplyr); library(ggplot2) })
.b <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
HERE <- if (length(.b)) dirname(normalizePath(sub("^--file=", "", .b[1]))) else "ctfree/figures"
source(file.path(dirname(dirname(HERE)), "figures", "style.R"))
source(file.path(dirname(dirname(HERE)), "figures", "validate_layout.R"))
ASSETS <- file.path(dirname(HERE), "assets")

risk <- read.csv(file.path(ASSETS, "schema_risk.csv"),  stringsAsFactors = FALSE)
crd  <- read.csv(file.path(ASSETS, "schema_crude.csv"), stringsAsFactors = FALSE)
SCH  <- c(S1 = "Fixed ratio", S2 = "MD-COPD",
          S3 = "NoCT-MD-COPD", S4 = "ESI-MD-COPD")
OUTC <- list(c("all", "All-cause mortality"), c("resp", "Respiratory mortality"),
             c("exac", "Exacerbations"))
# Facets are the categories; the fixed ratio contributes only to COPD-major.
CATS <- list(c("AFL-only", "S2,S3,S4"), c("COPD-minor", "S2,S3,S4"),
             c("COPD-major", "S1,S2,S3,S4"))
PAL  <- c("AFL-only" = "#9467BD", "COPD-minor" = "#FFB000", "COPD-major" = "#D62728")

gather_outcome <- function(o_key) {
  est <- if (o_key == "exac") "exac_IRR" else paste0(o_key, "_HR")
  do.call(rbind, lapply(CATS, function(cc) {
    cat_wanted <- cc[1]; schemas <- strsplit(cc[2], ",")[[1]]
    want <- if (cat_wanted == "COPD-major") c("COPD-major", "COPD") else cat_wanted
    a <- risk[risk$schema %in% schemas & risk$category %in% want & !is.na(risk[[est]]), ]
    k <- crd[crd$schema %in% schemas & crd$outcome == o_key &
             crd$category %in% want & !is.na(crd$rr), ]
    rbind(
      data.frame(schema = SCH[k$schema], est = k$rr, lo = k$lo, hi = k$hi,
                 cat = cat_wanted, type = "Crude", stringsAsFactors = FALSE),
      data.frame(schema = SCH[a$schema], est = a[[est]],
                 lo = a[[paste0(o_key, "_LCI")]], hi = a[[paste0(o_key, "_UCI")]],
                 cat = cat_wanted, type = "Adjusted", stringsAsFactors = FALSE))
  }))
}

make_fig <- function(o_key, o_label, file) {
  d <- gather_outcome(o_key)
  d$cat    <- factor(d$cat, levels = vapply(CATS, `[`, "", 1))
  d$schema <- factor(d$schema, levels = rev(unname(SCH)))
  d$type   <- factor(d$type, levels = c("Crude", "Adjusted"))
  # A lower bound of exactly zero is a real result, a category in which a
  # resample can contain no events. It cannot sit on a log axis, so it is
  # drawn as an open-ended interval rather than dropped.
  d$open_lo <- !is.na(d$lo) & d$lo <= 0
  d$lo[d$open_lo] <- NA_real_
  # One x scale across the facets, so the arrow target is computed once and
  # reads as a convention rather than a data value.
  d$arrow_to <- min(c(d$lo, d$est), na.rm = TRUE) * 0.75
  # Both layers must carry every row: position_dodge assigns offsets from the
  # group levels present in a layer, so a subsetted layer dodges to a different
  # place than the full ones and the cap lands on the wrong row.
  d$draw_lo <- ifelse(d$open_lo, d$arrow_to, d$lo)
  d$cap_x   <- ifelse(d$open_lo, d$arrow_to, NA_real_)
  # An empty facet renders without error and says nothing. Assert instead.
  stopifnot(all(vapply(levels(d$cat), function(l) sum(d$cat == l) > 0, logical(1))))
  pd <- position_dodge(width = 0.55)
  p <- ggplot(d, aes(x = est, y = schema, shape = type, group = type)) +
    geom_vline(xintercept = 1, linetype = 2, color = "grey45", linewidth = 0.4) +
    geom_linerange(aes(xmin = draw_lo, xmax = hi, color = cat), linewidth = 0.6,
                   position = pd, na.rm = TRUE) +
    geom_point(aes(x = cap_x, color = cat), shape = 60, size = 2.4, stroke = 0.9,
               position = pd, na.rm = TRUE) +
    geom_point(aes(color = cat), size = 2.6, position = pd,
               fill = "white", stroke = 0.9) +
    scale_shape_manual(values = c(Crude = 21, Adjusted = 19), name = NULL) +
    scale_color_manual(values = PAL, guide = "none") +
    facet_wrap(~ cat, ncol = 3) +
    labs(x = sprintf("%s: ratio versus that classification's own noCOPD group (log scale)",
                     o_label), y = NULL) +
    theme_esi() +
    theme(legend.position = "bottom",
          legend.margin = margin(t = -2, b = 0),
          panel.grid.minor = element_blank(),
          panel.grid.major.y = element_blank(),
          plot.margin = margin(4, 20, 2, 4)) +
    # Respiratory intervals reach ~90, so the upper end of the log scale runs
    # into the border unless the panel is given explicit headroom. Expanding
    # the scale rather than the margin keeps the three figures the same size.
    scale_x_log10(breaks = scales::breaks_log(n = 5),
                  labels = scales::label_number(drop0trailing = TRUE),
                  expand = expansion(mult = c(0.06, 0.12)))
  out <- file.path(HERE, file)
  # Every text element must still clear the docx readability floor once the
  # figure is scaled to the 6.5 inch content width. Errors rather than warns.
  validate_layout(p, out)
  ggsave(out, p, width = NATIVE_W, height = 2.9, dpi = 300, bg = "white")
  cat("wrote", out, "\n")
}

make_fig("all",  "All-cause mortality",   "figure2_allcause.png")
make_fig("resp", "Respiratory mortality", "figure3_respiratory.png")
make_fig("exac", "Exacerbations",         "figure4_exacerbations.png")
