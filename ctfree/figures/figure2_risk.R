#!/usr/bin/env Rscript
# Figures 2 to 4 (draft) — one per diagnostic category.
#
# A single figure holding every schema, every category and both estimate types
# was unreadable: 32 intervals per panel, and the comparison that matters,
# whether a category's label is honest, was buried among the ones that do not
# vary. Split by category, each figure asks one question of one group across
# the schemas that actually define it.
#
# Reference is that schema's own noCOPD group throughout. The fixed ratio has
# only a single COPD category, so it appears only alongside COPD-major, the
# category it corresponds to; it has no AFL-only or COPD-minor to show.
#
# MOCKUP STAGE: relaxed rigor, no validator gate yet.
suppressPackageStartupMessages({ library(dplyr); library(ggplot2) })
.b <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
HERE <- if (length(.b)) dirname(normalizePath(sub("^--file=", "", .b[1]))) else "ctfree/figures"
source(file.path(dirname(dirname(HERE)), "figures", "style.R"))
source(file.path(dirname(dirname(HERE)), "figures", "validate_layout.R"))
ASSETS <- file.path(dirname(HERE), "assets")

risk <- read.csv(file.path(ASSETS, "schema_risk.csv"),  stringsAsFactors = FALSE)
crd  <- read.csv(file.path(ASSETS, "schema_crude.csv"), stringsAsFactors = FALSE)
SCH  <- c(S1 = "Fixed ratio", S2 = "MD-COPD with CT",
          S3 = "MD-COPD without CT", S4 = "MD-COPD with ESI")
OUTC <- list(c("all", "All-cause mortality"), c("resp", "Respiratory mortality"),
             c("exac", "Exacerbations"))
PAL  <- c("AFL-only" = "#9467BD", "COPD-minor" = "#FFB000", "COPD-major" = "#D62728")

gather_one <- function(cat_wanted, schemas) {
  do.call(rbind, lapply(OUTC, function(o) {
    est <- if (o[1] == "exac") "exac_IRR" else paste0(o[1], "_HR")
    want <- if (cat_wanted == "COPD-major") c("COPD-major", "COPD") else cat_wanted
    a <- risk[risk$schema %in% schemas & risk$category %in% want & !is.na(risk[[est]]), ]
    k <- crd[crd$schema %in% schemas & crd$outcome == o[1] &
             crd$category %in% want & !is.na(crd$rr), ]
    rbind(
      data.frame(schema = SCH[k$schema], est = k$rr, lo = k$lo, hi = k$hi,
                 outcome = o[2], type = "Crude", stringsAsFactors = FALSE),
      data.frame(schema = SCH[a$schema], est = a[[est]],
                 lo = a[[paste0(o[1], "_LCI")]], hi = a[[paste0(o[1], "_UCI")]],
                 outcome = o[2], type = "Adjusted", stringsAsFactors = FALSE)) }))
}

make_fig <- function(cat_wanted, schemas, file) {
  d <- gather_one(cat_wanted, schemas)
  # n belongs on the axis label, not in a subtitle that runs off the canvas.
  lab_of <- vapply(schemas, function(s) {
    g <- if (cat_wanted == "COPD-major" && s == "S1") "COPD" else cat_wanted
    sprintf("%s\n(n = %s)", SCH[[s]],
            format(risk$n[risk$schema == s & risk$category == g], big.mark = ",")) }, "")
  names(lab_of) <- unname(SCH[schemas])
  d$schema <- unname(lab_of[d$schema])
  d$outcome <- factor(d$outcome, levels = vapply(OUTC, `[`, "", 2))
  d$schema  <- factor(d$schema, levels = rev(unname(lab_of)))
  d$type    <- factor(d$type, levels = c("Crude", "Adjusted"))
  # A lower bound of exactly zero is a real result, a category in which a
  # resample can contain no events. It cannot sit on a log axis, so it is
  # drawn as an open-ended interval rather than dropped.
  d$open_lo <- !is.na(d$lo) & d$lo <= 0
  d$lo[d$open_lo] <- NA_real_
  # Point the arrow just inside the panel rather than at est/10, which for a
  # small estimate lands off the axis, and target the same place for every
  # facet so the mark reads as a convention rather than a data value.
  d <- d %>% group_by(outcome) %>%
    mutate(arrow_to = min(c(lo, est), na.rm = TRUE) * 0.75) %>% ungroup()
  # Both layers must carry every row: position_dodge assigns offsets from the
  # group levels present in a layer, so a subsetted layer dodges to a different
  # place than the full ones and the arrow lands on the wrong row. Blank the
  # inapplicable rows with NA instead of filtering them out.
  # geom_segment dodges y and yend independently, which slants the mark across
  # rows. Draw the interval down to the panel floor with an ordinary linerange
  # and cap it with a "<" glyph, both of which dodge as a single y.
  d$draw_lo <- ifelse(d$open_lo, d$arrow_to, d$lo)
  d$cap_x   <- ifelse(d$open_lo, d$arrow_to, NA_real_)
  pd <- position_dodge(width = 0.55)
  p <- ggplot(d, aes(x = est, y = schema, shape = type, group = type)) +
    geom_vline(xintercept = 1, linetype = 2, color = "grey45", linewidth = 0.4) +
    geom_linerange(aes(xmin = draw_lo, xmax = hi), linewidth = 0.6, position = pd,
                   color = PAL[[cat_wanted]], na.rm = TRUE) +
    geom_point(aes(x = cap_x), shape = 60, size = 2.4, stroke = 0.9,
               position = pd, color = PAL[[cat_wanted]], na.rm = TRUE) +
    geom_point(size = 2.6, position = pd, color = PAL[[cat_wanted]],
               fill = "white", stroke = 0.9) +
    scale_shape_manual(values = c(Crude = 21, Adjusted = 19), name = NULL) +
    scale_x_log10(breaks = scales::breaks_log(n = 5),
                  labels = scales::label_number(drop0trailing = TRUE)) +
    facet_wrap(~ outcome, ncol = 3, scales = "free_x") +
    # No title above the panels. The category is named in the caption, which
    # is where a manuscript figure legend carries it anyway.
    labs(caption = sprintf("%s, against each schema's own noCOPD group.", cat_wanted),
         x = "Ratio versus that schema's own noCOPD group (log scale)", y = NULL) +
    theme_esi() +
    theme(legend.position = "bottom",
          plot.caption = element_text(hjust = 0.5, size = BODY_FS_NATIVE),
          panel.grid.minor = element_blank(),
          panel.grid.major.y = element_blank(),
          plot.margin = margin(4, 12, 4, 4))
  out <- file.path(HERE, file)
  # Every text element must still clear the docx readability floor once the
  # figure is scaled to the 6.5 inch content width. Errors rather than warns.
  validate_layout(p, out)
  ggsave(out, p, width = NATIVE_W, height = 3.5, dpi = 300, bg = "white")
  cat("wrote", out, "\n")
}

make_fig("AFL-only",   c("S2","S3","S4"),      "figure2_aflonly.png")
make_fig("COPD-minor", c("S2","S3","S4"),      "figure3_copdminor.png")
make_fig("COPD-major", c("S1","S2","S3","S4"), "figure4_copdmajor.png")
