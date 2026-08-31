"""Table 3 — covariate-adjusted associations in the four cross-classification
groups, the adjusted counterpart to the crude rate ratios in Table 2.

Cols: Classification group | All-cause mortality HR (95% CI)
      | Respiratory mortality HR (95% CI) | Exacerbation IRR (95% CI)

No compact-letter display. Adjusting the exacerbation models for prior
exacerbation frequency removed the only pairwise contrast among the three
COPD-positive groups that had reached significance, so no contrast reaches it
for any outcome and there are no letters to show. The full contrasts are in
Supplemental Table S3; the legend says so.

Sources:
    manuscript_assets/Table_BhattOnly_vs_Both.csv         (all-cause + respiratory HR)
    manuscript_assets/Table_Exacerbations_Discordance.csv (exacerbation IRR)
    manuscript_assets/Table_2_pairwise_contrasts.csv      (checked, not printed)
"""
import csv
import os

from tables import docx_helpers as dh
from tables.main import _crossclass_common as cc
from manifest import ASSETS

TABLE_NUM = "3"
TITLE = "Adjusted associations by cross-classification group"

HEADERS = ["Classification group",
           "All-cause mortality HR (95% CI)",
           "Respiratory mortality HR (95% CI)",
           "Exacerbation IRR (95% CI)"]

# The estimate artifacts label the discordant groups with a parenthetical the
# printed table drops.
SRC_KEY = {
    "CT-only-COPD":  "CT-only-COPD (ESI missed)",
    "ESI-only-COPD": "ESI-only-COPD (Bhatt missed)",
    "Both-COPD":     "Both-COPD",
}

CLD_ALPHA = 0.05


def _load(csv_name):
    with open(os.path.join(ASSETS, csv_name)) as f:
        return list(csv.DictReader(f))


def _lookup(rows, group):
    for r in rows:
        if r["group"] == group:
            return r
    raise KeyError(f"Group {group!r} not found in table source rows: "
                   f"{[r['group'] for r in rows]}")


def _assert_no_significant_contrast():
    """The legend states that no pairwise contrast reaches significance, which
    is why no significance letters are printed. If a re-analysis makes one
    significant, the letters have to come back and this fails rather than
    letting the legend quietly become false."""
    rows = _load("Table_2_pairwise_contrasts.csv")
    sig = [(r["outcome"], r["contrast"], r["p_adj"])
           for r in rows if float(r["p_adj"]) < CLD_ALPHA]
    if sig:
        raise AssertionError(
            "Table 3 prints no significance letters because no pairwise "
            f"contrast was significant, but these now are: {sig}")


def build_rows():
    """Body rows as lists of four strings. Split out from build() so the test
    suite can check the values without a Document."""
    _assert_no_significant_contrast()
    hr_data = _load("Table_BhattOnly_vs_Both.csv")
    irr_data = _load("Table_Exacerbations_Discordance.csv")

    body_rows = []
    for g in cc.GROUPS:
        if g == cc.REFERENCE:
            body_rows.append([g] + ["Reference"] * 3)
            continue
        src = SRC_KEY[g]
        hr = _lookup(hr_data, src)
        irr = _lookup(irr_data, src)
        body_rows.append([
            g,
            cc.fmt(hr["all_HR"],  hr["all_LCI"],  hr["all_UCI"]),
            cc.fmt(hr["resp_HR"], hr["resp_LCI"], hr["resp_UCI"]),
            cc.fmt(irr["IRR"],    irr["LCI"],     irr["UCI"]),
        ])
    return body_rows


def build(doc):
    tbl = cc.render(doc, HEADERS, build_rows())
    dh.add_legend_from_sibling(doc, __file__, TABLE_NUM)
    return tbl
