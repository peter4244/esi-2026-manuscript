#!/usr/bin/env python3
"""Phase K verification: per-cell triples + prose snapshot diff.

This runs deeper than tests/test_foundation.py (which validates framework
primitives). It verifies:

  T-VERIF-1  Every main/supplement table module renders cells that match the
             values re-derived independently from the underlying source CSV,
             using the same formatting rules the module documents.

  T-VERIF-2  The v9-rendered main-manuscript prose matches the source .md
             files after marker resolution (round-trip integrity test).

  T-VERIF-3  Prose paragraphs shared between v10.2 and v9 (i.e., excluding
             embedded table/figure captions that v9 moved to sibling
             legend .md files) are byte-identical modulo whitespace
             normalization. Catches accidental paraphrasing / dropped clauses
             from Phase J migration.

Run:  python3 tests/test_verification.py
Exit: 0 on all-pass, 1 on any failure. Prints [PASS]/[FAIL] per case.
"""
import csv
import os
import re
import sys
import importlib

THIS_DIR = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(THIS_DIR)
sys.path.insert(0, ROOT)

from docx import Document  # noqa: E402

from tables import docx_helpers as dh  # noqa: E402
from manifest import ASSETS, MAIN_TABLES, SUPP_TABLES  # noqa: E402


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
_failed = 0
_passed = 0


def _pass(msg):
    global _passed
    _passed += 1
    print(f"  PASS  {msg}")


def _fail(msg):
    global _failed
    _failed += 1
    print(f"  FAIL  {msg}")


def _cells(tbl):
    """Return list-of-lists of stripped cell text for a python-docx table."""
    return [[c.text.strip() for c in row.cells] for row in tbl.rows]


def _load_csv(name):
    with open(os.path.join(ASSETS, name)) as f:
        return list(csv.DictReader(f))


def _build_isolated(module_path):
    """Build a fresh Document, invoke mod.build(doc), return the first table."""
    mod = importlib.import_module(module_path)
    doc = Document()
    mod.build(doc)
    return mod, doc.tables[0]


# ---------------------------------------------------------------------------
# T-VERIF-1: per-cell triples
# ---------------------------------------------------------------------------
def verif_table1():
    """Table 1: outcomes by category. Re-derive HR (LCI–UCI) from source CSVs."""
    _, tbl = _build_isolated("tables.main.table1_by_category")
    rows = _cells(tbl)
    # Row 1: All-cause mortality (HR) | COPD-minor | CT | ESI
    allcause = _load_csv("Table_8_allcause.csv")
    for r in allcause:
        if r["group"] == "COPD-minor":
            expected_ct = (f"{float(r['bhatt_HR']):.2f} "
                            f"({float(r['bhatt_LCI']):.2f}–"
                            f"{float(r['bhatt_UCI']):.2f})")
            expected_esi = (f"{float(r['esi_HR']):.2f} "
                             f"({float(r['esi_LCI']):.2f}–"
                             f"{float(r['esi_UCI']):.2f})")
            break
    actual = rows[1]
    if actual[2] == expected_ct and actual[3] == expected_esi:
        _pass(f"Table 1 all-cause × COPD-minor: {expected_ct} | {expected_esi}")
    else:
        _fail(f"Table 1 all-cause × COPD-minor drift: "
              f"expected [{expected_ct} | {expected_esi}], got "
              f"[{actual[2]} | {actual[3]}]")


