# v9 rebuild plan — v2 (post second plan-agent review)
2026-07-19

Full rebuild of the ESI manuscript and supplement into a per-figure / per-table / per-prose-section workflow, modeled on the NMD supplement build (`~/claude_projects/nmd/paper/build_supplemental_figures_docx.js`).

- **v1 → v2:** 11 findings from the first plan-agent review folded in.
- **v2 additional patches:** 8 more findings from the second plan-agent review folded in (see "Second-review patches" section for the delta).

## Objective

Every table, figure, and prose section becomes an independent source artifact. A top-level orchestrator assembles them into the docx. Every future revision is "edit source → run build → verify" — no more surgical docx edits.

## Locked decisions

- **Target journal:** AJRCCM (Arial 11 pt body, US Letter, 1" margins, single-spaced, no line numbers). Baked into `style.R` and `docx_helpers.py` from day one.
- **Version:** Massimo's last was **v8**; rebuild becomes **v9**. Interim v9 through v10.2 files archive to `manuscript/Old/`.
- **Migration source (frozen):** `manuscript/ESI manuscript draft v10.2 2026.7.19_PJC.docx` + `manuscript/ESI manuscript supplement v10.2 2026.7.19_PJC.docx`. Accept-all any tracked changes / resolve any Word comments **before** Phase J starts. All new prose edits after Phase J happen in `.md` / `.py` sources, never in v10.2.
- **Figure code:** R (ggplot2). **Tables:** Python (python-docx). **Orchestrator:** Python.
- **Prose format:** Markdown (`.md`) per section, EXCEPT title/authors and the reference list which are Python modules emitting docx primitives directly (finding 7).

## Target directory layout

```
projects/ESI_2024/
├── figures/
│   ├── style.R                           ← single style module (theme, palette, sizes)
│   ├── validate_layout.R                 ← docx-scale readability check + text-in-canvas
│   ├── figure1_agreement/
│   │   ├── figure1_agreement.R
│   │   ├── figure1_agreement.png
│   │   └── figure1_agreement_legend.md
│   └── figure2_discordance/
│       ├── figure2_discordance.R
│       ├── figure2_discordance.png
│       └── figure2_discordance_legend.md
├── tables/
│   ├── docx_helpers.py                   ← extended: add_legend, marker resolvers
│   ├── main/
│   │   ├── table1_by_category.py          (exports TABLE_NUM, TITLE, build)
│   │   ├── table1_by_category_legend.md
│   │   ├── table2_cross_classification.py
│   │   └── table2_cross_classification_legend.md
│   └── supp/
│       ├── s1_thresholds.py + _legend.md
│       ├── s2_baseline.py + _legend.md            (transposed)
│       ├── s3_esi10_excluded.py + _legend.md      (only retained sensitivity)
│       ├── s4a_cvd.py + _legend.md
│       ├── s4b_cancer.py + _legend.md
│       ├── s4c_other.py + _legend.md
│       ├── s5_fev1_decline.py + _legend.md
│       ├── s6a1_continuous_mortality_all.py + _legend.md
│       ├── s6a2_continuous_mortality_resp.py + _legend.md
│       ├── s6b_continuous_exacerbations.py + _legend.md
│       ├── s6c_continuous_fev1_decline.py + _legend.md
│       ├── s7_esi_trajectory.py + _legend.md
│       ├── s8_hr_bootstrap.py + _legend.md
│       ├── s9a_pairwise_resp.py + _legend.md
│       └── s9b_pairwise_exac.py + _legend.md
├── prose/
│   ├── 02_abstract.md
│   ├── 03_introduction.md
│   ├── 04_methods.md
│   ├── 05_results.md
│   ├── 06_discussion.md
│   ├── 07_conclusion.md
│   └── supp_frontmatter.md               ← TOC section preamble, if any
├── prose_py/                              ← markdown-hostile sections as Python modules
│   ├── title_authors.py                  ← superscripted author markers, italic affiliations
│   └── references.py                     ← numbered list with DOI hyperlinks
├── build_manuscript.py                    ← top-level orchestrator (main)
├── build_supplement.py                    ← top-level orchestrator (supplement)
├── manifest.py                            ← ordered lists of prose, tables, figures
├── manuscript_assets/                     ← unchanged — CSVs from Rmd
└── esi_manuscript_analysis_2026.7.17.Rmd
```

Archive location: `manuscript/Old/` for retired v9-v10.2 docxs and one-off build scripts.

## Manifests (finding 1)

Explicit ordered lists in `manifest.py`; **never** rely on `sorted(glob(...))`:

```python
MAIN_PROSE_ORDER = [
    ("title_authors", "prose_py.title_authors"),   # Python module
    ("abstract",      "prose/02_abstract.md"),
    ("introduction",  "prose/03_introduction.md"),
    ("methods",       "prose/04_methods.md"),
    ("results",       "prose/05_results.md"),
    ("discussion",    "prose/06_discussion.md"),
    ("conclusion",    "prose/07_conclusion.md"),
    ("references",    "prose_py.references"),      # Python module
]

MAIN_TABLES = ["table1_by_category", "table2_cross_classification"]
FIGURES     = ["figure1_agreement", "figure2_discordance"]

SUPP_PROSE_ORDER = [
    ("title_and_toc", "prose_py.supp_title"),   # supplement title + author + auto-TOC
    ("frontmatter",   "prose/supp_frontmatter.md"),  # optional preamble; may be empty
]

SUPP_TABLES = [
    "s1_thresholds", "s2_baseline", "s3_esi10_excluded",
    "s4a_cvd", "s4b_cancer", "s4c_other", "s5_fev1_decline",
    "s6a1_continuous_mortality_all", "s6a2_continuous_mortality_resp",
    "s6b_continuous_exacerbations", "s6c_continuous_fev1_decline",
    "s7_esi_trajectory", "s8_hr_bootstrap",
    "s9a_pairwise_resp", "s9b_pairwise_exac",
]
```

Second-review nice-to-have 7: `SUPP_PROSE_ORDER` gives the supplement a single source of ordering truth for prose (title, TOC placeholder, frontmatter), separate from `SUPP_TABLES` which drives the table pass.

## Marker grammar (finding 2, tightened per second review finding 3)

Markers appear inline in prose. Grammar rules:

- `{{TABLE:N}}` → resolves to formatted "Table N" text (with internal hyperlink to the table's bookmark). N ∈ {1, 2}.
- `{{FIGURE:N}}` → "Figure N" text (hyperlinked). N ∈ {1, 2}.
- `{{REF:Sn}}` → "Supplementary Table Sn". `n` is a token matching `[A-Za-z0-9.]+` (allows `S6a.1`, `S3`, `S4b`).
- `{{REFS:Sn1,Sn2,Sn3}}` → "Supplementary Tables Sn1, Sn2, and Sn3" (**Oxford comma always**, "Tables" plural, "and" before last).
- `{{INSERT:tableN}}` / `{{INSERT:figureN}}` → embed the table/figure at this position by calling the artifact's `build(doc)` (tables) or embedding the PNG (figures).

**Resolution order:** the pipeline is **resolve markers first, then parse markdown**. `**{{TABLE:1}}**` becomes `**Table 1**` (bold hyperlink for "Table 1"). This means a marker cannot contain markdown syntax and vice versa; a marker resolves to plain text plus an optional inline hyperlink field.

**Escaping:** `\{{` renders as literal `{{`, and `\}}` renders as literal `}}`. To write the literal string `{{TABLE:1}}` in prose, write `\{{TABLE:1\}}`.

**Code fences:** marker resolution is **skipped inside triple-backtick fenced code blocks** (```). If prose needs to discuss marker syntax, wrap in a code block.

**Adjacent markers with no whitespace** (`{{TABLE:1}}{{TABLE:2}}`) render as `Table 1Table 2` — the resolver adds no padding. Author must include a space or "and" explicitly.

**Markers inside markdown link targets** (`[text]({{REF:S3}})`) — **prohibited**. Marker resolver errors if a `{{` appears between `](` and `)`. Rationale: internal hyperlinks are emitted by the marker, not by markdown link syntax; mixing produces malformed output.

**Newlines inside a marker** — prohibited. Marker resolver errors on `{{TABLE:\n1}}`.

**Ambiguity guard:** the resolver errors — does not silently pass through — on any unrecognized `{{…}}` token that survives parsing, so typos surface immediately.

## Contracts

### `figures/style.R`

Exports (single source of truth):
```r
NATIVE_W       <- 7.5           # inch (ggsave width)
CONTENT_W      <- 6.5           # inch (docx target)
BODY_FS_NATIVE <- 12            # native pt → 10.4 pt at 6.5" docx scale
HEADER_FS_NATIVE <- 14          # native pt → 12.1 pt at 6.5" docx scale
DOCX_READABILITY_FLOOR <- 9     # pt; validate_layout errors below this
PALETTE <- c(
  noCOPD            = "#7F7F7F",   # gray
  `AFL-only-noCOPD` = "#9467BD",   # purple
  `COPD-minor`      = "#FFB000",   # yellow
  `COPD-major`      = "#D62728",   # red
  `CT-based`        = "#1F77B4",   # blue
  `ESI-based`       = "#D62728"    # red
)
theme_esi()   # ggplot2 theme, Arial family, sizes from above
```

Rules:
- **No fontsize literals** anywhere in `figure*/*.R`.
- Every figure script `source("../style.R")` at top.
- Every figure script calls `validate_layout(fig, "figureN_*.png")` before `ggsave()`.

### Per-figure script (`figures/figureN_*/figureN_*.R`)

1. `source("../style.R")`
2. Read source CSV from `manuscript_assets/`.
3. Construct ggplot using `theme_esi()` and `PALETTE`.
4. `validate_layout()` — check every text run against the docx-scale readability floor and check that no text bleeds off canvas.
5. `ggsave()` to sibling PNG at NATIVE_W.

### Per-figure legend (`figureN_*_legend.md`)

Plain markdown:
```
**Figure N. <one-sentence title>.**

<legend body prose>

**Abbreviations:** HR, hazard ratio; IRR, incidence-rate ratio; ...
```

The bold first line is the caption title (rendered bold, inline with body). The `**Abbreviations:**` block is optional but present when any abbreviation appears in the figure or legend.

### `tables/docx_helpers.py`

Extended from current module. Existing (from v10.2 build): `add_table`, `vmerge_col`, `add_bookmark`, `add_internal_hyperlink`, `body_toc`, `set_cell_border`. New for v9:

```python
add_legend(doc, legend_body, table_or_fig_num, abbreviations=None) → Paragraph
    # renders "**Table N. <title>.** <body>. **Abbreviations:** ..."
    # NEVER emits a separate caption_note paragraph (v10.3 fix-list item 6)

resolve_markers(md_text, artifact_registry) → (md_text, list[insertions])
    # returns MD with {{TABLE:N}}, {{FIGURE:N}}, {{REF:Sn}}, {{REFS:...}}
    # substituted to plain text; {{INSERT:*}} deferred to a callback list

render_markdown_to_docx(doc, md_text, insertion_callbacks=None)
    # Standard markdown → docx primitives.
    # Supports: paragraphs, ## / ### headings, **bold**, *italic*,
    # single-line lists (- or 1.), inline code, unicode chars.
    # Does NOT support: nested lists, tables, images, fenced code,
    # blockquotes, footnotes (any of these needed → move to prose_py).
```

**MD → docx implementation strategy (second-review blocker 1):** hand-rolled walker using `markdown_it` (Python package `markdown-it-py`). Walker traverses the token stream and emits python-docx primitives per token type. Chosen over `pypandoc` because (a) no subprocess dependency, (b) preserves fine-grained control over run-level formatting, (c) integrates cleanly with `resolve_markers` (marker substitution happens on the raw MD text before tokenization). **Budget impact:** ~2-3 hours added to Phase G3 for the walker; sanity-checked against v10.2 prose in Phase K2.

`add_legend()` used for both **tables and figures** (finding 9). Legend rendering is a single primitive.

**No side effects at import (second-review should-fix 4):** every per-table and per-figure module must do all work inside `build(doc)`. Reading CSVs, opening files, or logging at module scope is prohibited — the two-pass TOC generator imports every supp module to read `TABLE_NUM` and `TITLE` constants, and side effects would run twice.

### Per-table module (`tables/main/tableN_*.py`, `tables/supp/sN_*.py`)

Each module exports **three symbols**:
```python
TABLE_NUM = "S3"                   # or "1" for main-manuscript tables
TITLE     = "Sensitivity analysis — ESI = 10 excluded"

def build(doc):
    """Append the table's legend + Table object + trailing spacer to `doc`.
    Order is FIXED: legend paragraph first (with bookmark), then Table,
    then empty spacer paragraph. Returns the Table object.
    """
```

`build_supplement.py` reads `TABLE_NUM` and `TITLE` from each module **without executing `build()`** to render the TOC first (finding 4 — two-pass). Then iterates in manifest order calling each `build(doc)`.

**No side effects at import** (second-review should-fix 4): a supp module must not open files, read CSVs, or log at import time — only inside `build(doc)`. Enforced by convention; violations surface as duplicated work when the TOC pass runs.

**TOC label formatting** (second-review should-fix 5): `TABLE_NUM` is a bare token (`"1"`, `"S3"`, `"S6a.1"`). The TOC generator formats:
- Main-manuscript tables (`TABLE_NUM = "1"` or `"2"`) → "Table 1", "Table 2"
- Supplement tables (starts with `S`) → "Supplementary Table S3", "Supplementary Table S6a.1"

The same formatter is used by `{{TABLE:1}}` / `{{REF:Sn}}` marker resolution so labels match everywhere.

Marker resolution: `{{INSERT:tableN}}` in prose maps directly to `tableN.build(doc)`. Legend and Table always emit together, in that order (finding 3).

### Per-table legend (`tableN_*_legend.md`)

Same schema as figure legends. Read by the module and passed to `add_legend()` inside `build(doc)`.

### `prose/*.md`

Standard markdown (paragraphs, `##` subheadings, `**bold**`, `*italic*`). Special inline markers from the grammar above.

Sub/superscript: use Unicode (`FEV₁`, `O₂`); no HTML tags. Non-breaking spaces and en/em dashes: preserved literally.

Non-covered features (deferred to `prose_py` if needed): numbered lists that must auto-increment, footnote-style references, tables inside prose, complex hyperlinks.

### `prose_py/title_authors.py` (finding 7 + R7)

Python module exposing `build(doc)`. Emits:
- Centered title paragraph.
- Author list with superscripted affiliation markers (`Peter J. Castaldi¹,²`).
- Italicized affiliation lines.
- Corresponding-author block.

Avoids the markdown-hostile parts of the title page.

### `prose_py/references.py`

Python module exposing `build(doc)`. Reads a `references_data.py` list (per-reference dict: `authors`, `title`, `journal`, `year`, `vol`, `pages`, `doi`) and emits:
- Numbered paragraphs (literal `1.`, `2.`, … prefix).
- DOI as an inline hyperlink where present.

Numbered references in v10.2 use literal digit prefixes; extracted verbatim into `references_data.py`.

### `build_manuscript.py` and `build_supplement.py`

Both scripts:
1. Import `manifest.py`.
2. Instantiate a fresh `Document()` with AJRCCM styles.
3. For the main manuscript: walk `MAIN_PROSE_ORDER`. For `.md` sections, call `render_markdown_to_docx(doc, resolve_markers(text, registry))`. For `.py` sections (title, references), import and call `.build(doc)`. `{{INSERT:*}}` markers trigger the table/figure module's `build(doc)` inline.
4. For the supplement: first pass reads `TABLE_NUM` + `TITLE` from each `SUPP_TABLES` module and builds the TOC (finding 4). Second pass calls each `.build(doc)` in manifest order.
5. **Per-artifact try/except (finding 6, extended per second-review blocker 2):** every `.build(doc)` call AND every `render_markdown_to_docx(doc, resolve_markers(...))` call is wrapped. On exception, a red-flagged paragraph `**[BUILD FAILED: <artifact-or-section> — <exc>]**` is inserted and the build continues. Applies to marker-resolver failures (unknown `{{REF:S99}}`, malformed `{{…}}`) as well as artifact failures. A per-run manifest is written to `build_log_v9.txt` listing which artifacts and prose sections succeeded / failed.
6. **First-pass TOC failure isolation (second-review should-fix 4):** the two-pass supplement build wraps each `importlib.import_module(...)` in try/except so a single broken supp module doesn't kill the entire TOC pass. Broken modules render as `[TOC ENTRY UNAVAILABLE: <module> — <exc>]`.
7. **Figure freshness check (finding 8, tightened per second-review should-fix 6):** before embedding `figureN.png`:
   - Compare PNG mtime to `figureN.R` mtime.
   - If PNG missing OR stale AND `Rscript` on PATH → run `Rscript figureN.R`; **fail-loud** on non-zero exit (build stops with the R script's stderr).
   - If PNG missing OR stale AND `Rscript` NOT on PATH → **fail-loud** with message: "Figure N is stale and Rscript is not on PATH. Install R or manually re-render the figure."
   - Never silently embed a stale PNG.
8. Save output.

## Migration strategy

### Freeze v10.2 (R6)

Before Phase J: verify no in-flight edits from Massimo. Accept-all any Word tracked changes in v10.2 (R8). Save the accepted version back to `Old/v10.2_frozen_2026.7.19.docx` as the immutable migration source. Route all further prose changes exclusively through the new `.md` / `.py` sources.

### Prose extraction

For each `MAIN_PROSE_ORDER` section:
- Copy v10.2 paragraphs verbatim into the corresponding `.md` file.
- Replace inline cross-references with markers:
  - "Table 1" → `{{TABLE:1}}`
  - "Figure 1" → `{{FIGURE:1}}`
  - "Supplementary Table S3" → `{{REF:S3}}` (or `{{REF:S3a}}`, etc.)
  - "Supplementary Tables S3a–c" → `{{REFS:S3a,S3b,S3c}}` (pre-v9-scope; after removing S3b/c this becomes `{{REF:S3}}`)
- Place `{{INSERT:tableN}}` and `{{INSERT:figureN}}` at the docx anchor positions.

Title/authors and references extracted into `prose_py/title_authors.py` and `prose_py/references.py` (finding 7).

### Tables

- **Table 1** — reads `Table_8_allcause.csv`, `Table_8_resp.csv`, `Table_Exacerbations_Bhatt.csv`. Merges C-index equivalence from `Table_1_Cindex_Equivalence.csv` into the legend body.
- **Table 2** — reads `Table_BhattOnly_vs_Both.csv` + `Table_Exacerbations_Discordance.csv`. Merges the three all-cause pairwise-contrast p-values from `Table_2_pairwise_contrasts.csv` into the legend body.
- **S1** — `Supp_Table_Thresholds.csv`.
- **S2** (transposed) — `Table_S2_baseline_characteristics.csv` with columns = strata, rows = characteristics.
- **S3** — `Table_S3_sensitivity.csv` filtered to `sensitivity == "ESI=10 excluded"`. S3b and S3c retired (v10.3 fix-list item 5).
- **S4a/b/c** — `Table_CauseSpecific_byClass.csv` filtered by cause.
- **S5** — `Table_BhattDecline.csv`.
- **S6a.1 / S6a.2** — `Table_S6a_continuous_mortality.csv` filtered by outcome.
- **S6b** — `Table_S6b_continuous_exacerbations.csv`.
- **S6c** — `Table_S6c_continuous_fev1_decline.csv`.
- **S7** — `Supp_Table_S7_ESI_trajectory.csv`.
- **S8** — `Supp_Table_HR_Difference_Bootstrap.csv`.
- **S9a / S9b** — `Table_2_pairwise_contrasts.csv` filtered by outcome.

Every module uses `docx_helpers.add_table()` with the same parameters — Table 1 and Table 2 will be visually indistinguishable (v10.3 fix-list item 3).

### Figures

- **Figure 1** — `figures/figure1_agreement/figure1_agreement.R`. Rebuild from `Table_6.csv`. Consumes `theme_esi()`, `PALETTE`. Runs `validate_layout`.
- **Figure 2** — `figures/figure2_discordance/figure2_discordance.R`. Port of existing R script; consumes `style.R`. Runs `validate_layout`.

Both figures internally consistent by construction (v10.3 fix-list item 2).

## Phase ordering

**Phase G — Foundation** (5–6 h — bumped from 2-3 h; MD-to-docx walker is real infrastructure per second-review blocker 1)
- G1 create directory skeleton + `manifest.py` scaffolding
- G2 write `figures/style.R` + `figures/validate_layout.R`
- G3 extend `tables/docx_helpers.py`:
  - `add_legend()` (tables and figures) — small
  - `resolve_markers()` — marker grammar per spec above; wrapped in try/except at call sites — small
  - `render_markdown_to_docx()` — hand-rolled walker over `markdown_it` tokens → python-docx primitives (~2-3 h; supports paragraphs, `##`/`###` headings, `**bold**`, `*italic*`, single-level `- `/`1. ` lists, inline `code`, unicode chars; explicit reject on nested lists, tables, images, fenced code, blockquotes, footnotes — those live in `prose_py/` if needed)
- G4 write `build_manuscript.py` + `build_supplement.py` skeletons — walk manifest with per-artifact try/except AND per-prose-section try/except (second-review blocker 2), mtime check with fail-loud paths (second-review should-fix 6), first-pass TOC import wrapped (second-review should-fix 4). Can produce empty docx from empty manifest.

**Phase H — Figures** (3–4 h — bumped for typical patchwork alignment issues)
- H1 port Figure 1 → `figures/figure1_agreement/figure1_agreement.R`, validators, PNG
- H2 port Figure 2 → `figures/figure2_discordance/figure2_discordance.R`, validators, PNG
- H3 write both legend `.md` files with abbreviation blocks

**Phase I — Tables** (6–8 h — realistic given 16 supp + 2 main tables)
- I1 write `tables/main/table1_by_category.py` + legend
- I2 write `tables/main/table2_cross_classification.py` + legend
- I3 write each of the 15 `tables/supp/*.py` + legend (S3b/c omitted per fix-list item 5; S2 transposed per item 4)

**Phase J — Prose migration** (4–6 h — realistic given docx-to-md extraction + 60-item reference list)
- J1 accept-all tracked changes in v10.2 (R8); save frozen source
- J2 extract 6 `.md` prose sections verbatim
- J3 write `prose_py/title_authors.py` and `prose_py/references_data.py` + `references.py`
- J4 insert markers where cross-references and table/figure anchors appear

**Phase K — Verification** (5–7 h — bumped per second-review should-fix 8; snapshot recorder + regenerator + diff utility are new infrastructure)
- K1 run `build_manuscript.py` — produces v9 draft docx
- K2 run `build_supplement.py` — produces v9 supplement docx
- K3 numeric verification (**strengthened per finding 5, further specified per second-review should-fix 5**):
  - Extract per-cell `(nearest-header, nearest-row-label, cell-text)` triples from v10.2 and v9 tables; diff.
  - Per-paragraph token diff of prose (v10.2 vs v9); ignore whitespace normalization.
  - Snapshot test per table script — one `.json` per table module living at `tests/snapshots/tables/<module_name>.json`, capturing the full rendered row/cell content. Regenerate via `python tests/regenerate_snapshots.py --module <name>` (or `--all`); requires manual review of the diff before committing. Snapshots are diffed on every `python build_manuscript.py` / `python build_supplement.py` run and fail the build on drift.
  - The snapshot recorder + regenerator + diff utility are new infrastructure written in K3 (2-3 hours by itself).
- K4 the nine Phase-E audit checks from v10.2 re-run against v9.
- K5 render Figures 1 and 2 at 6.5" docx scale; confirm docx-readable (≥ 9 pt effective) and stylistically matched.

**Phase L — Cleanup** (30 min)
- L1 move interim `v9`, `v10`, `v10.1`, `v10.2` (draft + supplement) → `manuscript/Old/`
- L2 move interim build scripts (`build_supplement_v10_2026.7.19.py`, `build_supplement_v10_2_2026.7.19.py`, scratchpad one-offs) → `manuscript/Old/scripts/`
- L3 write NEW v9 files to `manuscript/`:
  - `ESI manuscript draft v9 2026.7.19_PJC.docx`
  - `ESI manuscript supplement v9 2026.7.19_PJC.docx`
- L4 update project README (or CLAUDE.md pointer) to name `build_manuscript.py` + `build_supplement.py` as canonical entry points.

**Total realistic effort: 3–3.5 working days** (bumped from 2.5-3 after second review — Phase G MD-walker adds ~3 h, Phase K snapshot infrastructure adds ~2 h).

## Second-review patches (2026-07-19, folded in above)

Eight findings from the second plan-agent review:

- **[Blocker 1]** MD-to-docx walker committed to hand-rolled `markdown_it` approach; Phase G budget bumped from 2-3 h to 5-6 h.
- **[Blocker 2]** Marker resolver failures now wrapped in try/except; `render_markdown_to_docx(doc, resolve_markers(...))` gets same red-flag treatment as artifact `build(doc)`.
- **[Should-fix 3]** Marker grammar tightened: added `\}}` escape, resolution order rule ("resolve markers first, then parse markdown"), adjacent-marker semantics, prohibition of markers inside markdown link targets, prohibition of newlines inside markers.
- **[Should-fix 4]** Two-pass import: added "no side effects at import" convention; first-pass `importlib.import_module` wrapped in try/except with `[TOC ENTRY UNAVAILABLE]` fallback.
- **[Should-fix 5]** Snapshot tests specified: location (`tests/snapshots/tables/<module>.json`), regeneration procedure (`python tests/regenerate_snapshots.py --module <name>`), TOC label formatter shared with marker resolution.
- **[Should-fix 6]** Figure freshness check: fail-loud on missing `Rscript` on PATH; fail-loud on non-zero exit; never silently embed stale PNG.
- **[Nice-to-have 7]** `SUPP_PROSE_ORDER` added to `manifest.py` for supplement ordering.
- **[Nice-to-have 8]** Phase K effort estimate bumped from 3-5 h to 5-7 h; total 2.5-3 days → 3-3.5 days.

## Risks and mitigations

- **R1 — Numbers regression.** New docx-generation code reads same CSVs. Phase K3 catches via per-cell triple diff + snapshot tests.
- **R2 — Prose loss during migration.** Every paragraph copied verbatim into `.md` / `.py`; concatenated-source diff vs concatenated-v10.2 paragraphs should be zero up to markers.
- **R3 — Standard markdown → docx quirks.** Reference list and title/authors go to `prose_py/` (finding 7), avoiding the two markdown-hostile sections. Remaining sections use only paragraphs, `##` headings, `**bold**`, `*italic*` — all trivial. Non-standard features (`<sub>`, HTML) do not appear in v10.2 prose (verified during J2).
- **R4 — Figure re-render appearance change.** Figure 1 and 2 will look different from v10.2 and internally consistent with each other (that's the point). Any specific styling Massimo wanted preserved must be surfaced now.
- **R5 — Interim-version archival is one-way.** Phase L moves v9/v10/v10.1/v10.2 into `Old/`. Recoverable but not silently reversible. Confirmed with Pete.
- **R6 — Massimo/collaborator edits during rebuild.** v10.2 frozen at start of Phase J (accepted tracked changes → `Old/v10.2_frozen_2026.7.19.docx`). All new edits from J1 onward route through `.md` / `.py` sources.
- **R7 — Title/authors formatting.** Solved by `prose_py/title_authors.py` (Python module, not markdown).
- **R8 — Tracked changes / Word comments in v10.2.** Accept-all before extraction. Confirm the extraction operates on accepted-state text.
- **R9 — Journal formatting.** Target = **AJRCCM** (Arial 11 pt body, US Letter, 1" margins, single-space, no line numbers). Baked into `style.R` and `docx_helpers.py`. If target changes later, only these two modules need updating.

## Six approvals from v1 (already granted)

1. Directory layout — approved.
2. `style.R` sizes (BODY 12 pt native → 10.4 pt docx; HEADER 14 → 12.1 pt) — approved.
3. Palette (six named colors) — approved.
4. Prose marker syntax — approved (grammar tightened in this rewrite per finding 2).
5. `manuscript/Old/` archive — approved.
6. Plan-agent review — **done; all 11 findings folded into this rewrite**.

## What this eliminates from v10.3 fix list

Unchanged from v1 plan:

| v10.3 item | Resolution in v9 rebuild |
|---|---|
| 1. Abbreviation defs | Every legend `.md` has optional `**Abbreviations:**` block; `add_legend()` renders uniformly across all tables and figures |
| 2. Figure style consistency | Guaranteed — every figure sources `style.R`; `validate_layout` enforces the docx-readability floor |
| 3. Table 1 vs Table 2 style | Impossible to differ — both call `docx_helpers.add_table()` with identical parameters |
| 4. Table S2 layout | Transposed in `tables/supp/s2_baseline.py` |
| 5. Remove S3b, S3c | Not created; only `s3_esi10_excluded.py` exists |
| 6. Footnotes prohibited | `add_legend()` folds all note content into a single legend paragraph |
