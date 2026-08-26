"""Supplemental Table S15: continuous ESI vs FEV1/FVC as predictors of
FEV1 decline (mL/yr), stratified by baseline lung-function stratum
(GOLD 0, PRISm, pooled).

Companion table Supplemental Table 14 shows the same analysis for the
categorical outcomes (mortality + exacerbations).
"""
import csv
import os

from tables import docx_helpers as dh
from manifest import ASSETS

TABLE_NUM = "S15"
TITLE = ("Continuous ESI vs FEV1/FVC as predictors of FEV1 decline (mL/yr), "
         "stratified by baseline lung-function stratum")


def build(doc):
    with open(os.path.join(ASSETS,
                           "Table_S6c_continuous_fev1_decline.csv")) as f:
        rows = list(csv.DictReader(f))

    # ST15 is a stratified table: it reports the ESI-decline relationship within
    # each baseline lung-function stratum. The source CSV also carries a pooled
    # row across the whole cohort, which is a different analysis and is not
    # shown here. Pooled, ESI is confounded by baseline severity (high ESI is
    # concentrated in GOLD 3-4, who have least room to decline), so the pooled
    # estimate reverses sign relative to the within-stratum estimates and is
    # not interpretable as the same quantity. It remains in
    # Table_S6c_continuous_fev1_decline.csv for anyone tracing the analysis.
    rows = [r for r in rows if r["stratum"] != "pooled"]

    # "N" shortened from "N subjects" to fit the column; defined in legend.
    headers = ["Stratum", "N", "Model",
               "ESI slope (mL/yr)", "ESI p",
               "FEV₁/FVC slope (mL/yr)", "FEV₁/FVC p"]
    stratum_display = {"pooled": "Pooled"}
    body_rows = [
        [stratum_display.get(r["stratum"], r["stratum"]),
         r["n_subj"], r["model"],
         r["ESI_slope_mL_yr"], r["ESI_p"],
         r["FEV1FVC_slope_mL_yr"], r["FEV1FVC_p"]]
        for r in rows
    ]
    tbl = dh.add_table(doc, headers, body_rows,
                       col_widths_in=[0.75, 0.50, 1.00, 1.30, 0.65, 1.60, 0.70])
    dh.vmerge_col(tbl, col_idx=0)
    dh.vmerge_col(tbl, col_idx=1)
    dh.add_legend_from_sibling(doc, __file__, TABLE_NUM)
