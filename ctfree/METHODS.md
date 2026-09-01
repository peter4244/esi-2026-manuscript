# Methods — CT-free MD-COPD paper

Draft. Provenance is marked against `manuscript/ESI manuscript draft v15
2026.8.31_PJC.docx`: **[v15 ¶n]** means reused, verbatim or near, from that
paragraph. Unmarked sections are new. Every number is registered in
[CLAIMS.md](CLAIMS.md) and checked by `ctfree/verify.R`.

---

## Study design

*(replaces v15 ¶49, whose objective is the one being retired)*

The study was designed to determine whether the diagnostic benefit of the
MD-COPD framework over the fixed ratio can be preserved when chest CT is
unavailable. Three classifications were compared against the original CT-based
framework: the fixed ratio alone, an MD-COPD classification with the CT
criteria removed, and an MD-COPD classification in which the CT criteria are
replaced by the Emphysema Severity Index (ESI). Spirometric airflow
obstruction and the symptom criteria were unchanged throughout. The
comparisons were made at the level of the classification itself and at the
level of the risk each category carries.

## Study population

**[v15 ¶51, verbatim]**

The analysis was performed using data from the COPDGene study (NCT00608764), a
multicenter observational cohort of current and former smokers aged 45 to 80
years at enrollment with a smoking history of at least 10 pack-years, together
with a smaller group of never-smoking controls. Baseline evaluation included
standardized pre- and post-bronchodilator spirometry, chest CT imaging, symptom
assessment, and longitudinal clinical follow-up. Participants with complete data
required to construct all classifications were included. Individuals with
pre-existing diagnosed interstitial lung disease or bronchiectasis were not
analyzed. Details of COPDGene study design, imaging protocols, and follow-up
have been previously reported (17). Briefly, quantitative emphysema was measured
as low attenuation area below −950 Hounsfield units (LAA-950) using Thirona
software. CT visual emphysema and airway wall thickness were scored according to
Fleischner Society criteria (18, 19), and visual emphysema was deemed to be
present for scores of 1 or greater (where 1 = mild emphysema). Visually assessed
airway wall thickening was deemed to be present for a visual score of 2,
corresponding to definite wall thickening.

## The MD-COPD framework

**[v15 ¶53, verbatim]**

The MD-COPD framework (11) integrates three domains: spirometric airflow
obstruction, respiratory symptoms, and CT-defined structural abnormalities. The
major diagnostic criterion is post-bronchodilator FEV₁/FVC below 0.70. Five
minor criteria comprise two structural criteria, visual emphysema (Fleischner
assessment at least mild) and airway wall thickening (Fleischner assessment
definite thickening) (18), together with three symptom criteria: modified
Medical Research Council (mMRC) dyspnea score of 2 or greater, St. George's
Respiratory Questionnaire (SGRQ) total score of 25 or greater, and chronic
bronchitis. Participants meeting the major criterion together with at least one
minor criterion are classified as COPD major pathway; participants meeting at
least three of five minor criteria without the major criterion are classified as
COPD minor pathway; participants meeting the major criterion alone are
classified as Airflow Limitation (AFL)-only-noCOPD; and the remaining
participants are classified as noCOPD.

## The Emphysema Severity Index

**[v15 ¶55, verbatim]**

ESI was calculated from absolute values of standard spirometric measurements,
including peak expiratory flow (PEF), forced vital capacity (FVC), and forced
expiratory flows (FEF) measured after expiration of 25%, 50%, and 75% of FVC
(FEF25%, FEF50%, and FEF75%), using a previously validated algorithm (13, 14).
ESI ranges from 0 to 10 and reflects expiratory flow-volume curve morphology
independently of ethnic and anthropometric reference equations.

## The four classification schemas

*(new)*

Four classifications were applied to the same participants.

| | Schema | Major criterion | Minor criteria |
|---|---|---|---|
| 1 | Fixed ratio | FEV₁/FVC < 0.70 | none; COPD is airflow limitation |
| 2 | MD-COPD with CT | FEV₁/FVC < 0.70 | emphysema, wall thickening, dyspnea, SGRQ, chronic bronchitis |
| 3 | MD-COPD without CT | FEV₁/FVC < 0.70 | dyspnea, SGRQ, chronic bronchitis |
| 4 | MD-COPD with ESI | FEV₁/FVC < 0.70 | ESI, dyspnea, SGRQ, chronic bronchitis |

Schema 2 is the reference the other two multidimensional schemas approximate.
Schema 3 removes the CT criteria without replacing them, and so isolates what
ESI contributes over the symptom criteria it is bundled with; without it, a
comparison of schema 4 against schema 2 cannot distinguish the two.

