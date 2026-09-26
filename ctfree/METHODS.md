# Methods — CT-free MD-COPD paper

*(Massimo's draft of 2026-09-20, adopted as the baseline, with Pete's PJC edits through
2026-09-26. Do not rewrite a paragraph here; edit it in place or replace it with a version he supplies.)*

## Study population

We analyzed data from COPDGene (NCT00608764), a multicenter observational cohort of current and former smokers aged 45–80 years with ≥10 pack-years of smoking (17). Baseline evaluation included pre- and post-bronchodilator spirometry, chest CT, and symptom assessment. Participants with diagnosed interstitial lung disease or bronchiectasis, never-smokers, or without acceptable post-bronchodilator spirometry or CT passing quality control were excluded. The analysis included 9,240 participants with MD-COPD classification and baseline post-bronchodilator ESI. Mortality analyses included 9,238 participants with complete follow-up and covariates and exacerbation analyses 8,177 with longitudinal exacerbation data and complete covariates.

## MD-COPD classification

Participants were classified according to the published MD-COPD framework (11). The major criterion was post-bronchodilator FEV₁/FVC <0.70. Minor criteria were visually assessed emphysema of at least mild severity, definite airway wall thickening, modified Medical Research Council (mMRC) dyspnea score ≥2, St. George's Respiratory Questionnaire (SGRQ) total score ≥25, and chronic bronchitis. Participants meeting the major criterion with ≥1 minor criterion were classified as COPD-major and those meeting the major criterion alone as airflow limitation only (AFL-only). Without the major criterion, COPD-minor required ≥3 minor criteria; all others were classified as noCOPD.

Quantitative emphysema was expressed as the percentage of lung below −950 Hounsfield units at inspiration (%LAA-950HU), measured with Thirona software. Visual emphysema and airway wall thickening were assessed according to Fleischner Society criteria (18, 19), with emphysema considered present at ≥mild severity and airway wall thickening when definite; these constituted the two imaging minor criteria of MD-COPD. Further details of visual CT assessment are provided in the Supplemental Methods.

## ESI and modified classifications

ESI is a continuous spirometric index originally developed to assess the physiological expression of emphysema and evaluated against quantitative CT measures of emphysema (13, 14). Its algorithm combines absolute measurements of peak expiratory flow (PEF), FVC, and expiratory flows at 25%, 50%, and 75% of FVC into a value ranging from 0 to 10, representing increasing alteration of the morphology of the expiratory portion of the flow-volume curve. Because ESI uses absolute spirometric measurements, it does not require ethnic or anthropometric reference equations. Baseline post-bronchodilator ESI was used for classification.

Two modified MD-COPD classifications were evaluated. NoCT removed the two CT criteria, retaining the three symptom-based minor criteria. The ESI classification added ESI to these three criteria to represent the CT component.

For the two modified classifications, the number of minor criteria required for COPD diagnosis was derived from concordance with the four MD-COPD categories without using outcome data. Candidate thresholds were evaluated by five-fold cross-validation repeated five times using Cohen's κ, mean per-category sensitivity, and macro-F1 (the mean across the four categories of the harmonic mean of sensitivity and positive predictive value). Final thresholds were selected by macro-F1. Thresholds were refitted within each training fold, and the final thresholds were selected in the full cohort; agreement is therefore reported for the full cohort. As in MD-COPD, participants with airflow limitation were classified as COPD-major if they met at least one minor criterion and as AFL-only otherwise. In participants with coronary artery disease or congestive heart failure, the COPD-minor pathway required both CT criteria under MD-COPD, was unavailable under NoCT, and required the ESI criterion under the ESI classification.

## Clinical outcomes

Outcomes included all-cause and respiratory mortality, prospective respiratory exacerbations, and longitudinal FEV₁ decline. Mortality was ascertained through longitudinal follow-up and Social Security Death Index searches; respiratory mortality was adjudicated using modified TORCH criteria (20). Exacerbations were assessed through the COPDGene Longitudinal Follow-up program, and FEV₁ decline from spirometry at study visits 1–3. COPDGene data files are listed in the Supplement.

## Statistical analysis

The pre- to post-bronchodilator change in ESI was summarized by its mean and 95% CI (paired t-test). The ability of ESI to discriminate visual emphysema and definite airway wall thickening was assessed by receiver operating characteristic analysis and summarized by area under the curve (AUC), overall and separately in participants with airflow limitation and preserved spirometry.

Overall agreement with MD-COPD was compared between NoCT and ESI using McNemar's test. Agreement within each diagnostic category was summarized with MD-COPD as the reference by two quantities: sensitivity, the proportion of an MD-COPD category reproduced by the CT-free classification, and positive predictive value, the proportion of participants assigned to that category by the CT-free classification whom MD-COPD assigned to the same category. Positive predictive values were compared between the two CT-free classifications using 1,000 paired participant-level bootstrap resamples.

Associations with all-cause and respiratory mortality were assessed using Cox proportional hazards models and respiratory exacerbations using negative binomial regression with follow-up time as an offset. Models were adjusted for age, sex, race, current smoking, pack-years, and body mass index; exacerbation models were additionally adjusted for baseline exacerbation frequency.

For comparisons across classifications, AFL-only, COPD-minor, and COPD-major were compared with a common reference group classified as noCOPD by all three multidimensional classifications. Unadjusted rate ratios were calculated as the event rate per 100 person-years in each group divided by that in the reference. Adjusted hazard ratios (HRs) and incidence rate ratios (IRRs) were estimated from the models above. Each NoCT and ESI group was compared with the corresponding MD-COPD group as a rate ratio for unadjusted event rates and as a ratio of HRs or IRRs for adjusted estimates, with confidence intervals and P values from 1,000 paired participant-level bootstrap resamples.

Annualized FEV₁ change relative to the common reference group was estimated using linear mixed-effects models with participant-specific random intercepts, adjusted for height, sex, race, age, smoking status, pack-years, and baseline post-bronchodilator FEV₁. Differences between corresponding NoCT and ESI groups were assessed using 1,000 paired participant-level bootstrap resamples.

Discordance between ESI and MD-COPD was examined separately in participants with and without airflow limitation. Participants classified as noCOPD by both approaches served as the reference group with preserved spirometry, and those classified as AFL-only by both approaches with airflow limitation. ESI and %LAA-950HU were compared between discordant groups using the Wilcoxon rank-sum test and minor-criterion prevalence using Fisher's exact test.

Estimates are reported with 95% confidence intervals (CIs) in square brackets. Additional details on statistical procedures, including confidence-interval estimation for unadjusted outcome comparisons and handling of groups with fewer than 10 events, are provided in the Supplemental Methods. Analyses were performed in R version 4.5.2.
