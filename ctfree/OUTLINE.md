# Outline — CT-free MD-COPD paper

Mapped against `manuscript/ESI manuscript draft v15 2026.8.31_PJC.docx`. Paragraph
numbers are v15's, for lifting text directly.

**Reuse verdict.** The Introduction and roughly half the Discussion carry over
with light edits, because v15 already motivates the work by CT being
unavailable. What has to be rebuilt is the objective statement, the Results,
the threshold-derivation Methods, and the Limitations. Call it 60% reuse of
prose, 100% reuse of Methods machinery, and a new Results section.

---

## Title

v15: *The Emphysema Severity Index: Representing CT Abnormalities in a
Multidimensional COPD Framework*

The new claim is not "representing CT abnormalities", which is the thing that
turned out to be only partly true. Something closer to:

> Preserving the diagnostic benefit of a multidimensional COPD framework
> without chest CT

---

## Abstract — REWRITE

Cannot be salvaged. Its Main Results sentence is the specific claim being
retired: *"The ESI-based framework reproduced the CT-based framework with 91%
agreement (κ=0.82), 88% sensitivity, and 94% specificity."* Per category that
agreement is 50.5% and 12.4%, and the reframe no longer needs the claim.

New arc: MD-COPD improves on the fixed ratio by correctly reclassifying two
groups; without CT that benefit is at risk; symptoms alone do not preserve it
because they mislabel high-risk participants as not having COPD; adding ESI
does preserve it.

---

## INTRODUCTION — REUSE ALMOST ENTIRELY

| v15 | disposition |
|---|---|
| 42, COPD is multidimensional | **verbatim** |
| 43, Bhatt framework; CT requirement constrains implementation | **verbatim**, already the exact motivation |
| 44, CT cost, radiation, availability | **verbatim** |
| 45, what ESI is | **verbatim** |
| 46, objective | **rewrite** |

Only the objective paragraph changes. It currently promises "preserving
diagnostic agreement and prognostic performance", which is the claim being
dropped. Replace with the three-way question: does MD-COPD improve on the
fixed ratio, is that improvement lost when CT is removed, and does ESI recover it.

Add one sentence naming the fixed ratio as the comparator, since v15 never
establishes a baseline and the reviewer who calls it "fixed ratio" is a coauthor.

---

## METHODS — REUSE, WITH TWO SECTIONS REPLACED

| v15 | disposition |
|---|---|
| 49, study design | light edit to the new objective |
| 51, COPDGene population | **verbatim** |
| 53, the original MD-COPD framework | **verbatim** |
| 55, ESI and how it is measured | **verbatim** |
| 56, threshold derivation by rpart + 10-candidate grid | **REPLACE** |
| 58, diagnostic subgroup definitions | expand to four schemas |
| 60, outcomes and models | **verbatim**; Cox, negative binomial, covariates all unchanged |
| 61, agreement metrics, binary | **REPLACE** |
| 62, association models | **verbatim** |
| 63, C-index and TOST equivalence | keep, demoted to secondary |
| 64, pairwise contrasts | keep or drop with old Table 3 |

**New Methods §: the four schemas.** Fixed ratio; MD-COPD with CT; MD-COPD
without CT; MD-COPD with ESI. State that airflow limitation is defined
identically in all four, so no participant changes pathway.

**New Methods §: fitting the CT-free schemas.** Replaces v15 ¶56. Both CT-free
schemas fitted to approximate the CT-based one by macro-averaged F1, over their
full parameter space including the count threshold, outcome-blind, 5×5
stratified cross-validation. Must state plainly why not κ: κ, mean recall and
the C-index each select the schema that labels 1,119 participants
AFL-only-noCOPD, a group carrying 6.6× respiratory mortality. This is a
methodological point worth making in its own right.

**New Methods §: nested comparison against the fixed ratio.** Fixed-ratio COPD
is exactly AFL-only-noCOPD ∪ COPD-major, so the models nest and the comparison
is a likelihood ratio test on 2 df.

---

## RESULTS — REBUILD, IN FOUR STEPS