The major criterion is identical in all four schemas. Because it alone
determines which pair of categories a participant can occupy, no participant
changes pathway between schemas: a participant with airflow limitation is
either COPD-major or AFL-only-noCOPD under every schema, and a participant
without it is either COPD-minor or noCOPD. All disagreement between schemas is
therefore within a pathway and arises solely from the minor criteria.

## Fitting the CT-free schemas

*(new; replaces v15 ¶56, whose thresholds were fitted for a different purpose)*

Schemas 3 and 4 were fitted to approximate schema 2. Removing two of five minor
criteria changes the scale of the minor-criterion count, so the count threshold
was refitted along with the ESI threshold, and both schemas were fitted over
their full parameter space by the same objective. Fitting one and not the other
would favor whichever was allowed to adapt.

The objective was the macro-averaged F1 across the four categories. Each
category is weighted equally, and precision is balanced against recall within
each. Cohen's κ and mean recall were tested first and rejected. Neither
penalizes over-calling a small category. Both therefore select a schema that
assigns 1,119 participants to AFL-only-noCOPD in order to capture the 170 who
belong there, and that category carries 6.6 times the respiratory mortality of
its reference. The C-index has the same weakness as a measure of schema
quality, and is reported in the Results rather than used for fitting.

Fitting used only the schema 2 labels. No mortality or exacerbation data
entered threshold selection, so the risk profiles reported in the Results are
an independent check rather than a restatement of the fit. Selection was
validated by repeated stratified cross-validation, five repeats of five folds
stratified on the schema 2 categories, with every threshold refitted inside
each training fold and scored on the held-out fold.

## Agreement between classifications

*(new; replaces v15 ¶61, which assessed agreement only at the binary level)*

Agreement was assessed across the four diagnostic categories, not the binary
COPD classification. A binary comparison merges COPD-minor with COPD-major and
AFL-only-noCOPD with noCOPD. Those merges hide disagreement in the two
categories MD-COPD adds to the fixed ratio, which are the categories at issue
here. We report the full cross-classification of each CT-free schema against
the CT-based framework, with concordance in each category and the direction of
reclassification.

## Clinical outcomes

**[v15 ¶60, trimmed to the outcomes analyzed here]**

Clinical outcomes were all-cause mortality, respiratory mortality, and
prospective exacerbation rate. Overall mortality was determined through
longitudinal follow-up calls combined with Social Security Death Index
searches. Cause-specific mortality was determined by a pre-specified
adjudication process using a modified version of the Towards a Revolution in
COPD Health (TORCH) criteria as previously described (20). Respiratory
exacerbations were analyzed from the COPDGene Longitudinal Followup (LFU)
program dataset. The specific COPDGene data files used are listed in the
Supplement.

## Statistical analysis

**[v15 ¶62, adapted]**

Associations with clinical outcomes were assessed using Cox proportional
hazards models (hazard ratio, HR) for mortality and negative binomial
regression models with a follow-up-year offset (incidence-rate ratio, IRR) for
exacerbations. Covariates were age, sex, race, current smoking status,
pack-years and body mass index; exacerbation models additionally adjusted for
prior exacerbation frequency at baseline, consistent with the original MD-COPD
report. Every schema was fitted with the same covariates, and every estimate is
expressed against that schema's own noCOPD category.

Crude rate ratios are reported beside the adjusted estimates. The adjusted
estimate gives the contribution of the classification after the covariates. The
crude ratio gives the event rate participants in that category actually had.
For AFL-only-noCOPD the crude ratio is the one that matters, because that
category asserts the participants in it do not have COPD. Crude intervals are 95% percentile
intervals from a subject resample bootstrap (B = 1,000) in which the reference
rate is recomputed within every resample. A resample in which a category
contributes no events is retained as a draw with a rate ratio of zero; only
resamples in which the reference contributes no events leave the ratio
undefined and are discarded. Discarding zero-event draws truncates the interval
from below and can place a lower bound above 1 on the strength of a single
event.

All analyses were performed in R (version 4.5.2).

## Comparison with the fixed ratio

*(new)*

Fixed-ratio COPD comprises exactly the AFL-only-noCOPD and COPD-major
categories of the MD-COPD framework, so the fixed-ratio model is nested within
the four-category model. The two were therefore compared by likelihood ratio
test on 2 degrees of freedom rather than by comparing summary measures from
unrelated models. Discrimination was summarized with the C-index for the
mortality outcomes (23) and the Akaike information criterion for exacerbations.

---

## Still to write

- Supplement section listing the COPDGene data files, carried over from v15.
- Whether the FEV₁ decline outcome is retained; the analysis here does not use it.
- Justification for the count threshold of 2, which departs from the rule of 3
  in the original framework and applies to schemas 3 and 4 equally.
