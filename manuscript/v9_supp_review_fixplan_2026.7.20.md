# v9 Supplement Review — Fix Plan (2026-07-20)

## Origin
Pete's 8-comment review of the v9 supplement docx (`ESI manuscript supplement v9 2026.7.19_PJC.docx`), collected in TaskCreate #45 before applying any fixes. This plan orders and details the fixes so they can be applied as a single coherent batch.

Constraint: the current v9 build state passes 19 foundation + 36 verification checks, main build 12 OK / 0 FAIL, supplement 36 OK / 0 FAIL. After the fixes the numbers may shift (verification tests will grow to cover the renamed S6 modules) but must not regress to any FAIL.

---

## Phase M1 — Renumber the S6 group (do FIRST)

**Rationale.** Item #5 renames four modules and their table numbers. Every later phase touches at least one of them, so doing this first prevents rework.

**Mapping.**

| Old module + TABLE_NUM         | New module + TABLE_NUM       |
| ------------------------------ | ---------------------------- |
| `s6a1_continuous_mortality_all` `S6a.1` | `s6a_continuous_mortality_all` `S6a` |
| `s6a2_continuous_mortality_resp` `S6a.2` | `s6b_continuous_mortality_resp` `S6b` |
| `s6b_continuous_exacerbations` `S6b`   | `s6c_continuous_exacerbations` `S6c` |
| `s6c_continuous_fev1_decline` `S6c`    | `s6d_continuous_fev1_decline` `S6d` |

**Files that change.**