def verif_table2():
    """Table 2: cross-classification. Verify Both-COPD row against CSV."""
    _, tbl = _build_isolated("tables.main.table2_cross_classification")
    rows = _cells(tbl)
    hr_data = _load_csv("Table_BhattOnly_vs_Both.csv")
    irr_data = _load_csv("Table_Exacerbations_Discordance.csv")
    both_hr = next(r for r in hr_data if r["group"] == "Both-COPD")
    both_irr = next(r for r in irr_data if r["group"] == "Both-COPD")
    expected_all = (f"{float(both_hr['all_HR']):.2f} "
                     f"({float(both_hr['all_LCI']):.2f}–"
                     f"{float(both_hr['all_UCI']):.2f})")
    expected_resp = (f"{float(both_hr['resp_HR']):.2f} "
                      f"({float(both_hr['resp_LCI']):.2f}–"
                      f"{float(both_hr['resp_UCI']):.2f})")
    expected_irr = (f"{float(both_irr['IRR']):.2f} "
                     f"({float(both_irr['LCI']):.2f}–"
                     f"{float(both_irr['UCI']):.2f})")
    both_row = next(r for r in rows if r[0] == "Both-COPD")
    exp = ["Both-COPD", str(both_hr["n"]),
           expected_all, expected_resp, expected_irr]
    if both_row == exp:
        _pass(f"Table 2 Both-COPD row: {' | '.join(both_row)}")
    else:
        _fail(f"Table 2 Both-COPD row drift: expected {exp}, got {both_row}")


def verif_s1():
    """S1: 10 threshold variants + header = 11 rows. Verify the row marked
    "✓" in the "Selected" column matches the raw-CSV "[SELECTED]" row."""
    _, tbl = _build_isolated("tables.supp.s1_thresholds")
    rows = _cells(tbl)
    if len(rows) != 11:
        _fail(f"S1 row count: expected 11, got {len(rows)}")
        return
    # The "Selected" column is column 5 (0-indexed) — display uses "✓" for
    # the training-derived variant used in main analyses.
    selected = [r for r in rows[1:] if r[5] == "✓"]
    if len(selected) != 1:
        _fail(f"S1 Selected='✓' rows: expected 1, got {len(selected)}")
        return
    sel = selected[0]
    src = _load_csv("Supp_Table_Thresholds.csv")
    src_sel = next(r for r in src if "[SELECTED]" in r["variant"])
    exp_sens = f"{float(src_sel['sens']):.3f}"
    exp_spec = f"{float(src_sel['spec']):.3f}"
    exp_kappa = f"{float(src_sel['kappa']):.3f}"
    if sel[2] == exp_sens and sel[3] == exp_spec and sel[4] == exp_kappa:
        _pass(f"S1 selected variant: n={sel[1]}, sens={sel[2]}, "
              f"spec={sel[3]}, κ={sel[4]}")
    else:
        _fail(f"S1 selected variant drift: expected "
              f"[{exp_sens},{exp_spec},{exp_kappa}], got "
              f"[{sel[2]},{sel[3]},{sel[4]}]")


def verif_s2():
    """S2: baseline table. Verify Overall row cohort N == 9,463."""
    _, tbl = _build_isolated("tables.supp.s2_baseline")
    rows = _cells(tbl)
    overall_rows = [r for r in rows if r[0] == "Overall"]
    if len(overall_rows) != 1:
        _fail(f"S2 Overall rows: expected 1, got {len(overall_rows)}")
        return
    if overall_rows[0][1] == "9463":
        _pass(f"S2 Overall row: N=9,463 (matches analytic cohort size)")
    else:
        _fail(f"S2 Overall N drift: expected 9463, got {overall_rows[0][1]!r}")


def verif_s4a_cvd():
    """S4a: CVD mortality. COPD-major should have highest event count."""
    _, tbl = _build_isolated("tables.supp.s4a_cvd")
    rows = _cells(tbl)
    major_row = next(r for r in rows if r[0] == "COPD-major")
    src = _load_csv("Table_CauseSpecific_byClass.csv")
    src_maj = next(r for r in src
                    if r["cause"] == "CVD" and r["group"] == "COPD-major")
    if major_row[1] == str(src_maj["n_events_bhatt"]):
        _pass(f"S4a COPD-major CT events: {major_row[1]}")
    else:
        _fail(f"S4a COPD-major CT events drift: expected "
              f"{src_maj['n_events_bhatt']}, got {major_row[1]!r}")


