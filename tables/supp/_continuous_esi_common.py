"""Shared row-builder for S6a1/S6a2/S6b: continuous-ESI vs FEV1/FVC models.

All three tables share the same source shape (Table_S6a_continuous_mortality
for S6a1/S6a2, Table_S6b_continuous_exacerbations for S6b). This helper
factors the row construction.
"""
import csv
import os

from manifest import ASSETS


def load_and_filter(csv_name, outcome_label, effect_prefix):
    """Return the three ordered rows for an outcome from a continuous-ESI CSV.

    csv_name: relative CSV under ASSETS.
    outcome_label: value in the 'outcome' column to filter on.
    effect_prefix: 'HR' or 'IRR' — used for column-naming assertions.
    """
    with open(os.path.join(ASSETS, csv_name)) as f:
        rows = [r for r in csv.DictReader(f) if r["outcome"] == outcome_label]

    order = ["ESI only", "FEV1/FVC only", "ESI + FEV1/FVC"]
    by_model = {r["model"]: r for r in rows}
    missing = [m for m in order if m not in by_model]
    if missing:
        raise KeyError(
            f"{csv_name} outcome={outcome_label!r} missing model rows "
            f"{missing}; source-CSV drift — refuse to silently truncate."
        )
    ordered = [by_model[m] for m in order]

    # Pull the correct estimate columns based on the source CSV convention.
    est_key_esi     = f"ESI_{effect_prefix}"
    est_key_fev1fvc = f"FEV1FVC_{effect_prefix}"

    body_rows = []
    for r in ordered:
        body_rows.append([
            r["model"],
            r[est_key_esi],  r["ESI_p"],
            r[est_key_fev1fvc], r["FEV1FVC_p"],
            r["LR_vs_FEV1FVC_only"],
        ])
    return body_rows


HEADERS_HR = ["Model", "ESI HR (95% CI)", "ESI p",
              "FEV₁/FVC HR (95% CI)", "FEV₁/FVC p",
              "LR vs FEV₁/FVC only"]
HEADERS_IRR = ["Model", "ESI IRR (95% CI)", "ESI p",
               "FEV₁/FVC IRR (95% CI)", "FEV₁/FVC p",
               "LR vs FEV₁/FVC only"]
COL_WIDTHS  = [1.2, 1.15, 0.55, 1.15, 0.55, 1.9]
