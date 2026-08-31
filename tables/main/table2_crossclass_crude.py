"""Table 2 — crude rate ratios in the four cross-classification groups defined
by whether a participant meets COPD under each framework: Both-noCOPD
(reference), CT-only-COPD, ESI-only-COPD, Both-COPD.

Cols: Classification group | All-cause mortality RR (95% CI)
      | Respiratory mortality RR (95% CI) | Exacerbation RR (95% CI)

This table used to carry raw rates per 100 person-years and was the only main
table without intervals, which made it read as a different kind of object from
Table 3 directly beneath it. It now carries the crude rate ratio of each group
against the Both-noCOPD reference, on the same scale and in the same shape as
the adjusted estimates. The rates themselves, with the event counts and
person-years behind them, are in Supplemental Table S18.

Source:
    manuscript_assets/Table_2_raw_rates.csv
"""
import csv
import os

from tables import docx_helpers as dh
from tables.main import _crossclass_common as cc
from manifest import ASSETS

TABLE_NUM = "2"
TITLE = "Crude rate ratios by cross-classification group"

HEADERS = ["Classification group",
           "All-cause mortality RR (95% CI)",
           "Respiratory mortality RR (95% CI)",
           "Exacerbation RR (95% CI)"]

STEMS = ["rr_allcause", "rr_resp", "rr_exac"]


def _load():
    with open(os.path.join(ASSETS, "Table_2_raw_rates.csv")) as f:
        rows = {r["group"]: r for r in csv.DictReader(f)}
    missing = [g for g in cc.GROUPS if g not in rows]
    if missing:
        raise KeyError(f"Table_2_raw_rates.csv is missing groups {missing}; "
                       f"it has {sorted(rows)}")
    if "rr_allcause_lo" not in next(iter(rows.values())):
        raise KeyError("Table_2_raw_rates.csv has no interval columns; "
                       "re-render the analysis")
    return rows


def build_rows():
    """Body rows as lists of four strings. Split out from build() so the test
    suite can check the values without a Document."""
    src = _load()
    body_rows = []
    for g in cc.GROUPS:
        if g == cc.REFERENCE:
            body_rows.append([g] + ["Reference"] * 3)
            continue
        r = src[g]
        body_rows.append([g] + [
            cc.fmt(r[s], r[s + "_lo"], r[s + "_hi"]) for s in STEMS])
    return body_rows


def build(doc):
    tbl = cc.render(doc, HEADERS, build_rows())
    dh.add_legend_from_sibling(doc, __file__, TABLE_NUM)
    return tbl
