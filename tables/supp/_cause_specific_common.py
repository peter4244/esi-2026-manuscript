"""Shared row-builder for cause-specific mortality Supplemental Tables 6, 7, and 8.

All three (CVD, cancer, other) use the same source CSV
(Table_CauseSpecific_byClass.csv) filtered by cause. This helper factors out
the shared row-construction logic so the three per-cause modules are minimal.
"""
import csv
import os

from manifest import ASSETS


def _fmt_p(p):
    p = float(p)
    return "<0.001" if p < 0.001 else f"{p:.2f}"


def _fmt_hr(hr, lci, uci):
    return f"{float(hr):.2f} ({float(lci):.2f}–{float(uci):.2f})"


CATEGORY_ORDER = ["AFL-only-NoCOPD", "COPD-minor", "COPD-major"]
CATEGORY_DISPLAY = {
    "AFL-only-NoCOPD": "AFL-only-noCOPD",
    "COPD-minor":      "COPD-minor",
    "COPD-major":      "COPD-major",
}


def load_cause_specific(cause):
    """Return list of rows for the given cause label (e.g. 'CVD', 'Cancer',
    'Other'), ordered by CATEGORY_ORDER."""
    with open(os.path.join(ASSETS, "Table_CauseSpecific_byClass.csv")) as f:
        rows = [r for r in csv.DictReader(f) if r["cause"] == cause]
    by_group = {r["group"]: r for r in rows}
    missing = [c for c in CATEGORY_ORDER if c not in by_group]
    if missing:
        raise KeyError(
            f"Table_CauseSpecific_byClass.csv cause={cause!r} missing group "
            f"rows {missing}; source-CSV drift — refuse to silently truncate."
        )
    return [by_group[c] for c in CATEGORY_ORDER]


def build_rows(cause):
    rows = load_cause_specific(cause)
    out = []
    for r in rows:
        out.append([
            CATEGORY_DISPLAY[r["group"]],
            r["n_events_bhatt"],
            _fmt_hr(r["bhatt_HR"], r["bhatt_LCI"], r["bhatt_UCI"]),
            _fmt_p(r["bhatt_p"]),
            r["n_events_esi"],
            _fmt_hr(r["esi_HR"], r["esi_LCI"], r["esi_UCI"]),
            _fmt_p(r["esi_p"]),
        ])
    return out


HEADERS = ["Category", "CT events", "CT HR (95% CI)", "CT p",
           "ESI events", "ESI HR (95% CI)", "ESI p"]
COL_WIDTHS = [1.15, 0.75, 1.25, 0.60, 0.80, 1.25, 0.60]
