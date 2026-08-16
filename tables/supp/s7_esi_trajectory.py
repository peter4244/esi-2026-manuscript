"""Supplementary Table S7 — ESI trajectory (change from baseline to follow-up
visits) stratified by baseline GOLD-strata.
"""
import csv
import os

from tables import docx_helpers as dh
from manifest import ASSETS

TABLE_NUM = "S7"
TITLE = ("ESI trajectory by baseline lung-function stratum, follow-up visits "
         "2 and 3")


def build(doc):
    with open(os.path.join(ASSETS, "Supp_Table_S7_ESI_trajectory.csv")) as f:
        rows = list(csv.DictReader(f))

    # Normalize CSV stratum label ("GOLD0") to the whitespace form used in
    # sibling supplement tables and in this table's own legend ("GOLD 0").
    stratum_display = {"GOLD0": "GOLD 0"}

    headers = ["Baseline stratum", "Visit", "N", "Mean ΔESI", "Median ΔESI"]
    body_rows = [
        [stratum_display.get(r["stratum_baseline"], r["stratum_baseline"]),
         r["visitnum"], r["n"],
         f"{float(r['mean_dESI']):.3f}",
         f"{float(r['median_dESI']):.3f}"]
        for r in rows
    ]
    tbl = dh.add_table(doc, headers, body_rows,
                       col_widths_in=[1.6, 0.75, 0.85, 1.65, 1.65])
    # Each baseline stratum has 2 follow-up visit rows — collapse the label.
    dh.vmerge_col(tbl, col_idx=0)
    dh.add_legend_from_sibling(doc, __file__, TABLE_NUM)
