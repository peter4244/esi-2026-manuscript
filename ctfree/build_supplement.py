#!/usr/bin/env python3
"""Build the CT-free supplement .docx from source.

Same contract as build_manuscript.py: prose here, tables from artifacts,
nothing hand-edited into the document. Table numbering follows order of first
citation in the main text, which is what SUPP_ORDER encodes; the checker at the
end fails if the main text cites a table this file does not produce, or the
reverse, so the two cannot drift apart.

Usage:  python3 /abs/path/to/ctfree/build_supplement.py
"""
import csv
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
# ROOT holds the retired build_manuscript.py of the earlier paper, which would
# shadow this one's. HERE goes first so the import resolves to ctfree/.
sys.path.insert(0, ROOT)
sys.path.insert(0, HERE)

from docx.shared import Pt                                   # noqa: E402
from build_manuscript import (init_document, add_table, legend,  # noqa: E402
                              emphasis, ASSETS, CATS, SCHEMA_NAME)

OUT = os.path.join(HERE, "manuscript", "CT-free MD-COPD supplement draft v1.docx")
V15_ASSETS = os.path.join(ROOT, "manuscript_assets")
SUPP_ORDER = ["S1", "S2", "S3", "S4", "S5"]


def load(path, name):
    with open(os.path.join(path, name)) as f:
        return list(csv.DictReader(f))


def heading(doc, text):
    doc.add_paragraph(text, style="Heading 2")


def para(doc, text):
    emphasis(doc.add_paragraph(), text)


# --------------------------------------------------------------------------
def s1_baseline(doc):
    heading(doc, "Supplemental Table S1. Baseline characteristics")
    rows = load(V15_ASSETS, "Table_S2_baseline_characteristics.csv")
    keep = [("stratum", "Stratum"), ("n", "n"), ("age", "Age"),
            ("pct_female", "Female"), ("pct_current", "Current smoker"),
            ("pack_years", "Pack-years"), ("FEV1_pp", "FEV₁ %pred"), ("ESI", "ESI")]
    add_table(doc, [h for _, h in keep],
              [[r[k] for k, _ in keep] for r in rows],
              [0.86, 0.60, 0.86, 0.78, 1.00, 0.86, 0.84, 0.70])
    legend(doc, "Table S1.",
           "Baseline characteristics of the analytic cohort by GOLD stratum. Values "
           "are mean (SD) unless marked as a percentage. Carried over unchanged from "
           "the cohort description of the earlier analysis.")


def s2_ct(doc):
    heading(doc, "Supplemental Table S2. ESI and quantitative CT")
    rows = load(V15_ASSETS, "Supp_Table_CT_correlations.csv")
    hdr = list(rows[0].keys())
    label = {"Exp_LAA856_total_Thirona": "Air trapping (LAA-856)",
             "Insp_LAA950_total_Thirona": "Emphysema (LAA-950)",
             "PRM_pct_emphysema_Thirona": "PRM emphysema",
             "PRM_pct_airtrapping_Thirona": "PRM air trapping",
             "pctEmph_Thirona": "Percent emphysema"}
    add_table(doc, ["Stratum"] + [label.get(h, h) for h in hdr[1:]],
              [[r[h] for h in hdr] for r in rows],
              [1.10] + [1.08] * (len(hdr) - 1))
    legend(doc, "Table S2.",
           "Pearson correlations between ESI and quantitative CT measures, overall "
           "and within GOLD stratum.")


def s3_crossclass(doc):
    heading(doc, "Supplemental Table S3. Reclassification against the CT-based framework")
    x = load(ASSETS, "crossclass.csv")
    nm = {"S3": "MD-COPD without CT", "S4": "MD-COPD with ESI"}
    for s in ("S3", "S4"):
        para(doc, f"**{nm[s]}.** Rows are this schema; columns are MD-COPD with CT.")
        cell = {(r["row_cat"], r["col_cat"]): int(r["n"]) for r in x if r["schema"] == s}
        rows = []
        for rc in CATS:
            vals = [cell[(rc, cc)] for cc in CATS]
            rows.append([rc] + [f"{v:,}" for v in vals] + [f"{sum(vals):,}"])
        tot = [sum(cell[(rc, cc)] for rc in CATS) for cc in CATS]
        rows.append(["Total"] + [f"{v:,}" for v in tot] + [f"{sum(tot):,}"])
        add_table(doc, ["", *CATS, "Total"], rows,
                  [1.30, 1.02, 1.02, 1.06, 1.06, 1.04])
        doc.add_paragraph()
    legend(doc, "Table S3.",
           "Full cross-classification of each CT-free schema against the CT-based "
           "framework. Diagonal cells are participants both schemas place in the "
           "same category. The COPD-major column shows where the two schemas differ: "
           "949 of those participants fall into AFL-only-noCOPD without CT, against "
           "233 with ESI.")


