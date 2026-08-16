"""Explicit ordered manifests for the v9 rebuild.

Never use sorted(glob(...)) — insertion breaks silent-ordering, and lexical sort
places s10 before s2. All ordering flows through this file.
"""

# ============================================================================
# Main manuscript
# ============================================================================

# (label, source) — source is either a "prose_py.<module>" import path or a
# "prose/<name>.md" relative path.
MAIN_PROSE_ORDER = [
    ("title_authors", "prose_py.title_authors"),      # Python module
    ("abstract",      "prose/02_abstract.md"),
    ("introduction",  "prose/03_introduction.md"),
    ("methods",       "prose/04_methods.md"),
    ("results",       "prose/05_results.md"),
    ("discussion",    "prose/06_discussion.md"),
    ("conclusion",    "prose/07_conclusion.md"),
    ("references",    "prose_py.references"),         # Python module
]

# Main-manuscript tables. Long name = filesystem module; short alias = prose key.
MAIN_TABLES = [
    "table1_by_category",
    "table2_cross_classification",
]

# Figures. Same convention.
FIGURES = [
    "figure1_agreement",
    "figure2_discordance",
]

# Alias map decouples prose from filesystem naming (Phase G review #14).
# Prose writes {{INSERT:table1}}, {{INSERT:figure2}} — short and stable.
# If a table module is renamed, only this map changes; prose is untouched.
INSERT_KEYS = {
    "table1":   "tables.main.table1_by_category",
    "table2":   "tables.main.table2_cross_classification",
    "figure1":  "figures.figure1_agreement",
    "figure2":  "figures.figure2_discordance",
}


def _cross_check():
    """Fail loud on drift between MAIN_TABLES/FIGURES and INSERT_KEYS.
    Phase G checkpoint #2.
    """
    tables_in_keys = {p.rsplit(".", 1)[1] for p in INSERT_KEYS.values()
                      if p.startswith("tables.main.")}
    if tables_in_keys != set(MAIN_TABLES):
        raise AssertionError(
            f"MAIN_TABLES {sorted(MAIN_TABLES)} differs from INSERT_KEYS "
            f"main-table targets {sorted(tables_in_keys)}. Update one."
        )
    figs_in_keys = {p.rsplit(".", 1)[1] for p in INSERT_KEYS.values()
                    if p.startswith("figures.")}
    if figs_in_keys != set(FIGURES):
        raise AssertionError(
            f"FIGURES {sorted(FIGURES)} differs from INSERT_KEYS figure "
            f"targets {sorted(figs_in_keys)}. Update one."
        )

_cross_check()  # runs at import; build scripts fail immediately on drift.

# ============================================================================
# Supplement
# ============================================================================

SUPP_PROSE_ORDER = [
    ("title_and_toc", "prose_py.supp_title"),       # supplement title + auto-TOC
    ("frontmatter",   "prose/supp_frontmatter.md"),  # optional preamble
]

# Rendered in this exact order; TOC labels drawn from each module's TABLE_NUM/TITLE.
SUPP_TABLES = [
    "s1_thresholds",
    "s2_baseline",
    "s3a_esi10_excluded",
    "s3b_alt_framework",
    "s3c_severe_exac",
    "s4a_cvd",
    "s4b_cancer",
    "s4c_other",
    "s5_fev1_decline",
    "s6a_continuous_mortality_all",
    "s6b_continuous_mortality_resp",
    "s6c_continuous_exacerbations",
    "s6d_continuous_fev1_decline",
    "s7_esi_trajectory",
    "s8_hr_bootstrap",
    "s8b_irr_bootstrap",
    "s9a_pairwise_mortality",
    "s9b_pairwise_exac",
]

# ============================================================================
# Paths
# ============================================================================
import os
PROJECT_ROOT = os.path.dirname(os.path.abspath(__file__))
ASSETS       = os.path.join(PROJECT_ROOT, "manuscript_assets")
FIGURES_DIR  = os.path.join(PROJECT_ROOT, "figures")
MANUSCRIPT_OUT = os.path.join(PROJECT_ROOT, "manuscript",
                              "ESI manuscript draft v9 2026.7.19_PJC.docx")
SUPPLEMENT_OUT = os.path.join(PROJECT_ROOT, "manuscript",
                              "ESI manuscript supplement v9 2026.7.19_PJC.docx")
BUILD_LOG          = os.path.join(PROJECT_ROOT, "build_log_v9.txt")
BUILD_LOG_MAIN     = os.path.join(PROJECT_ROOT, "build_log_v9_main.txt")
BUILD_LOG_SUPP     = os.path.join(PROJECT_ROOT, "build_log_v9_supp.txt")
