# figures/validate_layout.R
# Docx-scale readability check for figure ggplot objects.
# Every figures/figureN_*/*.R script must call validate_layout(fig, out_path)
# BEFORE ggsave().
#
# Post Phase-G review notes:
#  - Base-R `%||%` (R >= 4.4) removed for portability (Phase G #10).
#  - Text-clipping detection removed — withCallingHandlers can't catch text
#    overflow; only data outside limits triggers warnings, giving false
#    confidence (Phase G #11). Author must eyeball the PNG.
#  - Vacuous-pass protection: fig's theme is merged with theme_bw() so a figure
#    that forgets theme_esi() has resolved font sizes we can check.

# Do NOT source style.R here — the calling figure script must source it first.
# (Cross-script `source()` with relative paths is fragile in R; the caller
# owns path resolution.) Verify the expected symbols exist.
for (nm in c("NATIVE_W", "CONTENT_W", "BODY_FS_NATIVE",
             "DOCX_READABILITY_FLOOR", "PALETTE", "theme_esi")) {
  if (!exists(nm)) {
    stop("validate_layout.R requires that style.R was sourced first; ",
         "missing symbol: ", nm)
  }
}

# --------------------------------------------------------------------------
# validate_layout(fig, out_path, native_w = NATIVE_W)
#
# Verifies that every text element in the ggplot's theme has a font size that,
# when scaled to CONTENT_W inches, meets DOCX_READABILITY_FLOOR.
#
# Errors — does not warn — on any failure. Print the offending element so the
# author can fix it before shipping.
# --------------------------------------------------------------------------
validate_layout <- function(fig, out_path, native_w = NATIVE_W) {
  # Merge fig$theme with the base theme so element sizes are all resolved,
  # not just the ones the figure overrode. Prevents vacuous pass when a
  # figure author forgets to call theme_esi().
  effective_theme <- theme_bw(base_family = "Arial",
                              base_size = BODY_FS_NATIVE) + fig$theme

  scale <- CONTENT_W / native_w
  elements <- c("plot.title", "plot.subtitle", "strip.text",
                "legend.title", "legend.text",
                "axis.title", "axis.title.x", "axis.title.y",
                "axis.text",  "axis.text.x",  "axis.text.y",
                "plot.tag")
  failures <- character(0)
  for (el in elements) {
    e <- effective_theme[[el]]
    if (is.null(e)) next
    sz <- e$size
    if (is.null(sz) || is.na(sz)) next
    docx_sz <- as.numeric(sz) * scale
    if (docx_sz < DOCX_READABILITY_FLOOR) {
      failures <- c(failures,
        sprintf("  %s: %.1f pt native → %.1f pt at docx scale (floor %.1f pt)",
                el, sz, docx_sz, DOCX_READABILITY_FLOOR))
    }
  }
  if (length(failures)) {
    stop("validate_layout(", basename(out_path),
         "): text below docx-readability floor:\n",
         paste(failures, collapse = "\n"))
  }

  # ---- Strip-label length heuristic (Phase H addition) --------------------
  # Full text-extent detection in R is fragile (requires grid device
  # introspection). A heuristic that catches the common case: for a
  # facet_wrap, the strip label per facet must fit inside the facet's
  # allocated width at the current strip font size.
  #
  # Rough width budget: `native_w / ncol` inches per facet strip. At
  # BODY_FS_NATIVE point (Arial), one character occupies roughly
  # `BODY_FS_NATIVE * 0.5 / 72` inches. `\n`-wrapped strip labels are
  # evaluated per line.
  built <- try(ggplot_build(fig), silent = TRUE)
  if (!inherits(built, "try-error")) {
    fp <- built$layout$facet_params
    ncol <- if (!is.null(fp$ncol)) fp$ncol else NA_integer_
    if (!is.na(ncol) && ncol >= 1) {
      strip_fs <- effective_theme$strip.text$size
      if (is.null(strip_fs) || is.na(strip_fs)) strip_fs <- BODY_FS_NATIVE
      char_w_in <- as.numeric(strip_fs) * 0.5 / 72       # ≈ Arial em width
      panel_w_in <- native_w / ncol
      # 15% margin buffer for padding/borders
      max_chars <- floor(panel_w_in * 0.85 / char_w_in)
      strip_labels <- as.character(built$layout$layout$PANEL)
      # Better: inspect the actual strip labels via layer_data
      lyt <- built$layout$layout
      panel_labels <- lyt[[grep("^\\.?[A-Za-z]", names(lyt))[
        length(grep("^\\.?[A-Za-z]", names(lyt)))]]]
      # Iterate through unique strip texts across the facet variable
      strip_var <- setdiff(names(lyt), c("PANEL", "ROW", "COL", "SCALE_X",
                                          "SCALE_Y"))
      long_labels <- character(0)
      if (length(strip_var)) {
        for (col in strip_var) {
          for (lbl in unique(as.character(lyt[[col]]))) {
            # Compare each `\n`-separated line to the char budget
            for (line in strsplit(lbl, "\n", fixed = TRUE)[[1]]) {
              if (nchar(line) > max_chars) {
                long_labels <- c(long_labels,
                  sprintf("  \"%s\" (%d chars > %d budget for %d cols at %.0fpt)",
                          line, nchar(line), max_chars, ncol, strip_fs))
              }
            }
          }
        }
      }
      if (length(long_labels)) {
        stop("validate_layout(", basename(out_path),
             "): facet strip labels likely to clip:\n",
             paste(long_labels, collapse = "\n"),
             "\n  Wrap with '\\n' or shorten labels.")
      }
    }
  }
  invisible(TRUE)
}

