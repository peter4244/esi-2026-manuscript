"""Shared builder for the pairwise-contrast table (Supplemental Table 3).

Rows come from Table_2_pairwise_contrasts.csv, filtered by outcome (all-cause
mortality, respiratory mortality, exacerbations).
"""
import csv
import os

from manifest import ASSETS


def load_contrasts(outcome_label):
    with open(os.path.join(ASSETS, "Table_2_pairwise_contrasts.csv")) as f:
        return [r for r in csv.DictReader(f) if r["outcome"] == outcome_label]


def _fmt_p(p):
    p = float(p)
    if p < 0.001:
        return "<0.001"
    if p >= 1:
        return "1.000"
    return f"{p:.3f}"


def _fmt(x, prec=3):
    return f"{float(x):.{prec}f}"


def build_rows(outcome_label):
    rows = load_contrasts(outcome_label)
    # The source CSV uses " - " to join the two contrast members, but the
    # category names themselves contain hyphens ("Both-COPD - CT-only-COPD"),
    # which is visually ambiguous. Use " / " as the contrast separator instead.
    return [
        [r["contrast"].replace(" - ", " / "),
         _fmt(r["est_logHR"]),
         _fmt(r["se_logHR"]),
         _fmt_p(r["p_adj"])]
        for r in rows
    ]
