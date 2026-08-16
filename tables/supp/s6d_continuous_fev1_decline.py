"""Supplementary Table S6d — continuous-ESI mixed-effects models for FEV1
decline, stratified by baseline GOLD-strata (GOLD 0, PRISm, pooled).
"""
import csv
import os

from tables import docx_helpers as dh
from manifest import ASSETS

TABLE_NUM = "S6d"
TITLE = ("Continuous ESI vs FEV1/FVC as predictors of FEV1 decline (mL/yr), "
         "stratified by baseline lung-function stratum")


def build(doc):
    with open(os.path.join(ASSETS, "Table_S6c_continuous_fev1_decline.csv")) as f:
        rows = list(csv.DictReader(f))

    headers = ["Stratum", "N subjects", "Model",
               "ESI slope (mL/yr)", "ESI p",
               "FEV₁/FVC slope (mL/yr)", "FEV₁/FVC p"]

    # Normalize the source-CSV "pooled" stratum label to sentence-cased
    # "Pooled" for visual consistency with sibling "GOLD 0" / "PRISm" strata.
    stratum_display = {"pooled": "Pooled"}

    body_rows = [
        [stratum_display.get(r["stratum"], r["stratum"]),
         r["n_subj"], r["model"],
         r["ESI_slope_mL_yr"], r["ESI_p"],
         r["FEV1FVC_slope_mL_yr"], r["FEV1FVC_p"]]
        for r in rows
    ]
    tbl = dh.add_table(doc, headers, body_rows,
                       col_widths_in=[0.75, 0.75, 1.2, 1.25, 0.45, 1.35, 0.75])
    # Each stratum has 2 model rows — collapse Stratum + N-subjects columns.
    dh.vmerge_col(tbl, col_idx=0)
    dh.vmerge_col(tbl, col_idx=1)
    dh.add_legend_from_sibling(doc, __file__, TABLE_NUM)