# --------------------------------------------------------------------------
# validate_significance_brackets(brackets_df, labels_df,
#                                text_size_mm, facet_col,
#                                y_max_lookup, panel_height_in,
#                                out_path = "figure")
#
# Checks that per-facet significance-bar stacks in a scientific figure have
# enough vertical clearance that a lower-tier label text does not collide
# with a higher-tier bracket's horizontal line.
#
# Reason for existence: `geom_text` labels above a `geom_segment` bracket
# ascend UP from their baseline. When multiple brackets are stacked (as in
# Figure 2's pairwise-comparison annotations), the label of tier N can
# extend into the horizontal line of tier N+1 if the tier spacing is less
# than the rendered text height plus a small padding. The core
# `validate_layout` docx-readability check does not catch this — text
# height in data-unit space depends on the panel's y-range and the panel's
# physical height, which are per-facet quantities.
#
# Inputs:
#   brackets_df:      data frame with a facet-key column, x, xend, y, yend
#                     (the geom_segment rows drawn for the bracket lines +
#                      tick "hooks"). Each row is one segment.
#   labels_df:        data frame with the same facet-key column, x, y,
#                     and `label` (character). Each row is one geom_text.
#   text_size_mm:     the `size = ` argument passed to geom_text (mm).
#   facet_col:        name of the facet-key column in both data frames.
#   y_max_lookup:     named list mapping each facet key to its ymax
#                     (visible axis maximum after scale expansion).
#   panel_height_in:  physical height, in inches, of a single facet panel
#                     (used with y-range to convert text-height points into
#                     data units).
#   out_path:         label for the error message.
#
# Fails with `stop(...)` if any label bbox top would overlap or graze a
# horizontal segment above it in the same facet. The check uses a small
# safety pad (default = 25% of text height in data units) so touch-and-go
# geometries still fail.
# --------------------------------------------------------------------------
validate_significance_brackets <- function(brackets_df, labels_df,
                                            text_size_mm,
                                            facet_col,
                                            y_max_lookup,
                                            panel_height_in,
                                            out_path = "figure",
                                            pad_frac = 0.50) {
  if (is.null(brackets_df) || nrow(brackets_df) == 0) return(invisible(TRUE))
  if (is.null(labels_df)   || nrow(labels_df)   == 0) return(invisible(TRUE))
  if (!facet_col %in% names(brackets_df) ||
      !facet_col %in% names(labels_df)) {
    stop("validate_significance_brackets: facet_col '", facet_col,
         "' not found in both brackets_df and labels_df.")
  }
  # ggplot geom_text size is in mm; convert to points then to inches.
  text_height_pt <- text_size_mm / 0.352778   # mm → pt
  text_height_in <- text_height_pt / 72
  failures <- character(0)
  for (facet_key in unique(labels_df[[facet_col]])) {
    ymax <- y_max_lookup[[as.character(facet_key)]]
    if (is.null(ymax) || is.na(ymax)) next
    # Convert text height (inches) into this facet's data units.
    # Panel y-range = ymax (the plot's expanded y-max, since panels start
    # at 0 for the bar plots in this codebase). data-units per inch =
    # ymax / panel_height_in.
    data_units_per_in <- ymax / panel_height_in
    text_h_data <- text_height_in * data_units_per_in
    pad_data    <- pad_frac * text_h_data

    facet_labels   <- labels_df[labels_df[[facet_col]]   == facet_key, ]
    facet_segments <- brackets_df[brackets_df[[facet_col]] == facet_key, ]
    # Horizontal segments only (y == yend); these are the bracket bars.
    horiz <- facet_segments[abs(facet_segments$y - facet_segments$yend) < 1e-9, ]
    if (nrow(horiz) == 0) next
    for (i in seq_len(nrow(facet_labels))) {
      lbl <- facet_labels[i, ]
      # Assume vjust = 0 (baseline at y) so text extends upward by
      # text_h_data. Label top-edge (with pad):
      label_top <- lbl$y + text_h_data + pad_data
      # Check every horizontal bracket line ABOVE the label baseline in
      # this facet. If any lies within the label's occupied vertical band,
      # flag it as a collision.
      above <- horiz[horiz$y > lbl$y, , drop = FALSE]
      if (nrow(above) == 0) next
      collide <- above[above$y <= label_top, , drop = FALSE]
      if (nrow(collide) > 0) {
        for (j in seq_len(nrow(collide))) {
          failures <- c(failures, sprintf(
            "  facet '%s': label '%s' at y=%.3f (top=%.3f incl %.0f%% pad) collides with bracket line at y=%.3f (gap=%.3f data-units; text height=%.3f)",
            as.character(facet_key), lbl$label, lbl$y, label_top, 100 * pad_frac,
            collide$y[j], collide$y[j] - lbl$y, text_h_data))
        }
      }
    }
  }
  if (length(failures)) {
    stop("validate_significance_brackets(", basename(out_path),
         "): stacked bracket labels overlap the bracket line above them:\n",
         paste(failures, collapse = "\n"),
         "\n  Increase tier spacing (y_mult), reduce text size, or expand y-axis headroom.")
  }
  invisible(TRUE)
}
