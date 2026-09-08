# Reviewer report: CT-free MD-COPD manuscript, PJC version of 2026-09-08

Read as an external reviewer. Every number below was checked against the
artifacts in `assets/` or `side_analyses/`; the source is named in each item.

---

## Major

### 1. The argument for why FEV₁/FVC cannot be the replacement criterion is wrong as written, and it is the first thing a reviewer will attack

Discussion, paragraph 4:

> A minor criterion defined by an FEV₁/FVC threshold above 0.70 is met by every
> participant with airflow limitation, so the AFL-only category empties entirely
> and the correction the framework exists to make is destroyed.

That sentence is true, and it answers a question nobody asked. The obvious
proposal is a threshold *below* 0.70, and the paragraph's conclusion ("It cannot
be") does not follow for that case. From `side_analyses/replacement_criteria_comparison.csv`:

| Replacement | AFL-only n | CT-only COPD-major recovered (of 833) | Held-out macro-F1 |
|---|---|---|---|
| MD-COPD (reference) | 275 | 833 | reference |
| none | 1,108 | 0 | 0.721 |
| **FEV₁/FVC ≤ 0.62** | **608** | **443** | **0.758** |
| ESI ≥ 1.50 | 543 | 483 | 0.752 |

A second FEV₁/FVC threshold does not empty AFL-only, and it beats ESI on the
paper's own stated fitting objective. As the Discussion currently stands, a
reviewer who tries this obvious alternative finds the paper's stated reason for
excluding it is false, and finds the alternative wins on the paper's own metric.

The defensible answer exists and is not in the paper. A sub-0.70 FEV₁/FVC
threshold reaches **zero** participants with preserved spirometry, so it cannot
serve the COPD-minor pathway at all, where ESI reaches 183. It also recovers
fewer of the participants CT was needed for (443 against 483). Those two facts
are the argument. Recommend replacing the "it cannot be" framing with them.

Related: the paper optimizes macro-F1 but argues recovery of the CT-identified
group. Those are different objectives and they rank the candidates differently
(quantitative CT itself, the actual structural measurement, scores second worst
on macro-F1 at 0.733 while recovering the most, 490). This is worth one honest
sentence rather than leaving it for a reviewer to find.

### 2. The 82 participants ESI-MD-COPD moves in the opposite direction are never mentioned

From `assets/crossclass.csv`, ESI-MD-COPD assigns **82 of the 275** participants
MD-COPD calls AFL-only to COPD-major. NoCT-MD-COPD assigns none. They are in
Table 2 and nowhere in the prose.

This matters more than its size, because it is the paper's own error type. The
thesis is that AFL-only exists to withhold a diagnosis from participants with
airflow limitation and nothing else, and is defensible only while its members
are at low risk. ESI-MD-COPD gives a COPD diagnosis to 30% of the participants
MD-COPD says should not have one.

It also explains where the headline F1 gain comes from. For AFL-only,
NoCT-MD-COPD has perfect recall (275 of 275) and precision 0.25; ESI-MD-COPD has
recall 0.70 and precision 0.36. The improvement from 0.40 to 0.47 is bought
entirely with precision, at the cost of a third of the recall. Presenting it as
"outperformed ... in the airflow-limitation groups" without that is the kind of
thing a reviewer flags as selective.

### 3. The count threshold of 2 is presented as both a design decision and a fitted parameter

Methods, comparator classifications:

> Since the two CT minor criteria are not available for this classification, the
> number of criteria needed for a COPD-minor pathway diagnosis is reduced from 3
> to 2.

Methods, threshold determination, immediately after:

> thresholds needed to be determined for the number of minor criteria necessary
> for the COPD-minor pathway ... Final thresholds were based on macro-averaged F1.

