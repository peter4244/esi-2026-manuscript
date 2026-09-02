# Methods — CT-free MD-COPD paper

Draft. Provenance is marked against `manuscript/ESI manuscript draft v15
2026.8.31_PJC.docx`: **[v15 ¶n]** means reused, verbatim or near, from that
paragraph. Unmarked sections are new. Every number is registered in
[CLAIMS.md](CLAIMS.md) and checked by `ctfree/verify.R`.

---

## Study design

*(replaces v15 ¶49, whose objective is the one being retired)*

The study examined whether the diagnostic benefit of the
MD-COPD framework over the fixed ratio can be preserved when chest CT is
unavailable. Three classifications were compared against
MD-COPD: the fixed ratio alone, NoCT-MD-COPD, in which the CT criteria are
removed, and ESI-MD-COPD, in which they are replaced by the Emphysema Severity
Index (ESI).

## Study population

**[v15 ¶51, verbatim]**

The analysis was performed using data from the COPDGene study (NCT00608764), a
multicenter observational cohort of current and former smokers aged 45 to 80
years at enrollment with a smoking history of at least 10 pack-years, together
with a smaller group of never-smoking controls. Baseline evaluation included
standardized pre- and post-bronchodilator spirometry, chest CT imaging, symptom
assessment, and longitudinal clinical follow-up. Individuals with
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

## The four classifications

*(new)*

We compared four ways of classifying the same participants (Table 1), and refer
to them throughout by the following names.

**Fixed ratio** uses post-bronchodilator FEV₁/FVC below 0.70 and nothing else.
**MD-COPD** is the framework of Bhatt and colleagues as published, and is the
reference the other two are compared against. **NoCT-MD-COPD** drops the two CT
criteria and keeps dyspnea, SGRQ and chronic bronchitis. **ESI-MD-COPD**
replaces the two CT criteria with a single ESI criterion.

The major criterion is the same in all four. It decides whether a participant
can be COPD-major or AFL-only-noCOPD, or instead COPD-minor or noCOPD, and no
minor criterion can move a participant between those two pairs. Participants
with airflow limitation are therefore COPD-major or AFL-only-noCOPD under every
classification, and participants without it are COPD-minor or noCOPD. Every
disagreement between classifications comes from the minor criteria.

NoCT-MD-COPD is included to show what ESI adds. Without it, any advantage of
ESI-MD-COPD over the symptom criteria could be credited to ESI when the
symptoms alone would have produced it.

## Fitting NoCT-MD-COPD and ESI-MD-COPD

*(new; replaces v15 ¶56, whose thresholds were fitted for a different purpose)*

NoCT-MD-COPD and ESI-MD-COPD both need thresholds, and both were fitted to match MD-COPD
as closely as possible.

MD-COPD counts five minor criteria and calls a participant
COPD-minor at three of them. NoCT-MD-COPD has three minor criteria
and ESI-MD-COPD has four, so three is no longer the
right cut-off for either. We refitted the count together with the ESI
threshold, and refitted both classifications the same way. Letting one adapt
and not the other would favor the one that adapted.

We fitted by maximizing the macro-averaged F1 across the four categories. This
weights each category equally, and within each category it penalizes both
missing participants who belong there and adding participants who do not. We
tried Cohen's κ and mean per-category sensitivity first and rejected both.
Neither penalizes adding participants. Both therefore chose a classification
that labels 1,119 participants AFL-only-noCOPD in order to capture the 170 who
belong there, and that category then carries 6.6 times the respiratory
mortality of its reference, which makes the label wrong. The C-index has the
same problem, so we report it in the Results rather than fitting to it.

Fitting used the MD-COPD labels only. No mortality or exacerbation data was
used to choose thresholds. The risk estimates in the Results are therefore a
separate test of the fitted classifications, not a restatement of how they were
fitted. We validated the fitting by cross-validation: five repeats of five
folds, stratified on the MD-COPD categories, refitting every threshold within
each training set and scoring it on the fold held out.

## Agreement between classifications

*(new; replaces v15 ¶61, which assessed agreement only at the binary level)*

We compared classifications across all four diagnostic categories rather than
as COPD versus no COPD. A binary comparison puts COPD-minor and COPD-major on
the same side of the line, and AFL-only-noCOPD and noCOPD on the other. Both of
the categories MD-COPD adds to the fixed ratio therefore disappear into the
merge, and disagreement within them cannot show. We report the full
cross-classification of NoCT-MD-COPD and ESI-MD-COPD against
MD-COPD.

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
report. Every classification was fitted with the same covariates, and every estimate
is expressed against that classification's own noCOPD category.

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
  in the original framework and applies to NoCT-MD-COPD and ESI-MD-COPD equally.
