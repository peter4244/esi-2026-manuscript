"""Table 1 — Outcome associations by Bhatt-framework category, both frameworks.

Rows: {All-cause mortality (HR), Respiratory mortality (HR), Exacerbations (IRR)}
      x {COPD-minor, COPD-major}.  AFL-only-noCOPD not included (small n,
      non-significant across all three outcomes).
Cols: Outcome (metric) | Category | CT-based (95% CI) | ESI-based (95% CI) |
      CT vs ESI (paired bootstrap p)

Sources:
    manuscript_assets/Table_8_allcause.csv                       (HR estimates)
    manuscript_assets/Table_8_resp.csv                           (HR estimates)
    manuscript_assets/Table_Exacerbations_Bhatt.csv              (IRR estimates)
    manuscript_assets/Supp_Table_HR_Difference_Bootstrap.csv     (paired-bootstrap p, mortality)
    manuscript_assets/Supp_Table_IRR_Difference_Bootstrap.csv    (paired-bootstrap p, exacerbations)

The legend body cites the paired C-index-equivalence result summarized from
manuscript_assets/Table_1_Cindex_Equivalence.csv, but the specific numeric
("p < 0.001") is hardcoded in the legend .md rather than pulled at build time.
If a re-analysis changes those p-values, update the legend .md manually.
"""
import csv
import os

from tables import docx_helpers as dh
from manifest import ASSETS

TABLE_NUM = "1"
TITLE = ("Associations of MD-COPD diagnostic categories with mortality "
         "and exacerbation outcomes, under the original CT-based and the "
         "reformulated ESI-based framework")


def _load(csv_name):
    with open(os.path.join(ASSETS, csv_name)) as f:
        return list(csv.DictReader(f))


def _fmt(hr, lci, uci):
    return f"{float(hr):.2f} ({float(lci):.2f}–{float(uci):.2f})"


def _row_lookup(rows, group):
    for r in rows:
        if r["group"] == group:
            return r
    raise KeyError(f"Group {group!r} not found in table source rows: "
                   f"{[r['group'] for r in rows]}")


def _pvalue_lookup(rows, outcome_key, category):
    """Return the 'two_sided_p_reported' string from a bootstrap CSV row
    matching (outcome, category). Raises KeyError if no match — a missing
    cell would silently render as blank and mask an analysis gap."""
    for r in rows:
        if r["outcome"] == outcome_key and r["category"] == category:
            return r["two_sided_p_reported"]
    raise KeyError(f"No bootstrap p-value for outcome={outcome_key!r}, "
                   f"category={category!r}")


def build(doc):
    allcause = _load("Table_8_allcause.csv")
    resp     = _load("Table_8_resp.csv")
    exac     = _load("Table_Exacerbations_Bhatt.csv")
    hr_boot  = _load("Supp_Table_HR_Difference_Bootstrap.csv")
    irr_boot = _load("Supp_Table_IRR_Difference_Bootstrap.csv")

    categories = ["COPD-minor", "COPD-major"]
    # outcome_key values must match the 'outcome' column in the bootstrap CSVs.
    outcomes = [
        ("All-cause mortality (HR)",   allcause, "bhatt_HR",  "esi_HR",
         hr_boot,  "all-cause"),
        ("Respiratory mortality (HR)", resp,     "bhatt_HR",  "esi_HR",
         hr_boot,  "respiratory"),
        ("Exacerbations (IRR)",        exac,     "bhatt_IRR", "esi_IRR",
         irr_boot, "exacerbations"),
    ]

    body_rows = []
    for outcome_label, src, ct_est_col, esi_est_col, boot_src, boot_key in outcomes:
        for cat in categories:
            r = _row_lookup(src, cat)
            ct_est_prefix  = ct_est_col.split("_")[0]     # "bhatt"
            esi_est_prefix = esi_est_col.split("_")[0]    # "esi"
            body_rows.append([
                outcome_label,
                dh.cat_label(cat),
                _fmt(r[ct_est_col],
                     r[f"{ct_est_prefix}_LCI"],
                     r[f"{ct_est_prefix}_UCI"]),
                _fmt(r[esi_est_col],
                     r[f"{esi_est_prefix}_LCI"],
                     r[f"{esi_est_prefix}_UCI"]),
                _pvalue_lookup(boot_src, boot_key, cat),
            ])

    headers = ["Outcome (metric)", "Category",
               "CT-based (95% CI)", "ESI-based (95% CI)",
               "CT vs ESI (p)"]
    tbl = dh.add_table(doc, headers, body_rows,
                       col_widths_in=[1.45, 1.10, 1.55, 1.55, 0.85])
    # Vmerge the outcome column so each outcome heading spans its two rows.
    dh.vmerge_col(tbl, col_idx=0, header_rows=1)

    # Legend
    dh.add_legend_from_sibling(doc, __file__, TABLE_NUM)