Reuse ¶67 (cohort description) and ¶68 (ESI versus quantitative CT) verbatim as
the opening. Everything after is new, and follows the schema order.

**R1. The fixed ratio and what MD-COPD adds.** LR χ² = 110.2, 53.9, 162.4. The
gain comes from two reclassifications: 170 people called COPD with no excess
mortality (HR 0.90), 1,086 called non-COPD carrying HR 1.91. State that the
C-index gain is small (+0.009) and that the claim is correct reclassification,
not better prediction. *(New Table 1.)*

**R2. What is lost when CT is removed.** Symptoms alone lose 949 of 3,943
COPD-major, because 24.1% of that group qualifies only through a CT finding.
*(New Table 2, the label-flow table.)*

**R3. Symptoms alone predict better and mislabel.** Best C-index of any schema,
achieved by putting 1,119 people in AFL-only-noCOPD with 6.6× respiratory
mortality and 1.8× exacerbations. This is the paper's hardest comparison and it
goes in the Results, not buried in the Discussion.

**R4. ESI preserves both the labels and the discrimination.** AFL-only 0.94 with
every interval crossing 1; COPD-minor 1.94 against 1.91; COPD-major held at
3,803 against 3,943; discrimination slightly above the CT reference on all
three outcomes. Fitted rule is simpler than v15's: one ESI threshold at 1.25,
count of 2 of 4. *(New Table 3, risk by schema.)*

**Retire:** v15 ¶70–71 (agreement), ¶73–75 (framework-versus-framework), ¶77–78
(cross-classification). The cross-classification analysis may survive as a
supplement.

**Keep:** ¶80, secondary continuous-ESI analyses, as a short closing subsection.

---

## DISCUSSION — REUSE MORE THAN HALF

| v15 | disposition |
|---|---|
| 82, opening summary | rewrite to the new finding |
| **83, CT and spirometry interrogate different aspects** | **verbatim, and it anticipates the new argument**: *"The objective of this spirometric representation is therefore not to reproduce CT morphology, but to capture the functional consequences of structural abnormalities."* That sentence is now the thesis rather than a caveat |
| 84, ESI independent of bronchodilator response | **verbatim** |
| 85, ESI versus quantitative CT | **verbatim** |
| 86, discordant classifications | rewrite or drop |
| 87, cross-classification | drop or demote |
| **88, AFL-only-noCOPD behavior** | **promote**. Currently an aside; it is now a central result, since the AFL-only category is what separates an honest CT-free schema from a dishonest one |
| 89, continuous ESI | **verbatim** |
| 90, practical implications | **near-verbatim**, strengthen with the 949 |
| 91, limitations | **REWRITE** |

**New Discussion §: why discrimination is the wrong sole criterion.** The
symptoms-only schema wins every prediction metric and is unusable. Worth its
own paragraph; it generalizes beyond this paper.

**Limitations, rewritten.** Keep v15's threshold-validation and
airway-predominant points, both still true. Add: per-category agreement with
the CT classification is moderate at best, 50.5% for COPD-minor, and ESI is
flat across emphysema grades 0 to 2 where the criterion cuts; the count
threshold of 2 departs from Bhatt's rule of 3, applied equally to both CT-free
schemas; everything is COPDGene.

---

## CONCLUSIONS — REWRITE

v15 ¶93 concludes that ESI "preserved the contribution of the structural
domain". The supportable conclusion is narrower and more useful: MD-COPD's
advantage over the fixed ratio can be preserved without CT, but not by symptoms
alone, and ESI is what makes the difference.

---

## Tables and figures

| | |
|---|---|
| Table 1 | schema definitions and category counts, all four |
| Table 2 | label flow from MD-COPD to each CT-free schema |
| Table 3 | risk within each schema's categories, plus discrimination |
| Table 4 | fitted parameters and held-out macro-F1 |
| Figure 1 | alluvial plot, **reusable** with a third axis for the symptoms-only schema |
| Figure 2 | characteristics of concordant and discordant groups, **reusable as is** |

Supplement: most of S1–S18 survives. S4 baseline, S5 ESI versus quantitative
CT, S17 bronchodilator, and the continuous-ESI tables are untouched by the
reframe.
