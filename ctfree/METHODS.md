# Methods — CT-free MD-COPD paper

*(Pete's draft of 2026-09-08 20:56, adopted verbatim. Do not rewrite a
paragraph here; edit it in place or replace it with a version he supplies.)*

## Study design

The study examined whether the diagnostic benefit of the MD-COPD framework over the fixed ratio can be preserved when chest CT is unavailable. Three classifications were compared against MD-COPD: the fixed ratio alone, the NoCT classification, in which the CT criteria are removed, and the ESI classification, in which they are replaced by the Emphysema Severity Index (ESI).


## Study population

The analysis was performed using data from the COPDGene study (NCT00608764), a multicenter observational cohort of current and former smokers aged 45 to 80 years at enrollment with a smoking history of at least 10 pack-years. Baseline evaluation included standardized pre- and post-bronchodilator spirometry, chest CT imaging, symptom assessment, and longitudinal clinical follow-up. Individuals with pre-existing diagnosed interstitial lung disease or bronchiectasis were not analyzed. Following the source MD-COPD report, the never-smoking controls COPDGene also enrolled were excluded, as were participants without acceptable post-bronchodilator spirometry or a chest CT passing quality control. The analytic cohort is therefore entirely ever-smokers. Details of COPDGene study design, imaging protocols, and follow-up have been previously reported (17). Briefly, quantitative emphysema was measured as low attenuation area below −950 Hounsfield units (LAA-950) using Thirona software. CT visual emphysema and airway wall thickness were scored according to Fleischner Society criteria (18, 19). The Fleischner visual emphysema scale has six levels: none, trace, mild, moderate, confluent and advanced destructive. Visual emphysema was deemed to be present for scores of 2 or greater, corresponding to at least mild emphysema. Visually assessed airway wall thickening was deemed to be present for a visual score of 2, corresponding to definite wall thickening.


## The Emphysema Severity Index

ESI was calculated from absolute values of standard spirometric measurements, including peak expiratory flow (PEF), forced vital capacity (FVC), and forced expiratory flows (FEF) measured after expiration of 25%, 50%, and 75% of FVC (FEF25%, FEF50%, and FEF75%), using a previously validated algorithm (13, 14). ESI ranges from 0 to 10 and reflects expiratory flow-volume curve morphology independently of ethnic and anthropometric reference equations.


## The MD-COPD framework and comparator classifications

The MD-COPD framework (11) integrates three domains: spirometric airflow obstruction, respiratory symptoms, and CT-defined structural abnormalities. The major diagnostic criterion is post-bronchodilator FEV₁/FVC below 0.70. Five minor criteria comprise two structural criteria, visual emphysema (Fleischner assessment at least mild) and airway wall thickening (Fleischner assessment definite thickening) (18), together with three symptom criteria: modified Medical Research Council (mMRC) dyspnea score of 2 or greater, St. George's Respiratory Questionnaire (SGRQ) total score of 25 or greater, and chronic bronchitis. Participants meeting the major criterion together with at least one minor criterion are classified as COPD major pathway; participants meeting at least three of five minor criteria without the major criterion are classified as COPD minor pathway; participants meeting the major criterion alone are classified as Airflow Limitation (AFL)-only-noCOPD; and the remaining participants are classified as noCOPD. In participants with a comorbid cardiac condition, specifically coronary artery disease or congestive heart failure, whose symptoms may be explained as well or better by that condition, two of the three minor criteria required for the COPD minor pathway must be imaging-based.

Fixed ratio uses traditional COPD spirometric definition of post-bronchodilator FEV₁/FVC < 0.70. The NoCT classification drops the two CT criteria and keeps dyspnea, SGRQ and chronic bronchitis. Since the two CT minor criteria are not available for this classification, the number of criteria needed for a COPD-minor pathway diagnosis is reduced from 3 to 2. The ESI classification replaces the two CT criteria with a single ESI criterion, and 2 minor criteria are necessary for the COPD-minor pathway diagnosis. Participants with airflow limitation are therefore COPD-major or AFL-only under every classification, and participants without it are COPD-minor or noCOPD. Every disagreement between classifications comes from the minor criteria.


## Determination of diagnostic thresholds for comparator classifications

For the NoCT and ESI classifications, thresholds needed to be determined for the number of minor criteria necessary for the COPD-minor pathway, and for the ESI classification an ESI threshold needed to be determined for its use as a minor criterion. The objective of the fitting process was to approximate the MD-COPD labels as closely as possible. We explored thresholds using Cohen's κ, mean per-category sensitivity, and macro-averaged F1 as the selection criteria. Threshold selection used the MD-COPD labels only with five-fold cross validation to assess the recovery of the original labels. The difference in held-out macro-averaged F1 between the two CT-free classifications was tested with the corrected resampled t-test, which inflates the variance of the per-fold differences to account for the training sets shared between cross-validation folds. Mortality and exacerbation data were not considered for the threshold selection. Final thresholds were based on macro-averaged F1.


## Clinical outcomes

Clinical outcomes were all-cause mortality, respiratory mortality, and prospective exacerbation rate. Overall mortality was determined through longitudinal follow-up calls combined with Social Security Death Index searches. Cause-specific mortality was determined by a pre-specified adjudication process using a modified version of the Towards a Revolution in COPD Health (TORCH) criteria as previously described (20). Respiratory exacerbations were analyzed from the COPDGene Longitudinal Followup (LFU) program dataset. The specific COPDGene data files used are listed in the Supplement.


## Statistical analysis

Associations with clinical outcomes were assessed using Cox proportional hazards models (hazard ratio, HR) for all-cause and respiratory mortality and negative binomial regression models with a follow-up-year offset (incidence-rate ratio, IRR) for exacerbations. Covariates were age, sex, race, current smoking status, pack-years and body mass index; exacerbation models additionally adjusted for prior exacerbation frequency at baseline, consistent with the original MD-COPD report. Models were fitted separately for each classification.

Crude rate ratios are also reported, calculated as the observed event rate in each group divided by the observed rate in the common reference group. Intervals for the crude mortality ratios are exact conditional intervals for a ratio of Poisson rates. Exacerbation counts are overdispersed and clustered within participant, so their intervals are 95% percentile intervals from a subject resample bootstrap with B = 1,000 resamples, with the reference rate recomputed within each resample. No interval is reported for a group with fewer than 10 events; the rate ratio is given alone and flagged, since an interval built on a handful of deaths conveys precision the data do not carry.

All comparisons between the multidimensional classifications are made against a single common reference: the participants every multidimensional classification assigns to noCOPD. Every member of that group is noCOPD under each classification, so it shares no participant with any group it is compared against. A per-classification reference would differ in composition between classifications and estimates made against it would not be comparable, which is the comparison this study requires.

Annualized change in FEV₁ was estimated with linear mixed models over visits 1 to 3 with a random intercept per participant, adjusted for height, sex, race, age, smoking status and pack-years, the difference between groups being the interaction between follow-up time and group. Each model was fitted twice, the second adding baseline post-bronchodilator FEV₁ as the source MD-COPD report did. Baseline FEV₁ enters through its interaction with time, since a main effect would have the visit 1 outcome predicting itself.

Fixed-ratio COPD comprises the AFL-only and COPD-major categories of the MD-COPD framework, so the fixed-ratio model is nested within the four-category model; the two were compared by likelihood ratio test on 2 degrees of freedom. Discrimination was summarized with the C-index for the mortality outcomes (21) and the Akaike information criterion for exacerbations.

Agreement between classifications was assessed across the four diagnostic categories. All analyses were performed in R (version 4.5.2).