A reader cannot tell whether 2 was chosen a priori for the stated reason or
selected by fitting. It was fitted (`assets/objective_selection.csv`), and the
choice is not robust to the objective: Cohen's κ selects **k = 3** with an ESI
threshold of 0.75, and mean per-category sensitivity selects k = 2 with an ESI
threshold of 3.0 and an AFL-only group of 954. The selected configuration
depends on the objective, and the objective was chosen by the authors.

The Discussion limitation ("The count threshold of two departs from the three of
the original framework") describes it as a modification, which reads as
prespecified. Pick one account and use it in all three places.

### 4. Discussion says 6.4, Results says 9.38, for what reads like the same quantity

Results:

> the crude rate ratio against its own no COPD group was 9.38 (95% CI: 5.00 to 21.95)

Discussion:

> that category carries 6.4 times the respiratory mortality of its own reference,
> and unadjusted its members died at 1.54 times the reference rate.

Checked: 6.37 is the **adjusted** respiratory hazard ratio
(`assets/schema_risk.csv`) and 1.54 is the **crude all-cause** rate ratio
(`assets/schema_crude.csv`). The sentence labels neither, and the word
"unadjusted" attached to 1.54 invites the reader to take 6.4 as the adjusted
version of the same outcome, which it is not. The unadjusted respiratory figure
is the 9.38 already given in Results. As written the two sections look like they
disagree.

### 5. The respiratory mortality estimates in Table 3 rest on very few events, and the counts are not shown

From `assets/discord_rates.csv`, respiratory death rates per 100 person-years
are 0.030, 0.091, 0 and 0.135 across the four groups. Back-calculated against
the all-cause deaths and rates, that is on the order of 11, 5, 0 and 8
respiratory deaths. The manuscript reports hazard ratios of 3.63 (1.20 to 11.02)
and 5.10 (1.92 to 13.55) from these, to two decimal places, and Table 3 gives
n and rates but no event counts.

Add respiratory and all-cause death counts as columns. A reviewer who works out
that a hazard ratio of 5.10 rests on eight deaths will trust the rest of the
paper less than one who was told.

### 6. "Misclassified" contradicts the paper's own limitation

Results, reclassification:

> NoCT-MD-COPD misclassified 833 of 3,809 COPD-major participants (21.9%) as
> AFL-only, whereas ESI-MD-COPD only misclassified 350

Discussion, limitations:

> all comparisons treat the CT-based classification as the reference, which is
> appropriate for asking whether it can be reproduced without CT but does not
> establish that it is correct.

If MD-COPD is not established as correct, disagreement with it is not
misclassification. The previous wording ("reclassified") was accurate and cost
nothing. The claim that the reclassification is an error is made properly
elsewhere, by the outcome data, and does not need to be smuggled into the verb.

---

## Moderate

### 7. Results overstates the FEV₁/FVC comparison; the Discussion has it right

Results: "FEV₁/FVC discriminated both criteria at least as well as ESI".
Discussion: "at least as well as ESI in almost every stratum".

From `assets/esi_ct_auc.csv`, FEV₁/FVC is higher in five of six stratum by
criterion combinations and lower in one: airway wall thickening within airflow
limitation, 0.745 against ESI's 0.746. The difference is trivial, but the
Results sentence as written is false and the Discussion sentence is true. Use
the Discussion's wording in both.

### 8. "No excess in either mortality outcome" for AFL-only under ESI-MD-COPD is not right for the crude estimates

Discussion: "Under ESI-MD-COPD the category largely holds, with no excess in
either mortality outcome".

From `assets/schema_crude.csv`, the crude all-cause rate ratio for that group is
**1.29 (1.05 to 1.55)**, which excludes 1. The adjusted all-cause (0.96), crude
respiratory (2.37) and adjusted respiratory (1.77) estimates all cover 1. The
sentence is right about three of four and wrong about the fourth, and the paper
elsewhere makes a point of reporting crude alongside adjusted. Say "no excess
after adjustment, and a modest crude excess in all-cause mortality".

### 9. Our estimates are attributed to Bhatt's paper

Results: "In the original report, the AFL-only MD-COPD group showed no excess on
any outcome, crude or adjusted."

The estimates being described are ours, computed in our cohort of 9,240
(`assets/schema_crude.csv`, `assets/schema_risk.csv`). They are consistent with
the original report, which is worth saying, but "in the original report" claims
they are Bhatt's published numbers. Recommend: "Under MD-COPD in this cohort,
the AFL-only group showed no excess on any outcome, crude or adjusted,
consistent with the original report."

### 10. A confidence interval with a lower bound of exactly 0 is never explained in the text

The MD-COPD AFL-only respiratory estimate is given as 1.76 (0 to 5.75) in both
Abstract and Results. A lower bound of exactly zero for a rate ratio is
arresting. The figure legends explain it ("An interval drawn open at its lower
end denotes a category in which a bootstrap resample can contain no events") but
the Methods and the text do not. One clause in the Statistical analysis section
would fix it. `assets/schema_crude.csv` also records that this estimate used 864
of 1,000 resamples, against 1,000 for the others; that should be stated
somewhere.

### 11. The continuous ESI paragraph is filed under a heading about the CT criteria

The final paragraph of "Relationship of ESI to the visual CT criteria" reports
continuous ESI against mortality and FEV₁ decline. It is not about the visual CT
criteria. It is also the only place in Results where ESI is analyzed as a
continuous predictor rather than as a criterion, and it is two sentences. Either
give it its own short heading or move it to the Supplement; as it stands it
reads like something that had nowhere else to go.

### 12. Abstract quotes one of the two preserved-spirometry AUC values

Abstract: "but not among those with preserved spirometry (0.56)". The two values
are 0.56 for visual emphysema and 0.61 for wall thickening. Results gives both.
Quoting the lower one alone in the Abstract slightly strengthens the claim.
"0.56 and 0.61" costs four characters.

---

## Minor and editorial

- **Naming is inconsistent.** Methods introduces the category as "Airflow
  Limitation (AFL)-only-noCOPD", the Figure 1 legend says "AFL-only-noCOPD", and
  everything else says "AFL-only". Pick one, and if it is "AFL-only" the Methods
  sentence should still explain that the label withholds a COPD diagnosis, since
  that is what the shortened name loses.
- **Table 3's legend defines "AFL-only"**, which does not appear anywhere in
  Table 3. Leftover boilerplate.
- **Study population repeats the exclusion chain from Methods.** "It follows the
  exclusion chain of the source MD-COPD report, which removes never-smokers, so
  the cohort is entirely ever-smokers" restates two Methods sentences. Results
  can just give the number.
- **Table 1 puts fixed-ratio COPD in the COPD-major column.** Defensible, since
  the nesting argument depends on it, but the column header says COPD-major and
  the fixed ratio has no such category. A footnote would prevent the reading
  that fixed ratio and MD-COPD agree on 4,084 versus 3,809 participants.
- **The Discussion's C-index paragraph is the strongest thing in the paper** and
  is buried seventh. It is the paragraph that survives review. Consider moving
  it ahead of the FEV₁/FVC paragraph.

---

## What holds up

Checked and correct: all Table 1 and Table 2 marginals reconcile against
`assets/crossclass.csv` and `assets/schema_labels.csv`; the 91.2% concordance
(729 of 799); the C-index claim that NoCT-MD-COPD ranks highest of the four
(`assets/schema_discrimination.csv`, 0.721 all-cause and 0.874 respiratory, and
the lowest exacerbation AIC); the FEV₁ decline claim that two of ten estimates
reach significance, both COPD-major under a CT-free classification, both in the
direction of slower decline (`assets/fev1_decline.csv`); the correlation figures
0.78 across the cohort and 0.08 within GOLD 0; and the crude and adjusted
estimates quoted for AFL-only under all three multidimensional classifications.

The two paragraphs revised in this version both read better than what they
replaced. The AFL-only outcomes paragraph in particular now states the stake
before the numbers, which is what it was missing.