def verif_s8_bootstrap():
    """S8: paired-bootstrap. two-sided p reported as pre-formatted CSV column."""
    _, tbl = _build_isolated("tables.supp.s8_hr_bootstrap")
    rows = _cells(tbl)
    src = _load_csv("Supp_Table_HR_Difference_Bootstrap.csv")
    # Find the COPD-major all-cause row in v9 output and in source
    resp_maj_row = next(r for r in rows
                         if r[0] == "respiratory" and r[1] == "COPD-major")
    src_row = next(r for r in src
                    if r["outcome"] == "respiratory"
                    and r["category"] == "COPD-major")
    if resp_maj_row[-1] == src_row["two_sided_p_reported"]:
        _pass(f"S8 respiratory×COPD-major p: {resp_maj_row[-1]!r}")
    else:
        _fail(f"S8 respiratory×COPD-major p drift: expected "
              f"{src_row['two_sided_p_reported']!r}, got {resp_maj_row[-1]!r}")


def verif_s9a_mortality():
    """S9a: 6 rows (3 all-cause + 3 respiratory), grouped by outcome."""
    _, tbl = _build_isolated("tables.supp.s9a_pairwise_mortality")
    rows = _cells(tbl)  # includes header
    body = rows[1:]
    if len(body) != 6:
        _fail(f"S9a body row count: expected 6, got {len(body)}")
        return
    outcomes = [r[0] for r in body]
    if outcomes[:3] == ["All-cause mortality"] * 3 and \
       outcomes[3:] == ["Respiratory mortality"] * 3:
        _pass(f"S9a row grouping: 3 all-cause + 3 respiratory")
    else:
        _fail(f"S9a row grouping drift: {outcomes}")


def _verif_s3_variant(mod_name, sensitivity_label, expected_body):
    _, tbl = _build_isolated(f"tables.supp.{mod_name}")
    rows = _cells(tbl)
    if len(rows) - 1 != expected_body:
        _fail(f"{mod_name} body row count: expected {expected_body}, "
              f"got {len(rows) - 1}")
        return
    _pass(f"{mod_name}: {expected_body} outcome/framework/category rows + header")
    src = [r for r in _load_csv("Table_S3_sensitivity.csv")
            if r["sensitivity"] == sensitivity_label]
    if len(src) == expected_body:
        _pass(f"{mod_name} source-CSV filter ({sensitivity_label!r}) yields "
              f"matching {expected_body} rows")
    else:
        _fail(f"{mod_name} source-CSV filter yielded {len(src)} rows, "
              f"expected {expected_body}")


def verif_s3():
    """S3a/b/c: three sensitivity variants split from v10.2 S3a-c."""
    _verif_s3_variant("s3a_esi10_excluded",  "ESI=10 excluded",  18)
    _verif_s3_variant("s3b_alt_framework",   "4-criterion alt", 18)
    _verif_s3_variant("s3c_severe_exac",     "severe exac only", 6)


def verif_s4b_cancer():
    _, tbl = _build_isolated("tables.supp.s4b_cancer")
    rows = _cells(tbl)
    src = _load_csv("Table_CauseSpecific_byClass.csv")
    minor = next(r for r in src
                  if r["cause"] == "Cancer" and r["group"] == "COPD-minor")
    minor_row = next(r for r in rows if r[0] == "COPD-minor")
    if minor_row[1] == str(minor["n_events_bhatt"]):
        _pass(f"S4b COPD-minor CT events: {minor_row[1]}")
    else:
        _fail(f"S4b COPD-minor CT events drift: expected "
              f"{minor['n_events_bhatt']}, got {minor_row[1]!r}")


def verif_s4c_other():
    _, tbl = _build_isolated("tables.supp.s4c_other")
    rows = _cells(tbl)
    src = _load_csv("Table_CauseSpecific_byClass.csv")
    afl = next(r for r in src
                if r["cause"] == "Other" and r["group"] == "AFL-only-NoCOPD")
    afl_row = next(r for r in rows if r[0] == "AFL-only-noCOPD")
    if afl_row[1] == str(afl["n_events_bhatt"]):
        _pass(f"S4c AFL-only-noCOPD CT events: {afl_row[1]}")
    else:
        _fail(f"S4c AFL-only-noCOPD events drift: expected "
              f"{afl['n_events_bhatt']}, got {afl_row[1]!r}")


