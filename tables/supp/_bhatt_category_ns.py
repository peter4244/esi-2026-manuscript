"""CT-framework category totals (N at risk), derived from Table_6.csv.

Previously these were hardcoded, with an assertion that compared the hardcoded
dict to a hardcoded cohort size. Both were stale after the ILD/Bronchiectasis
exclusion changed the analytic cohort from 9,463 to 9,402, and because the
assertion only compared one constant to another it could not detect that. The
legends of ST6-ST9 consequently stated at-risk denominators (1,099 COPD-minor,
3,969 COPD-major) that no table in the supplement reproduced.

They are now read from the cross-tabulation the supplement itself publishes, so
they cannot drift from it again.
"""
import csv
import os

from manifest import ASSETS

_ROW_LABELS = {
    "noCOPD":          "noCOPD",
    "AFL-only-NoCOPD": "AFL-only-noCOPD",
    "COPD-minor":      "COPD-minor",
    "COPD-major":      "COPD-major",
}


def _load():
    path = os.path.join(ASSETS, "Table_6.csv")
    with open(path) as f:
        rows = list(csv.DictReader(f))
    out = {}
    for r in rows:
        label = _ROW_LABELS.get(r["Bhatt"])
        if label is None:
            raise KeyError(f"Unexpected CT category in Table_6.csv: {r['Bhatt']!r}")
        out[label] = sum(int(v) for k, v in r.items() if k != "Bhatt")
    missing = set(_ROW_LABELS.values()) - set(out)
    if missing:
        raise KeyError(f"Table_6.csv is missing CT categories: {sorted(missing)}")
    return out


BHATT_CATEGORY_NS = _load()


def at_risk_sentence(include_noCOPD=False):
    """Legend-ready sentence enumerating the CT-framework category totals."""
    keys = ["AFL-only-noCOPD", "COPD-minor", "COPD-major"]
    if include_noCOPD:
        keys = ["noCOPD"] + keys
    return ", ".join(f"{k} n = {BHATT_CATEGORY_NS[k]:,}" for k in keys)
