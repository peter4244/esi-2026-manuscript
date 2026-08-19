"""Supplemental Table S14: continuous ESI vs FEV1/FVC as predictors of
categorical outcomes (mortality + exacerbations).

For each of three outcomes (all-cause mortality [HR], respiratory mortality
[HR], exacerbations [IRR]), the fitted model is refit under three model
specifications: ESI only, FEV1/FVC only, and ESI + FEV1/FVC combined. The
rightmost column reports the likelihood-ratio test statistic and p-value
for the null hypothesis that adding continuous ESI to a model already
containing FEV1/FVC does not improve fit.

Companion table Supplemental Table 15 shows the same analysis for FEV1
decline (mL/yr), stratified by baseline lung-function stratum.
"""
from tables import docx_helpers as dh
from tables.supp._continuous_esi_common import load_and_filter

TABLE_NUM = "S14"
TITLE = ("Continuous ESI vs FEV1/FVC as predictors of mortality and "
         "exacerbations, and combined-model likelihood-ratio tests")


_OUTCOMES = [
    ("All-cause mortality",   "HR",  "Table_S6a_continuous_mortality.csv", "all-cause"),
    ("Respiratory mortality", "HR",  "Table_S6a_continuous_mortality.csv", "respiratory"),
    ("Exacerbations",         "IRR", "Table_S6b_continuous_exacerbations.csv", "exacerbations"),
]


def build(doc):
    headers = ["Outcome", "Metric", "Model",
               "ESI estimate (95% CI)", "ESI p",
               "FEV₁/FVC estimate (95% CI)", "FEV₁/FVC p",
               "LR vs FEV₁/FVC only"]
    body = []
    for display_outcome, metric, csv_name, outcome_label in _OUTCOMES:
        rows = load_and_filter(csv_name, outcome_label=outcome_label,
                               effect_prefix=metric)
        for r in rows:
            # rows are [model, ESI_estimate, ESI_p, FEV1FVC_estimate, FEV1FVC_p, LR_p]
            body.append([display_outcome, metric, r[0],
                         r[1], r[2], r[3], r[4], r[5]])
    # 8 columns with long headers ("ESI estimate (95% CI)", "FEV₁/FVC
    # estimate (95% CI)", "LR vs FEV₁/FVC only") won't fit in portrait 6.5"
    # without heavy header wrap. Landscape gives 10.3" of usable width.
    dh.begin_landscape(doc)
    tbl = dh.add_table(doc, headers, body,
                       col_widths_in=[1.30, 0.60, 1.30, 1.65, 0.70, 1.85, 0.70, 1.60],
                       max_width_in=dh.LANDSCAPE_CONTENT_WIDTH_IN)
    dh.vmerge_col(tbl, col_idx=0)
    dh.vmerge_col(tbl, col_idx=1)
    dh.add_legend_from_sibling(doc, __file__, TABLE_NUM)
    dh.end_landscape(doc)