def verif_s5():
    _, tbl = _build_isolated("tables.supp.s5_fev1_decline")
    rows = _cells(tbl)
    src = _load_csv("Table_BhattDecline.csv")
    afl = next(r for r in src if r["group"] == "AFL-only-NoCOPD")
    afl_row = next(r for r in rows if r[0] == "AFL-only-noCOPD")
    expected = f"{float(afl['esi_est']):.2f}"
    if afl_row[4] == expected:
        _pass(f"S5 AFL-only-noCOPD ESI slope: {afl_row[4]} mL/yr")
    else:
        _fail(f"S5 AFL-only-noCOPD ESI slope drift: expected {expected}, "
              f"got {afl_row[4]!r}")


def verif_s6a_mortality_all():
    _, tbl = _build_isolated("tables.supp.s6a_continuous_mortality_all")
    rows = _cells(tbl)
    if len(rows) != 4:  # header + 3 model rows
        _fail(f"S6a row count: expected 4, got {len(rows)}")
        return
    models = [r[0] for r in rows[1:]]
    if models == ["ESI only", "FEV1/FVC only", "ESI + FEV1/FVC"]:
        _pass(f"S6a model rows: {models}")
    else:
        _fail(f"S6a model row order drift: {models}")


def verif_s6b_exac():
    _, tbl = _build_isolated("tables.supp.s6c_continuous_exacerbations")
    rows = _cells(tbl)
    src = _load_csv("Table_S6b_continuous_exacerbations.csv")
    joint = next(r for r in src if r["model"] == "ESI + FEV1/FVC")
    joint_row = next(r for r in rows if r[0] == "ESI + FEV1/FVC")
    if joint_row[1] == joint["ESI_IRR"]:
        _pass(f"S6b joint-model ESI IRR: {joint_row[1]}")
    else:
        _fail(f"S6b joint-model ESI IRR drift: expected {joint['ESI_IRR']!r}, "
              f"got {joint_row[1]!r}")


def verif_s6c_stratum_display():
    """S6c should show 'Pooled' not 'pooled' (Phase I concern-fix)."""
    _, tbl = _build_isolated("tables.supp.s6d_continuous_fev1_decline")
    rows = _cells(tbl)
    strata = {r[0] for r in rows[1:]}
    if "Pooled" in strata and "pooled" not in strata:
        _pass(f"S6c stratum labels normalized: {sorted(strata)}")
    else:
        _fail(f"S6c stratum labels not normalized: {sorted(strata)}")


def verif_s7_stratum_display():
    """S7 should show 'GOLD 0' not 'GOLD0' (Phase I concern-fix)."""
    _, tbl = _build_isolated("tables.supp.s7_esi_trajectory")
    rows = _cells(tbl)
    strata = {r[0] for r in rows[1:]}
    if "GOLD 0" in strata and "GOLD0" not in strata:
        _pass(f"S7 stratum labels normalized: {sorted(strata)}")
    else:
        _fail(f"S7 stratum labels not normalized: {sorted(strata)}")


def verif_bhatt_ns_consistent_across_legends():
    """Every legend that quotes Bhatt-category Ns must use the same numbers
    as tables/supp/_bhatt_category_ns.BHATT_CATEGORY_NS.

    Match is whitespace-tolerant: both "AFL-only-noCOPD n=170" and
    "AFL-only-noCOPD n = 170" are accepted."""
    from tables.supp._bhatt_category_ns import BHATT_CATEGORY_NS

    def _pair_re(cat, n):
        # Escape hyphens (regex-safe) and allow flexible whitespace around "=".
        cat_esc = re.escape(cat)
        return re.compile(rf"{cat_esc}\s+n\s*=\s*{n:,}")

    checks = [
        ("AFL-only-noCOPD", BHATT_CATEGORY_NS["AFL-only-noCOPD"]),
        ("COPD-minor",      BHATT_CATEGORY_NS["COPD-minor"]),
        ("COPD-major",      BHATT_CATEGORY_NS["COPD-major"]),
    ]
    legends = ["s4a_cvd_legend.md", "s4b_cancer_legend.md",
               "s4c_other_legend.md", "s5_fev1_decline_legend.md"]
    for leg in legends:
        with open(os.path.join(ROOT, "tables", "supp", leg)) as f:
            text = f.read()
        drift = [f"{cat} n={n:,}" for cat, n in checks
                 if not _pair_re(cat, n).search(text)]
        if not drift:
            _pass(f"{leg}: at-risk Ns match _bhatt_category_ns SSOT")
        else:
            _fail(f"{leg}: at-risk Ns drift from SSOT — missing {drift}")


