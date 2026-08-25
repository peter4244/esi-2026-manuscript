"""Supplemental Table S1 — sensitivity of the ESI-based COPD definition to
choice of low/high ESI thresholds and minor-criteria thresholding.

Rows: 10 candidate variants; the training-derived variant used in all
main-manuscript analyses is annotated in a dedicated "Selected" column.
Source: manuscript_assets/Supp_Table_Thresholds.csv (columns: variant, n_COPD,
sens, spec, kappa). The raw CSV encodes selection status by appending the
literal "[SELECTED]" to the variant string; the display strips that marker
and reifies it as a separate column so no reader sees "[SELECTED]" as an
unresolved placeholder.
"""
import csv
import os
import re

from tables import docx_helpers as dh
from manifest import ASSETS

TABLE_NUM = "S1"
TITLE = ("Threshold sensitivity: agreement and diagnostic performance of "
         "candidate ESI-based COPD definitions relative to the CT-based "
         "reference")


_SELECTED_MARKER = "[SELECTED]"

# Display transforms for the Variant column. The source CSV uses two
# different styles across rows ("4-crit, ESI cutoff X, threshold >=Y-of-Z"
# vs "5-crit, T_low=X / T_high=Y"). We standardize to a single style at
# display time: "N criteria" (not "N-crit"), and consistent "= " spacing
# around numeric parameters, while keeping the 4-crit single-cutoff form
# distinguishable from the 5-crit dual-threshold form.
_VARIANT_TRANSFORMS = [
    (re.compile(r"^(\d)-crit,"),     r"\1 criteria,"),
    (re.compile(r">=\s*(\d+)-of-(\d+)"), r"≥\1 of \2 minor"),
    (re.compile(r"ESI cutoff (\d)"), r"ESI cutoff = \1"),
    (re.compile(r"T_low=\s*"),       r"T_low = "),
    (re.compile(r"T_high=\s*"),      r"T_high = "),
    (re.compile(r"\s*/\s*T_high"),   r", T_high"),
]


def _display_variant(v):
    for pat, repl in _VARIANT_TRANSFORMS:
        v = pat.sub(repl, v)
    return v


def build(doc):
    with open(os.path.join(ASSETS, "Supp_Table_Thresholds.csv")) as f:
        rows = list(csv.DictReader(f))

    # "N" (the count of participants classified as COPD by this candidate
    # definition) is short enough that a wider header column would waste
    # space; abbreviation is defined in the legend's Abbreviations block.
    # Each candidate is reported twice: on the full analytic cohort (in-sample
    # with respect to threshold selection, since the cut-points were derived
    # from the 80% training split) and on the held-out 20% split. Column
    # headers carry the population so the two blocks cannot be confused.
    headers = ["Variant",
               "Full N", "Full sens.", "Full spec.", "Full κ",
               "Test N", "Test sens.", "Test spec.", "Test κ",
               "Selected"]
    body_rows = []
    for r in rows:
        variant = r["variant"]
        is_selected = _SELECTED_MARKER in variant
        variant_clean = variant.replace(_SELECTED_MARKER, "").strip()
        body_rows.append([
            _display_variant(variant_clean),
            r["n_COPD"],
            f"{float(r['sens']):.3f}",
            f"{float(r['spec']):.3f}",
            f"{float(r['kappa']):.3f}",
            r["test_n_COPD"],
            f"{float(r['test_sens']):.3f}",
            f"{float(r['test_spec']):.3f}",
            f"{float(r['test_kappa']):.3f}",
            "✓" if is_selected else "",
        ])
    # Landscape section so the wide Variant column ("4 criteria, ESI cutoff
    # = 2.0, threshold ≥3 of 4 minor" ~53 chars) and the full-word data
    # headers ("Sensitivity", "Specificity", "Selected") all fit on one
    # line without wrapping.
    # begin_landscape is idempotent (no-op if already landscape). We do NOT
    # call end_landscape here because the next table (ST2 baseline) also
    # needs landscape — the last consecutive landscape table is the one
    # that switches back to portrait via end_landscape.
    dh.begin_landscape(doc)
    dh.add_table(doc, headers, body_rows,
                 col_widths_in=[3.95, 0.60, 0.70, 0.70, 0.55,
                                0.60, 0.70, 0.70, 0.55, 0.95],
                 max_width_in=dh.LANDSCAPE_CONTENT_WIDTH_IN)
    dh.add_legend_from_sibling(doc, __file__, TABLE_NUM)