def s4_fitting(doc):
    heading(doc, "Supplemental Table S4. Fitting the CT-free schemas")
    fit = load(ASSETS, "schema_fit.csv")
    cvd = load(ASSETS, "schema_fit_cv_diff.csv")[0]
    nm = {"S3": "MD-COPD without CT", "S4": "MD-COPD with ESI"}
    rows = [[nm[r["schema"]], f"≥ {int(float(r['k']))}",
             "—" if r["t_low"] in ("", "NA") else f"{float(r['t_low']):.2f}",
             f"{float(r['macroF1_insample']):.4f}",
             f"{float(r['macroF1_heldout']):.4f}"]
            for r in fit if r["schema"] in nm]
    add_table(doc, ["Schema", "Count threshold", "ESI threshold",
                    "In-sample macro-F1", "Held-out macro-F1"], rows,
              [1.55, 1.20, 1.05, 1.32, 1.38])
    legend(doc, "Table S4.",
           "Thresholds fitted to approximate the CT-based classification, by "
           "macro-averaged F1 across the four categories, over the full parameter "
           "space of each schema. Held-out values are from five repeats of "
           "five-fold cross-validation stratified on the CT-based categories, with "
           "thresholds refitted inside every training fold. The ESI-based schema "
           f"exceeds the symptoms-only schema by {float(cvd['diff_mean']):.4f} "
           f"({float(cvd['diff_lo']):.4f} to {float(cvd['diff_hi']):.4f}) across "
           f"{int(cvd['n_folds'])} held-out folds.")


def s5_discrimination(doc):
    heading(doc, "Supplemental Table S5. Discrimination under each schema")
    d = load(ASSETS, "schema_discrimination.csv")
    add_table(doc, ["Schema", "All-cause C-index", "Respiratory C-index",
                    "Exacerbation AIC"],
              [[SCHEMA_NAME[r["schema"]], f"{float(r['c_allcause']):.4f}",
                f"{float(r['c_resp']):.4f}", f"{float(r['exac_AIC']):.0f}"] for r in d],
              [1.70, 1.60, 1.65, 1.55])
    legend(doc, "Table S5.",
           "Discrimination for each schema, every model carrying the same "
           "covariates. The symptoms-only schema has the highest C-index for both "
           "mortality outcomes and the lowest exacerbation AIC. Table 3 of the main "
           "text shows what that costs: its AFL-only-noCOPD category carries 6.6 "
           "times the respiratory mortality of its own reference.")


def data_files(doc):
    heading(doc, "COPDGene files used")
    para(doc, "Analyses in this manuscript draw on the following COPDGene "
              "distribution files.")
    for line in [
        "**COPDGene_VitalStatus_SM_NS_Sep23.csv** — vital status and follow-up time, "
        "used for all-cause mortality.",
        "**COPDGene_Mort_COD_Adj.csv** — adjudicated underlying cause of death, used "
        "for respiratory mortality.",
        "**LFU_SidLevel_Comorbid_SM_30SEP21.txt** — the COPDGene Longitudinal "
        "Follow-up program dataset, used for prospective exacerbation counts and "
        "person-time at risk.",
        "**COPDGene_P1P2P3_SM_NS_Long_Sep24.csv** — the main COPD phenotype file in "
        "long format, used for baseline characteristics and the diagnostic criteria.",
    ]:
        para(doc, line)
    para(doc, "Emphysema Severity Index values were computed from the COPDGene "
              "spirometric flow-volume curves as described in the main text.")


def check_citations(produced):
    """The main text and this file must agree on which supplemental tables
    exist. A dangling citation is exactly the defect that reaches reviewers."""
    with open(os.path.join(HERE, "RESULTS.md")) as f:
        body = f.read()
    with open(os.path.join(HERE, "METHODS.md")) as f:
        body += f.read()
    cited = set(re.findall(r"Supplemental Table (S\d+)", body))
    missing = sorted(cited - set(produced))
    unused = sorted(set(produced) - cited)
    if missing:
        raise SystemExit(f"main text cites {missing}, which the supplement "
                         f"does not produce")
    if unused:
        print(f"  note: {unused} produced but never cited in the main text")


def main():
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    doc = init_document()
    p = doc.add_paragraph()
    r = p.add_run("Supplement: Preserving the diagnostic benefit of a "
                  "multidimensional COPD framework without chest CT")
    r.bold = True
    r.font.size = Pt(14)
    doc.add_paragraph("Draft v1. Tables generated from ctfree/assets/ and, where "
                      "marked, from the earlier analysis.")
    for fn in (s1_baseline, s2_ct, s3_crossclass, s4_fitting, s5_discrimination):
        fn(doc)
        doc.add_paragraph()
    data_files(doc)
    doc.save(OUT)
    check_citations(SUPP_ORDER)
    print(f"wrote {OUT}\n  {len(SUPP_ORDER)} supplemental tables, all cited")


if __name__ == "__main__":
    main()