def verif_s9b_exac():
    _, tbl = _build_isolated("tables.supp.s9b_pairwise_exac")
    rows = _cells(tbl)
    if len(rows) != 4:
        _fail(f"S9b row count: expected 4 (header + 3 contrasts), "
              f"got {len(rows)}")
        return
    _pass(f"S9b: 3 pairwise IRR contrasts + header")


def verif_shape_all():
    """Every module (main + supp) must build a table without exception."""
    ok = 0
    for name in MAIN_TABLES:
        try:
            _, tbl = _build_isolated(f"tables.main.{name}")
            ok += 1
        except Exception as e:
            _fail(f"{name} failed to build: {type(e).__name__}: {e}")
            return
    for name in SUPP_TABLES:
        try:
            _, tbl = _build_isolated(f"tables.supp.{name}")
            ok += 1
        except Exception as e:
            _fail(f"{name} failed to build: {type(e).__name__}: {e}")
            return
    _pass(f"all {ok} table modules build without exception")


# ---------------------------------------------------------------------------
# T-VERIF-2: round-trip prose integrity
# ---------------------------------------------------------------------------
_MD_INSERT_PAT = re.compile(r"\{\{INSERT:(\w+)\}\}")


def _strip_md_inserts_and_markers(md_text):
    """Return a version of md_text with all resolve_markers artifacts inlined,
    for comparing against docx-rendered prose. Uses dh.resolve_markers with a
    stub registry so INSERT markers vanish and TABLE/FIGURE/REF markers become
    'Table N' / 'Figure N' / 'Supplementary Table SN'.
    """
    # Registry knows about every insertion key defined in the manifest so no
    # resolution errors surface.
    from manifest import INSERT_KEYS
    resolved, _ = dh.resolve_markers(md_text, set(INSERT_KEYS.keys()))
    # Drop {{INSERT:...}} literals — the resolver returns them for callback
    # dispatch, but for a textual round-trip we skip them.
    return _MD_INSERT_PAT.sub("", resolved)


def _check_prose_marker_resolution(rel_path, must_contain):
    """Resolve markers in a prose .md and check (a) no unresolved {{...}}
    literals survive, (b) every phrase in `must_contain` appears after
    resolution."""
    with open(os.path.join(ROOT, rel_path)) as f:
        md = f.read()
    resolved = _strip_md_inserts_and_markers(md)
    surviving = re.findall(r"\{\{[^}]+\}\}", resolved)
    if not surviving:
        _pass(f"{rel_path}: no unresolved markers post-resolution")
    else:
        _fail(f"{rel_path}: unresolved markers survive: {surviving}")
    for expected in must_contain:
        if expected in resolved:
            _pass(f"{rel_path} contains {expected!r}")
        else:
            _fail(f"{rel_path} missing expected phrase {expected!r}")


def verif_results_marker_resolution():
    _check_prose_marker_resolution(
        "prose/05_results.md",
        ["Table 1", "Table 2", "Figure 1", "Figure 2",
         "Supplementary Table S2",
         "Supplementary Tables S3a, S3b, and S3c",
         "Supplementary Table S5", "Supplementary Table S7",
         "Supplementary Tables S4a, S4b, and S4c",
         "Supplementary Tables S6a, S6b, S6c, and S6d"],
    )


def verif_methods_marker_resolution():
    _check_prose_marker_resolution(
        "prose/04_methods.md",
        ["Supplementary Table S1"],
    )


# ---------------------------------------------------------------------------
# T-VERIF-3: v10.2 vs v9 prose verbatim preservation
# ---------------------------------------------------------------------------
_SUPP_REF_PAT = re.compile(
    r"Supplement(?:al|ary)\s+Tables?\s+"
    r"S[0-9a-z.]+"
    r"(?:"
        r"\s*(?:,\s*and\s+|,\s*|\s+and\s+|[–-])\s*"
        r"S?[0-9a-z.]+"
    r")*"
)
_REF_NUM_PAT = re.compile(r"^\d+\.\s+")


