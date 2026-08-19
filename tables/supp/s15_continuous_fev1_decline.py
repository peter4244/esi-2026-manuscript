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
