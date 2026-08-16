"""Shared builder for S9a/S9b pairwise-contrast tables.

Both source their rows from Table_2_pairwise_contrasts.csv filtered by outcome.
S9a is respiratory mortality (log HR contrasts); S9b is exacerbations (log IRR
contrasts).
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
        return "1.00"
    # Small p-values (< 0.01) need 3 decimals so 0.005 doesn't round to 0.00
    # under a naive .2f format (Phase M4 visual-QA fix).
    if p < 0.01:
        return f"{p:.3f}"
    return f"{p:.2f}"


def _fmt(x, prec=3):
    return f"{float(x):.{prec}f}"


def build_rows(outcome_label):
    rows = load_contrasts(outcome_label)
    # The source CSV uses " - " to join the two contrast members, but the
    # category names themselves contain hyphens ("Both-COPD - Bhatt-only-COPD"),
    # which is visually ambiguous. Use " / " as the contrast separator instead.
    return [
        [r["contrast"].replace(" - ", " / "),
         _fmt(r["est_logHR"]),
         _fmt(r["se_logHR"]),
         _fmt_p(r["p_adj"])]
        for r in rows
    ]
