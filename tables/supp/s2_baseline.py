"""Supplementary Table S2 — baseline characteristics by GOLD-stage stratum.

Rows: 8 (Never, GOLD0, PRISm, GOLD1..4, Overall).
Source: manuscript_assets/Table_S2_baseline_characteristics.csv.

Layout (supp review §1 follow-up): 14 columns are too wide for portrait
6.5". Rendered in a landscape section (10" content width) so every column
can carry its full header ("% female", "% chronic bronchitis", etc.) without
compressing to abbreviations or shrinking below 9-pt text.
"""
import csv
import os

from tables import docx_helpers as dh
from manifest import ASSETS

TABLE_NUM = "S2"
TITLE = ("Baseline characteristics of the analytic cohort by GOLD-stage "
         "stratum")


def build(doc):
    # Landscape section wraps the heading, the table, and the legend so all
    # three sit on the same landscape page.
    dh.begin_landscape(doc)
    with open(os.path.join(ASSETS, "Table_S2_baseline_characteristics.csv")) as f:
        rows = list(csv.DictReader(f))

    headers = ["Stratum", "N", "Age", "% female", "% current smoker",
               "BMI", "Pack-years", "FEV1 %pred", "FEV1/FVC",
               "ESI", "%LAA-950HU", "% mMRC ≥ 2", "% SGRQ ≥ 25",
               "% chronic bronchitis"]

    body_rows = [
        [r["stratum"], r["n"], r["age"], r["pct_female"], r["pct_current"],
         r["BMI"], r["pack_years"], r["FEV1_pp"], r["FEV1_FVC"],
         r["ESI"], r["LAA950"], r["pct_mMRC2p"], r["pct_SGRQ25p"],
         r["pct_CB"]]
        for r in rows
    ]

    # 14 columns must sum to ≤ 10.0" (landscape content width). Column
    # widths chosen so the widest header ("% chronic bronchitis" at 9pt bold
    # ≈ 1.10") fits on a single line. Body + header at 9pt: readable, no
    # cell wraps beyond one line.
    #                Stratum, N, Age, %fem, %CS,
    #                BMI, PkYr, FEV1%pd, FEV1/FVC,
    #                ESI, %LAA, %mMRC≥2, %SGRQ≥25, %CB
    dh.add_table(doc, headers, body_rows,
                 col_widths_in=[0.55, 0.35, 0.45, 0.60, 0.85,
                                0.45, 0.65, 0.70, 0.70,
                                0.45, 0.95, 0.75, 0.80, 1.15],
                 body_fs=9, header_fs=9,
                 max_width_in=dh.LANDSCAPE_CONTENT_WIDTH_IN)
    dh.add_legend_from_sibling(doc, __file__, TABLE_NUM)

    # Revert to portrait for S3a and onward.
    dh.end_landscape(doc)
