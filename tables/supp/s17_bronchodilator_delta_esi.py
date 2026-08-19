"""Supplemental Table S17 — Change in ESI between paired pre- and
post-bronchodilator spirometry measurements."""
import os

from tables import docx_helpers as dh
from manifest import ASSETS

TABLE_NUM = "S17"
TITLE = ("ESI stability across paired pre- and post-bronchodilator "
         "spirometry")


def _parse(path):
    """Parse Supp_Bronchodilator_deltaESI.txt of the form
    key=value\\n... into a dict."""
    out = {}
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line or "=" not in line:
                continue
            k, v = line.split("=", 1)
            out[k.strip()] = v.strip()
    return out


def build(doc):
    data = _parse(os.path.join(ASSETS, "Supp_Bronchodilator_deltaESI.txt"))
    n     = int(data["n_paired"])
    mean_ = float(data["mean_delta"])
    sd_   = float(data["sd_delta"])

    headers = ["Statistic", "Value"]
    body = [
        ["Paired pre/post-bronchodilator measurements (N)",  f"{n:,}"],
        ["Mean ΔESI (post − pre)",                            f"{mean_:+.2f}"],
        ["Standard deviation of ΔESI",                        f"{sd_:.2f}"],
    ]

    dh.add_table(doc, headers, body,
                 col_widths_in=[4.00, 2.50])
    dh.add_legend_from_sibling(doc, __file__, TABLE_NUM)