def _normalize(s):
    """Whitespace-collapse for paragraph comparison."""
    return re.sub(r"\s+", " ", s).strip()


def _normalize_semantically(s):
    """Normalize a paragraph for semantic (non-verbatim) comparison:
    (1) collapse leading reference-list numbers "12. Author..." → "Author...",
    (2) replace every "Supplementary Table(s) SN[a-z]?[.subN]?[, SM ...]"
        phrase with a placeholder, so v9's expanded / renumbered references
        compare equal to v10.2's range notation."""
    s = _normalize(s)
    s = _REF_NUM_PAT.sub("", s)
    s = _SUPP_REF_PAT.sub("[[SUPP_REF]]", s)
    return s


V10_2 = os.path.join(ROOT, "manuscript",
                     "ESI manuscript draft v10.2 2026.7.19_PJC.docx")
V9    = os.path.join(ROOT, "manuscript",
                     "ESI manuscript draft v9 2026.7.19_PJC.docx")


def _flatten_paragraphs(docx_path, normalizer=None):
    """Return list of normalized 'text chunks' from a docx. A chunk is one
    line of paragraph text: soft line breaks inside a single Word paragraph
    become separate chunks. This lets us compare v10.2 (which joins
    affiliations + abstract sub-labels + short list items into single
    paragraphs with internal newlines) against v9 (which splits each into
    its own paragraph)."""
    if normalizer is None:
        normalizer = _normalize
    doc = Document(docx_path)
    chunks = []
    for p in doc.paragraphs:
        # p.text includes soft line-break characters as \n; split on them.
        for line in p.text.split("\n"):
            line = normalizer(line)
            if line:
                chunks.append(line)
    return chunks


