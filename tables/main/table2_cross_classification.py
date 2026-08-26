"""Table 2 — Outcomes in the four cross-classification groups defined by
whether a participant meets COPD under each framework: Both-noCOPD (reference),
CT-only COPD (ESI missed), ESI-only COPD (Bhatt missed), Both-COPD.

Cols: Classification group | All-cause mortality HR (95% CI)
      | Respiratory mortality HR (95% CI) | Exacerbation IRR (95% CI)

Superscript letters after each estimate encode a compact-letter display of
pairwise significance among the three COPD subgroups within each outcome
column: groups sharing a letter did not differ significantly (single-step-
adjusted, multcomp). The Both-noCOPD reference is excluded from the pairwise
tests (its association with each COPD group is captured by the point estimate
in the same row).

Sources:
    manuscript_assets/Table_BhattOnly_vs_Both.csv         (all-cause + resp HR, n)
    manuscript_assets/Table_Exacerbations_Discordance.csv (IRR, n_analytic for IRR)
    manuscript_assets/Table_2_pairwise_contrasts.csv      (pairwise p among COPD subgroups)
"""
import csv
import os

from tables import docx_helpers as dh
from manifest import ASSETS

TABLE_NUM = "2"
TITLE = ("Mortality and exacerbation outcomes across the four "
         "cross-classification groups defined by concordance and discordance "
         "between the CT-based and ESI-based COPD definitions")

# Unicode superscript letters — Arial has these glyphs; simpler than modifying
# add_table to accept mixed-run inputs.
_SUP = {"a": "ᵃ", "b": "ᵇ", "c": "ᶜ"}
CLD_ALPHA = 0.05


def _load(csv_name):
    with open(os.path.join(ASSETS, csv_name)) as f:
        return list(csv.DictReader(f))


def _fmt(est, lci, uci):
    return f"{float(est):.2f} ({float(lci):.2f}–{float(uci):.2f})"


def _lookup(rows, group):
    for r in rows:
        if r["group"] == group:
            return r
    raise KeyError(f"Group {group!r} not found in table source rows: "
                   f"{[r['group'] for r in rows]}")


def _cld_three_groups(g1, g2, g3, p12, p13, p23, alpha=CLD_ALPHA):
    """Compact letter display for exactly three groups given the three
    pairwise p-values. Returns {group: letter_string}. Assigns the smallest
    number of letters needed so that: (a) any two groups sharing a letter
    have p >= alpha for their contrast, and (b) any two groups with no
    letter in common have p < alpha for their contrast."""
    def nonsig(p): return float(p) >= alpha
    a12, a13, a23 = nonsig(p12), nonsig(p13), nonsig(p23)
    if a12 and a13 and a23:                # all three indistinguishable
        return {g1: "a", g2: "a", g3: "a"}
    if not a12 and not a13 and not a23:    # all three distinct
        return {g1: "a", g2: "b", g3: "c"}
    # Exactly one non-sig pair (the pair sharing a letter) OR
    # exactly two non-sig pairs (one group bridges two clusters).
    if a12 and a13 and not a23:            # g1 ties g2 and g3; g2 ≠ g3
        return {g1: "ab", g2: "a", g3: "b"}
    if a12 and not a13 and a23:            # g2 ties g1 and g3; g1 ≠ g3
        return {g1: "a", g2: "ab", g3: "b"}
    if not a12 and a13 and a23:            # g3 ties g1 and g2; g1 ≠ g2
        return {g1: "a", g2: "b", g3: "ab"}
    if a12 and not a13 and not a23:        # only g1 ties g2
        return {g1: "a", g2: "a", g3: "b"}
    if not a12 and a13 and not a23:        # only g1 ties g3
        return {g1: "a", g2: "b", g3: "a"}
    if not a12 and not a13 and a23:        # only g2 ties g3
        return {g1: "a", g2: "b", g3: "b"}
    raise AssertionError("unreachable")    # covered above


def _compute_letters(pw_rows):
    """Load the pairwise-contrasts CSV and return
    {outcome_key: {group_name: 'a' | 'ab' | ...}}.
    outcome_key values in the CSV: 'all-cause mortality',
    'respiratory mortality', 'exacerbations'."""
    # Group source rows by outcome.
    by_outcome = {}
    for r in pw_rows:
        by_outcome.setdefault(r["outcome"], []).append(r)

    groups_expected = {"CT-only-COPD", "Both-COPD", "ESI-only-COPD"}
    letters_by_outcome = {}
    for outcome, rows in by_outcome.items():
        p_of = {}
        for r in rows:
            a, b = [s.strip() for s in r["contrast"].split(" - ")]
            p_of[frozenset([a, b])] = float(r["p_adj"])
        # We need exactly three pairs for three groups.
        assert len(p_of) == 3, (
            f"outcome {outcome!r}: expected 3 pairwise contrasts, got {len(p_of)}")
        g_seen = set()
        for pair in p_of:
            g_seen.update(pair)
        assert g_seen == groups_expected, (
            f"outcome {outcome!r}: contrast groups {g_seen} != {groups_expected}")
        g1, g2, g3 = "CT-only-COPD", "Both-COPD", "ESI-only-COPD"
        letters_by_outcome[outcome] = _cld_three_groups(
            g1, g2, g3,
            p_of[frozenset([g1, g2])],
            p_of[frozenset([g1, g3])],
            p_of[frozenset([g2, g3])])
    return letters_by_outcome


def _sup(letters_str):
    """Convert 'ab' → 'ᵃᵇ'."""
    return "".join(_SUP[ch] for ch in letters_str)


def build(doc):
    hr_data  = _load("Table_BhattOnly_vs_Both.csv")
    irr_data = _load("Table_Exacerbations_Discordance.csv")
    pw_rows  = _load("Table_2_pairwise_contrasts.csv")
    letters  = _compute_letters(pw_rows)

    # (display_label, src_key_for_hr/irr, key_used_in_pairwise_CSV)
    ordered_groups = [
        ("Both-noCOPD",                    "Reference",       None),
        ("CT-only-COPD (ESI missed)",   "CT-only-COPD", "CT-only-COPD"),
        ("ESI-only-COPD (Bhatt missed)",   "ESI-only-COPD",   "ESI-only-COPD"),
        ("Both-COPD",                       "Both-COPD",      "Both-COPD"),
    ]

    body_rows = []
    for src_key, display_label, pw_group in ordered_groups:
        if display_label == "Reference":
            body_rows.append([
                "Both-noCOPD",
                "Reference", "Reference", "Reference",
            ])
            continue
        hr = _lookup(hr_data, src_key)
        irr = _lookup(irr_data, src_key)
        all_letter  = _sup(letters["all-cause mortality"][pw_group])
        resp_letter = _sup(letters["respiratory mortality"][pw_group])
        exac_letter = _sup(letters["exacerbations"][pw_group])
        body_rows.append([
            display_label,
            _fmt(hr["all_HR"],  hr["all_LCI"],  hr["all_UCI"])  + all_letter,
            _fmt(hr["resp_HR"], hr["resp_LCI"], hr["resp_UCI"]) + resp_letter,
            _fmt(irr["IRR"],    irr["LCI"],     irr["UCI"])     + exac_letter,
        ])

    headers = [
        "Classification group",
        "All-cause mortality HR (95% CI)",
        "Respiratory mortality HR (95% CI)",
        "Exacerbation IRR (95% CI)",
    ]
    dh.add_table(doc, headers, body_rows,
                 col_widths_in=[1.7, 1.6, 1.6, 1.6])
    dh.add_legend_from_sibling(doc, __file__, TABLE_NUM)
