#!/usr/bin/env Rscript
# Figures 2 to 4 — one per outcome, faceted by diagnostic category.
#
# One figure per diagnostic group, matching how the Results paragraphs are
# organized: each paragraph takes one group through all three outcomes across
# the three classifications, and each figure shows exactly that.
#
# The three outcomes sit on very different scales (respiratory rate ratios
# reach 80 where all-cause reaches 4), so the panels carry free x scales. The
# comparison the figure exists to support is between classifications within a
# panel, which a free scale preserves; comparing across panels was never
# meaningful for these outcomes and a shared scale would only have made the
# all-cause panel unreadable.
#
# Reference is the common noCOPD group throughout: the participants all three
# multidimensional classifications assign to noCOPD. Per-classification
# references differ in composition, so estimates made against them are not
# comparable between classifications, which is the comparison these figures
# exist to support. The fixed ratio is not shown; its comparison with the
# multidimensional framework is the source report's question, not this one.
suppressPackageStartupMessages({ library(dplyr); library(ggplot2) })
.b <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
HERE <- if (length(.b)) dirname(normalizePath(sub("^--file=", "", .b[1]))) else "ctfree/figures"
source(file.path(dirname(dirname(HERE)), "figures", "style.R"))
source(file.path(dirname(dirname(HERE)), "figures", "validate_layout.R"))
ASSETS <- file.path(dirname(HERE), "assets")

risk <- read.csv(file.path(ASSETS, "consensus_ref_risk.csv"),  stringsAsFactors = FALSE)
crd  <- read.csv(file.path(ASSETS, "consensus_ref_crude.csv"), stringsAsFactors = FALSE)
SCH  <- c(S2 = "MD-COPD", S3 = "NoCT-MD-COPD", S4 = "ESI-MD-COPD")
OUTC <- list(c("all", "All-cause mortality"), c("resp", "Respiratory mortality"),
             c("exac", "Exacerbations"))
GRPS <- c("AFL-only", "COPD-minor", "COPD-major")
PAL  <- c("AFL-only" = "#9467BD", "COPD-minor" = "#FFB000", "COPD-major" = "#D62728")

gather_group <- function(grp) {
  do.call(rbind, lapply(OUTC, function(oo) {
    o_key <- oo[1]; o_label <- oo[2]
    est <- if (o_key == "exac") "exac_IRR" else paste0(o_key, "_HR")
    lci <- if (o_key == "exac") "exac_LCI" else paste0(o_key, "_LCI")
    uci <- if (o_key == "exac") "exac_UCI" else paste0(o_key, "_UCI")
    flg <- if (o_key == "exac") "all_few_events" else paste0(o_key, "_few_events")
    a <- risk[risk$category == grp, ]
    k <- crd[crd$category == grp & crd$outcome == o_key, ]
    stopifnot(nrow(a) == length(SCH), nrow(k) == length(SCH))
    rbind(
      data.frame(schema = SCH[a$schema], est = a[[est]], lo = a[[lci]],
                 hi = a[[uci]], few = a[[flg]], outcome = o_label,
                 type = "Adjusted", stringsAsFactors = FALSE),
      data.frame(schema = SCH[k$schema], est = k$rr, lo = k$lo, hi = k$hi,
                 few = k$few_events, outcome = o_label,
                 type = "Crude", stringsAsFactors = FALSE))
  }))
}

make_fig <- function(grp, file) {
  d <- gather_group(grp)
  d$outcome <- factor(d$outcome, levels = vapply(OUTC, `[`, "", 2))
  # MD-COPD and ESI-MD-COPD sit adjacent because the Results paragraphs pair
  # them and contrast NoCT-MD-COPD against the pair. Reversed because ggplot
  # draws the first factor level at the bottom.
  d$schema  <- factor(d$schema, levels = rev(unname(SCH[c("S2", "S4", "S3")])))
  d$type    <- factor(d$type, levels = c("Crude", "Adjusted"))
  # A group with fewer than 10 events carries a point estimate but no
  # interval, drawn as a bare point so the eye does not read an interval that
  # was deliberately not computed. The adjusted model still returns one; it is
  # dropped for the same reason, so both estimate types follow one rule.
  d$few <- !is.na(d$few) & d$few
  d$lo[d$few] <- NA_real_; d$hi[d$few] <- NA_real_
  stopifnot(!any(is.na(d$lo[!d$few])), !any(is.na(d$est)))
  # An empty facet renders without error and says nothing. Assert instead.
  stopifnot(all(vapply(levels(d$outcome), function(l) sum(d$outcome == l) > 0,
                       logical(1))))
  pd <- position_dodge(width = 0.55)
  p <- ggplot(d, aes(x = est, y = schema, shape = type, group = type)) +
    geom_vline(xintercept = 1, linetype = 2, color = "grey45", linewidth = 0.4) +
    geom_linerange(aes(xmin = lo, xmax = hi), color = PAL[[grp]],
                   linewidth = 0.6, position = pd, na.rm = TRUE) +
    geom_point(color = PAL[[grp]], size = 2.6, position = pd,
               fill = "white", stroke = 0.9) +
    scale_shape_manual(values = c(Crude = 21, Adjusted = 19), name = NULL) +
    facet_wrap(~ outcome, ncol = 3, scales = "free_x") +
    labs(x = sprintf("%s: ratio versus the common noCOPD reference (log scale)",
                     grp), y = NULL) +
    theme_esi() +
    theme(legend.position = "bottom",
          legend.margin = margin(t = -2, b = 0),
          panel.grid.minor = element_blank(),
          panel.grid.major.y = element_blank(),
          plot.margin = margin(4, 20, 2, 4)) +
    scale_x_log10(breaks = scales::breaks_log(n = 4),
                  labels = scales::label_number(drop0trailing = TRUE),
                  expand = expansion(mult = c(0.10, 0.14)))
  out <- file.path(HERE, file)
  # Every text element must still clear the docx readability floor once the
  # figure is scaled to the 6.5 inch content width. Errors rather than warns.
  validate_layout(p, out)
  ggsave(out, p, width = NATIVE_W, height = 2.6, dpi = 300, bg = "white")
  cat("wrote", out, "\n")
}

make_fig("AFL-only",   "figure2_aflonly.png")
make_fig("COPD-minor", "figure3_copdminor.png")
make_fig("COPD-major", "figure4_copdmajor.png")
