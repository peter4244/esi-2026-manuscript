"""Supplementary Table S1 — sensitivity of the ESI-based COPD definition to
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

from tables import docx_helpers as dh
from manifest import ASSETS

TABLE_NUM = "S1"
TITLE = ("Threshold sensitivity: agreement and diagnostic performance of "
         "candidate ESI-based COPD definitions relative to the CT-based "
         "reference")


_SELECTED_MARKER = "[SELECTED]"


def build(doc):
    with open(os.path.join(ASSETS, "Supp_Table_Thresholds.csv")) as f:
        rows = list(csv.DictReader(f))

    headers = ["Variant", "N COPD", "Sensitivity", "Specificity", "κ",
               "Selected"]
    body_rows = []
    for r in rows:
        variant = r["variant"]
        is_selected = _SELECTED_MARKER in variant
        variant_clean = variant.replace(_SELECTED_MARKER, "").strip()
        body_rows.append([
            variant_clean, r["n_COPD"],
            f"{float(r['sens']):.3f}",
            f"{float(r['spec']):.3f}",
            f"{float(r['kappa']):.3f}",
            "✓" if is_selected else "",
        ])
    dh.add_table(doc, headers, body_rows,
                 col_widths_in=[2.6, 0.60, 0.85, 0.85, 0.75, 0.85])
    dh.add_legend_from_sibling(doc, __file__, TABLE_NUM)
