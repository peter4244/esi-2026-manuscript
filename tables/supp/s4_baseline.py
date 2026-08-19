"""Supplemental Table S4 — baseline characteristics by GOLD-stage stratum.

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

TABLE_NUM = "S4"
TITLE = ("Baseline characteristics of the analytic cohort by GOLD-stage "
         "stratum")


def build(doc):
    # Landscape section wraps the heading, the table, and the legend so all
    # three sit on the same landscape page.
    dh.begin_landscape(doc)
    with open(os.path.join(ASSETS, "Table_S2_baseline_characteristics.csv")) as f:
        rows = list(csv.DictReader(f))

    # Compact headers so all 14 columns fit landscape 10" content width
    # without any cell wrapping. Terms are defined in the legend.
    # "mMRC≥2" and "SGRQ≥25" written without spaces around ≥ so they fit;
    # "FEV1 %pred" kept spaced-and-readable (needs 0.95" for header).
    headers = ["Stratum", "N", "Age", "Female", "Smoker",
               "BMI", "Pack-yr", "FEV1 %pred", "FEV1/FVC",
               "ESI", "LAA-950HU", "mMRC≥2", "SGRQ≥25",
               "Bronchitis"]

    body_rows = [
        [r["stratum"], r["n"], r["age"], r["pct_female"], r["pct_current"],
         r["BMI"], r["pack_years"], r["FEV1_pp"], r["FEV1_FVC"],
         r["ESI"], r["LAA950"], r["pct_mMRC2p"], r["pct_SGRQ25p"],
         r["pct_CB"]]
        for r in rows
    ]

    # Column widths sized so every header AND every body value renders on
    # ONE line at 9pt. Widest body values are the "X.X (Y.Y)" mean-(SD)
    # formats (Age/BMI/FEV1/FVC/ESI/LAA at ~11 chars, need ≥0.75).
    # Widest headers are "FEV1 %pred" and "Bronchitis" (10 chars bold,
    # need ≥0.90). Sum = 9.99, at landscape 10" content width.
    #                Stratum, N,    Age,  Female, Smoker,
    #                BMI,   Pack-yr, FEV1%pd, FEV1/FVC,
    #                ESI,   LAA,     mMRC,  SGRQ,   Bronchitis
    dh.add_table(doc, headers, body_rows,
                 col_widths_in=[0.65, 0.45, 0.70, 0.60, 0.65,
                                0.70, 0.68, 0.95, 0.80,
                                0.80, 0.90, 0.70, 0.80, 0.90],
                 body_fs=9, header_fs=9,
                 max_width_in=dh.LANDSCAPE_CONTENT_WIDTH_IN)
    dh.add_legend_from_sibling(doc, __file__, TABLE_NUM)

    # Revert to portrait for the next table onward.
    dh.end_landscape(doc)