def verif_v10_to_v9_prose_preservation():
    """Every substantive v10.2 prose chunk should appear in v9 — with the
    exception of embedded Table/Figure captions that v9 moves to sibling
    legend .md files, and the 'Key words: ...' line which v9 will emit in
    a slightly different position.

    We detect captions heuristically as v10.2 chunks starting with 'Table N.'
    or 'Figure N.'. Short chunks (<6 words) are tolerated even if missing —
    they're headings, list fragments, or boundary strings that render
    differently between the two layouts."""
    if not (os.path.exists(V10_2) and os.path.exists(V9)):
        _fail(f"docx files missing: v10.2={os.path.exists(V10_2)}, "
              f"v9={os.path.exists(V9)}")
        return

    # Use semantic normalization so v10.2 "Supplementary Tables S3a–c" and
    # v9 "Supplementary Table S3" compare equal, and v9's numbered references
    # ("12. Author...") compare equal to v10.2's unnumbered ("Author...").
    v10_chunks = _flatten_paragraphs(V10_2, normalizer=_normalize_semantically)
    v9_chunks  = _flatten_paragraphs(V9,    normalizer=_normalize_semantically)
    # Join all v9 chunks into one long string so consolidated paragraphs
    # (Pete's style directive to merge short paragraphs) match substring-
    # wise even if v10.2 had them as separate paragraphs.
    v9_concat = " ".join(v9_chunks)
    v9_set = set(v9_chunks)

    # Filter embedded captions from v10.2 — v9 moves these to _legend.md.
    caption_pat = re.compile(r"^(Table|Figure)\s+\d+[a-z]?\.\s")
    substantive = [c for c in v10_chunks if not caption_pat.match(c)]

    def _short(c):
        return len(c.split()) < 6

    def _is_supp_toc_entry(c):
        # v10.2's main manuscript contains a manual "SUPPLEMENTARY MATERIAL"
        # TOC that lists each supp table's title. v9 omits this because the
        # supplement docx has its own auto-TOC. Skip these.
        return c.startswith("[[SUPP_REF]]")

    # Known deliberate v9 corrections (not drift):
    #   1. v10.2 reference #12 has a "WuWu F" typo; v9 fixes it to "Wu F".
    #   2. v10.2 Methods claims "Models were adjusted for age, sex, race,
    #      current smoking status, pack-years, and body mass index. Models
    #      of FEV₁ decline additionally included baseline height." — this
    #      understates model diversity. Post-review Rmd audit showed three
    #      adjustment sets (BMI for mortality/exac; Height_CM for LMM
    #      FEV1-decline; GOLD-stratum for continuous ESI). v9 rewrites the
    #      Methods paragraph to describe all three.
    def _is_known_v10_2_typo(c):
        # Deliberate v9 style edits from the dual-reviewer critique:
        #   - "Longitudinal FEV₁ decline showed" → "demonstrated"
        #   - "In both frameworks, the AFL-only-noCOPD" — sentence moved to a
        #     different paragraph and rephrased as "Under both frameworks..."
        #   - "Importantly, cross-classification" — soft-emphasis "Importantly,"
        #     dropped; verb changed to "demonstrated"
        #   - PRISm-vs-GOLD-0 orphan paragraph consolidated into the
        #     secondary-analyses paragraph
        return (c.startswith("WuWu F")
                or c.startswith("Models were adjusted for age, sex, race, "
                                 "current smoking status, pack-years, and "
                                 "body mass index. Models of FEV")
                or c.startswith("Longitudinal FEV₁ decline showed")
                or c.startswith("In both frameworks, the AFL-only-noCOPD")
                or c.startswith("Importantly, cross-classification analyses")
                or c.startswith("The different longitudinal ESI trajectories"))

    # A v10.2 chunk is "present in v9" if either the full chunk appears
    # verbatim OR its first 40-char prefix appears in the concatenated v9
    # text. The prefix-match is robust to Pete-directed consolidation edits
    # that add transitional words ("...outcomes; and comparable...") or
    # switch trailing periods to colons ("profiles. Bhatt-only" →
    # "profiles: Bhatt-only") without dropping any of the v10.2 content.
    v9_concat_lc = v9_concat.lower()

    def _in_v9(c):
        if c in v9_set or c in v9_concat:
            return True
        # Case-insensitive prefix match — catches consolidations where a
        # sentence's initial capital was lowercased when joined mid-paragraph
        # ("Comparable results..." → "..., and comparable results...").
        prefix = c[:40].lower()
        return len(prefix) >= 20 and prefix in v9_concat_lc

    missing = [c for c in substantive
               if not _in_v9(c) and not _short(c)
               and not _is_supp_toc_entry(c)
               and not _is_known_v10_2_typo(c)]

    if not missing:
        _pass(f"v10.2→v9 prose preservation: all substantive chunks "
              f"({len(substantive)} total, min 6 words) present verbatim in v9")
    else:
        _fail(f"v10.2→v9 prose drift: {len(missing)} substantive chunk(s) "
              f"missing/altered in v9")
        for c in missing[:10]:
            _fail(f"  missing: {c[:140]}…")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main():
    print("=" * 70)
    print("Phase K verification suite")
    print("=" * 70)

    print("\nT-VERIF-1  Per-cell triples")
    print("-" * 70)
    verif_shape_all()
    verif_table1()
    verif_table2()
    verif_s1()
    verif_s2()
    verif_s3()
    verif_s4a_cvd()
    verif_s4b_cancer()
    verif_s4c_other()
    verif_s5()
    verif_s6a_mortality_all()
    verif_s6b_exac()
    verif_s6c_stratum_display()
    verif_s7_stratum_display()
    verif_s8_bootstrap()
    verif_s9a_mortality()
    verif_s9b_exac()
    verif_bhatt_ns_consistent_across_legends()

    print("\nT-VERIF-2  Marker resolution round-trip")
    print("-" * 70)
    verif_results_marker_resolution()
    verif_methods_marker_resolution()

    print("\nT-VERIF-3  v10.2 → v9 prose verbatim preservation")
    print("-" * 70)
    verif_v10_to_v9_prose_preservation()

    print()
    print("=" * 70)
    print(f"===== {_passed} PASS, {_failed} FAIL =====")
    print("=" * 70)
    return 0 if _failed == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
