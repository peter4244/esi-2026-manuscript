# Side analyses

Not part of the manuscript pipeline. Nothing here is read by the analysis
report, the claims registry or the document builders.

## Co-author report on replacement criteria -- WRITTEN 2026-09-07

**`replacement_criteria_2026.9.7.Rmd`** (rendered to `.html`) is the co-author
write-up. It recomputes everything below from source, checks itself against
`replacement_criteria_comparison.csv` (39 checks, all passing), and carries
three figures. Written against manuscript draft v1, at Pete's direction, rather
than waiting for the manuscript to be marked final.

### The question

If the two CT criteria are removed from MD-COPD, what should replace them?
The paper answers "ESI". This asks whether that is the right answer, and by
what standard.

### What was found (2026-09-07)

`replacement_criteria_comparison.R` fits every candidate by the same objective
over the same count grid and judges them on label agreement, recovery of the
group CT was needed for, and whether the AFL-only label survives.

| Replacement | AFL-only | CT-only recovered (of 833) | Held-out macro-F1 |
|---|---|---|---|
| MD-COPD (reference) | 275 | 833 | — |
| none | 1,108 | 0 | 0.721 |
| FEV1/FVC <= 0.62 | 608 | 443 | 0.758 |
| FEV1pp <= 67.5 | 771 | 300 | 0.742 |
| ESI >= 1.50 | 543 | 483 | 0.752 |
| LAA-950 >= 3.5 (has CT) | 521 | 490 | 0.733 |
| FEV1/FVC + ESI | 604 | 445 | 0.757 |

Three points the report should make:

1. **Macro-F1 and "recovers the right people" are different objectives, and
   the paper optimizes the first while arguing the second.** A second FEV1/FVC
   threshold beats ESI on held-out macro-F1 (0.758 vs 0.752) but recovers
   fewer of the CT-only COPD-major participants (443 vs 483). Quantitative CT,
   the actual structural measurement, scores worst but one on macro-F1 (0.733)
   while recovering the most (490). That is close to a proof that macro-F1 is
   the wrong lens for this question.

2. **Every spirometric replacement repairs the AFL-only label.** FEV1/FVC 0.95,
   ESI 0.96, FEV1pp 0.91, all with respiratory intervals covering 1, against
   6.37 with no replacement. The claim that removing CT breaks the label and a
   spirometric criterion repairs it is robust; a claim that ESI specifically is
   required is not.

3. **Reach is where ESI differs from a second FEV1/FVC threshold** -- not from
   spirometric alternatives in general. A second FEV1/FVC threshold must sit
   below 0.70 or it fires for everyone with airflow limitation and collapses
   AFL-only to exactly 0 (the circularity, demonstrated in
   `fevfvc_as_criterion.R`). Below 0.70 it therefore reaches 0 participants
   with preserved spirometry, against 183 for ESI. Combining both adds 13.

   **Corrected 2026-09-07 while writing the co-author report:** ESI is not the
   only CT-free criterion with reach. FEV1pp <= 67.5 reaches **318**
   participants with preserved spirometry, more than ESI's 183 (LAA-950
   reaches 853 but needs CT). The `reach_preserved` column of the CSV had this
   all along; the summary above did not. ESI's case against FEV1pp rests on
   what it reaches (483 CT-only COPD-major recovered against FEV1pp's 300),
   not on whether it reaches.

### Open question for the report

Whether the fitting objective should be recovery of the CT-identified group
rather than macro-averaged F1. That is a different paper-level decision and
was not made here.

### Scripts

- `fevfvc_as_criterion.R` — the circularity demonstration and the pairwise
  FEV1/FVC vs ESI comparison, with outcome models
- `replacement_criteria_comparison.R` — the full head-to-head; writes
  `replacement_criteria_comparison.csv`
- `replacement_criteria_2026.9.7.Rmd` — the co-author report; recomputes both
  scripts from source, renders three figures into `figures/`, and self-checks
  against `replacement_criteria_comparison.csv`
