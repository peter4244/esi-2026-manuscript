# figures/style.R
# Single source of truth for ESI-manuscript figure styling. Sourced by every
# figures/figureN_*/*.R script.  No fontsize literals may appear elsewhere.
#
# Target journal: AJRCCM (US Letter, 6.5" content width, Arial family).

suppressPackageStartupMessages({
  library(ggplot2)
  library(scales)
})

# --------- Scale constants -------------------------------------------------
NATIVE_W               <- 7.5   # inch; ggsave width. Docx renders at 6.5"
CONTENT_W              <- 6.5   # inch; docx content width (post-1"-margin)
DOCX_SCALE             <- CONTENT_W / NATIVE_W   # 0.867

BODY_FS_NATIVE         <- 12    # pt at native width
HEADER_FS_NATIVE       <- 14    # pt at native width
DOCX_READABILITY_FLOOR <- 9     # pt at docx scale — validate_layout errors below this

# Effective (docx-scale) sizes:
BODY_FS_DOCX   <- BODY_FS_NATIVE   * DOCX_SCALE   # ~10.4 pt
HEADER_FS_DOCX <- HEADER_FS_NATIVE * DOCX_SCALE   # ~12.1 pt

# --------- Palette ---------------------------------------------------------
# Categorical colors for Bhatt-classification categories (four)
# + framework colors (CT vs ESI).
PALETTE <- c(
  "noCOPD"            = "#7F7F7F",   # gray
  "AFL-only-noCOPD"   = "#9467BD",   # purple
  "COPD-minor"        = "#FFB000",   # yellow
  "COPD-major"        = "#D62728",   # red
  "CT-based"          = "#1F77B4",   # blue
  "ESI-based"         = "#D62728"    # red (paired with CT blue)
)

# --------- Theme -----------------------------------------------------------
theme_esi <- function() {
  theme_bw(base_family = "Arial", base_size = BODY_FS_NATIVE) +
    theme(
      # Two-font hierarchy: headers (title, strip, legend title) at HEADER_FS;
      # body (axis titles, axis text, legend text) at BODY_FS.
      plot.title        = element_text(size = HEADER_FS_NATIVE, face = "plain"),
      plot.subtitle     = element_text(size = BODY_FS_NATIVE,   face = "plain",
                                       color = "grey30"),
      strip.text        = element_text(size = HEADER_FS_NATIVE, face = "plain"),
      legend.title      = element_text(size = HEADER_FS_NATIVE, face = "plain"),
      axis.title        = element_text(size = BODY_FS_NATIVE,   face = "plain"),
      axis.text         = element_text(size = BODY_FS_NATIVE,   face = "plain"),
      legend.text       = element_text(size = BODY_FS_NATIVE,   face = "plain"),
      plot.tag          = element_text(size = HEADER_FS_NATIVE, face = "bold"),
      # Layout
      panel.grid.minor  = element_blank(),
      strip.background  = element_blank(),
      legend.position   = "bottom"
    )
}

# --------- Helpers ---------------------------------------------------------
esi_fill <- function() {
  scale_fill_manual(values = PALETTE, name = "Classification")
}
esi_color <- function() {
  scale_color_manual(values = PALETTE, name = "Classification")
}
