"""Supplemental table numbering, in the order the text first cites them.

One list, read by both builders, so a main-text legend that points at a
supplemental table and the supplement's own headings cannot disagree.
Reordering it changes every number. The prose citations are literal, and
display_order.check stops the build until they match.
"""
SUPP_KEYS = ["baseline", "thresholds", "crossclass", "groups_vs_mdcopd", "risk_common_ref",
             "fev1", "discord_risk", "esi_by_ct"]


def supp_num(key):
    return f"S{SUPP_KEYS.index(key) + 1}"