- 4× rename of `tables/supp/*.py`
- 4× rename of the matching `*_legend.md` files
- 4× update of `TABLE_NUM` constant (and `TITLE` if the label appears)
- 4× update of the `**Supplementary Table SN. ...**` header inside each legend .md
- `manifest.py::SUPP_TABLES` — list entries renamed in place; order preserved
- `prose/05_results.md` — the marker `{{REFS:S6a.1,S6a.2,S6b,S6c}}` becomes `{{REFS:S6a,S6b,S6c,S6d}}`
- `tests/test_verification.py` — function names / assertions that reference old module names (`verif_s6a1_mortality_all`, `verif_s6b_exac`, `verif_s6c_stratum_display`) are updated
- **`tests/test_verification.py::verif_results_marker_resolution`** — the `must_contain` list at ~L411 includes the exact string `"Supplementary Tables S6a.1, S6a.2, S6b, and S6c"`; that expected phrase must become `"Supplementary Tables S6a, S6b, S6c, and S6d"` or the marker-resolution test will FAIL (**plan-agent blocker #1**)
- `tables/docx_helpers.py::format_label` docstring at ~L302 and `add_legend_from_sibling` docstring at ~L757 use `'S6a.1'` as illustrative examples — update to `'S6a'` for accuracy (cosmetic, non-blocking)
- `tests/test_foundation.py:265` — `bookmark_for("S6a.1") == "tbl_S6a_1"` is a generic dot-to-underscore rule check and **stays** as-is; no live table will use it after M1, but the assertion documents the general contract
- **DO NOT MODIFY** `build_supplement_v10_2_2026.7.19.py` — legacy archive of the v10.2 build; its 6 hardcoded `S6a.1`/`S6a.2` references reflect that historical state and must stay intact

**No content changes** in Phase M1 — this is a mechanical relabelling.

---

## Phase M2 — N-at-risk + p-value method in ST4/ST5 legends (items #3, #4)

**Rationale.** Pete's later comment (#4) supersedes the earlier suggestion (#3) that N-at-risk go into a table column: put N in the legend instead, keeping the table layout unchanged.

**Bhatt-category N-at-risk (verified from `manuscript_assets/Table_6.csv` row sums; **these are Bhatt-based category totals** — the row axis of Table 6 is `Bhatt`, so row-sums are the Bhatt-framework participant counts):**

- noCOPD:            4,225
- AFL-only-noCOPD:     170
- COPD-minor:        1,099
- COPD-major:        3,969
- Total:             9,463 ✓ (matches analytic-cohort N)

**Plan-agent blocker #2 fix:** the earlier draft mislabeled these as "CT-based." They are correctly labeled Bhatt-based (the framework whose category labels — AFL-only-noCOPD, COPD-minor, COPD-major — are the row axis in ST4/ST5). ESI-based framework totals differ (e.g. AFL-only-noCOPD n=84 under ESI). Legend text will say **"category totals (Bhatt-framework)"** to avoid ambiguity, not "CT-based."

**Implementation.**

1. Create `tables/supp/_bhatt_category_ns.py` — a single module exporting the 4 category Ns as a dict, so no other module hardcodes them.
2. **S4a, S4b, S4c legends**: append a sentence to each legend body, e.g.:
   `"Category totals (Bhatt-framework, at-risk before conditioning on cause-of-death classification): AFL-only-noCOPD n=170, COPD-minor n=1,099, COPD-major n=3,969."`
3. **S5 legend**:
   - Add p-value method line: `"P-values are Wald tests on the between-group slope contrasts from the mixed-effects model."`
   - Add the same at-risk sentence as S4.

**Framework caveat.** These Ns are the CT-based framework's category totals. The ESI-based framework has slightly different totals (e.g. AFL-only-noCOPD n=84). Since ST4/ST5 report both frameworks side-by-side, either (a) use CT-based Ns and say so in the legend, or (b) report both. Plan chooses (a) for concision — CT-based is the reference framework in the paper. **This is a call worth checking with Pete if the plan-agent flags it.**

---

## Phase M3 — vmerge on natural groupings (item #2)

**Rationale.** The plain rendering of the sensitivity + outcome-grouped tables repeats the row-header text ("all-cause" four times, then "respiratory" four times, etc.). Word can span these vertically with `w:vMerge` — `docx_helpers.vmerge_col` already does this and is used on Table 1. Apply to every supp table with a naturally grouped column.

**Concrete plan per table** (row counts *exclude* header):

| Table | Grouping column(s)                        | Rows per group | vmerge call                          |
| ----- | ----------------------------------------- | -------------- | ------------------------------------ |
| S3a   | col 0 (Outcome, 3 groups × 6) + col 1 (Framework, 6 groups × 3) | 6 / 3 | `vmerge_col(tbl, 0); vmerge_col(tbl, 1)` |
| S3b   | same as S3a                               | 6 / 3          | same                                 |
| S3c   | col 1 (Framework, 2 groups × 3)           | 3              | `vmerge_col(tbl, 1)` (col 0 has only 1 distinct outcome — merging would waste a full-column span but be visually fine; skip col 0) |
| S6d (new number for old S6c) | col 0 (Stratum, 3 groups × 2) | 2 | `vmerge_col(tbl, 0)` |
| S7    | col 0 (Baseline stratum, 2 groups × 2)    | 2              | `vmerge_col(tbl, 0)`                 |
| S8    | col 0 (Outcome, 2 groups × 2)             | 2              | `vmerge_col(tbl, 0)`                 |
| S9a   | col 0 (Outcome, 2 groups × 3)             | 3              | `vmerge_col(tbl, 0)`                 |

**Not merging** — S1, S2 (every row distinct), S4a/b/c (only one column repeats: the category header itself, and vmerge on a 3-row column doesn't gain much), S5, S6a/b/c (new numbers; new S6a and S6b are 3-row model tables where each row is distinct), S9b (no grouping).

**Validation.** After the vmerge, run a smoke test that:
- The table still has the correct visible cell count
- The vmerged column still shows its label once per group (not zero times, not still all N times)

This can be a lightweight visual eyeball step; the `docx_helpers.vmerge_col` implementation was reviewed in Phase G.

---

## Phase M4 — Small formatting fixes (items #1, #7, #8)

### M4a — Contrast separator (item #7)

`tables/supp/_pairwise_common.py::build_rows` currently emits contrast labels straight from the CSV column: `"Both-COPD - Bhatt-only-COPD"`. Because the category names themselves contain hyphens, the separator hyphen visually merges with them.

Fix: after loading, `.replace(" - ", " / ")` on the contrast label. Verified this yields: `"Both-COPD / Bhatt-only-COPD"`, `"Both-COPD / ESI-only-COPD"`, `"Bhatt-only-COPD / ESI-only-COPD"`. No collision with intra-category hyphens.

Applies to S9a and S9b (both use the shared helper).

### M4b — Strip TOC numbering (item #8)

`tables/docx_helpers.py::body_toc` currently prefixes each entry with ` 1. `, ` 2. `, …. Pete wants those gone — the "S1/S2/..." column already carries order.

Fix: drop the `f"{idx:>2}. "` run and remove the `enumerate(..., start=1)` numbering; iterate plainly.

**Ripple check:** the foundation test that exercises `body_toc` (if any) may assert the numbering prefix. Grep and adjust.

### M4c — S2 numbers-don't-fit (item #1)

Plan-agent's diagnosis (accepted): the wrap is almost certainly in the narrow numeric columns (LAA950, FEV1/FVC, ESI at 0.45"–0.50") whose values like `"8.29 (1.99)"` are ~11 characters ≈ 0.61" at Arial 8pt, against ~0.42" usable after cell padding.

**First-try fix (do this without asking):**
1. Change SD formatting from 2-decimal to 1-decimal for the wide-column values (`"8.29 (1.99)"` → `"8.3 (2.0)"` — 9 chars, ~0.50"). This is a display-only change (data unchanged in the source CSV).
2. Reduce `TABLE_BODY_FS` for S2 only from 10pt to 8pt via a temporary override.

**If step 1+2 still wraps** (inspect after render): switch S2 to landscape orientation via a `w:sectPr` section break so it gets the full 10" of landscape width. This is a bigger structural change — pause and confirm with Pete before applying.

**Inspection after render:** open the built supplement docx, verify S2 renders cleanly on all 8 data rows with no cell wrapping. Screenshot for reference.

---

## Phase M5 — Verify

1. `python3 build_manuscript.py` — expect 12 OK / 0 FAIL (unchanged)
2. `python3 build_supplement.py` — expect 38 OK / 0 FAIL (same 17 tables + 4 more OK entries only if the new module names produce 2 log entries each; likely 36 stays 36)
3. `python3 tests/test_foundation.py` — expect 19 PASS
4. `python3 tests/test_verification.py` — expect 36 PASS after updating S6-related module names in the test file
5. Open the resulting supp docx; visually spot-check:
   - S2 (still readable, no wraps after M4c)
   - S3a/b, S6d, S7, S8, S9a (vmerge collapses look right)
   - S9a/b contrast column (uses " / " now)
   - TOC (no leading "1., 2., 3." numbers, table-number column still leads)

---

## Ordering / dependency notes

- **M1 before M2**: legends for S6 modules use the new TABLE_NUM in their title line.
- **M1 before M3**: `manifest.SUPP_TABLES` order determines which module the vmerge_col docstring lookup uses.
- **M3 depends on the underlying `add_table` layout being stable** — no rewrites of add_table in this batch.
- **M4c (S2 fix) is the only genuinely uncertain step** — depends on inspection.

## Out-of-scope for this batch (deferred if raised in review)

- Any changes to figures (Figure 1, Figure 2) — Pete's list was supplement-only.
- Any changes to the main-manuscript prose beyond the marker rewrite in Item #5.
- Any restructuring of the supplement's overall composition (adding/removing tables beyond what #5 covers).

## Open questions — resolved by plan-agent review

1. **Q1 (CT vs ESI Ns for ST4/ST5)** — **Answered**: neither. Use Bhatt-framework row-sums from Table_6 (170 / 1,099 / 3,969), labeled "Bhatt-framework." Both blockers folded into M1/M2 above.
2. **Q2 (S3a Framework-column vmerge visually worse?)** — **Answered**: no, 6 spans of 3 rows each is a clear improvement. Keep the vmerge on both col-0 (Outcome) and col-1 (Framework) for S3a/S3b.
3. **Q3 (S4a/b/c vmerge?)** — **Answered**: skip. Those have 3 category rows with no repeated grouping column.
4. **Q4 (S2 fit deferred?)** — **Answered**: do not defer. First-try fix folded into M4c above (drop SD decimal + 8pt body font, then inspect; landscape only if that fails).
5. **Q5 (TOC-numbering removal downstream)** — **Answered**: safe. `body_toc` isn't tested against a leading integer, and no resolver reads it.
