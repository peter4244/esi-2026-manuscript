# METHODS



## Study design


The study was designed to determine whether the CT-derived structural component of the multidimensional diagnostic framework proposed by Bhatt and colleagues (11) could be represented by a measure obtained from standard spirometry. To isolate this contribution, only the structural component of the original framework was reformulated using the Emphysema Severity Index (ESI), whereas spirometric airflow obstruction and symptom criteria were unchanged. The resulting ESI-based classification was compared with the original CT-based framework for diagnostic agreement and prognostic performance.


## Study population


The analysis was performed using data from the COPDGene study (NCT00608764), a multicenter observational cohort of current and former smokers aged 45–80 years with a smoking history of at least 10 pack-years. Baseline evaluation included standardized pre- and post-bronchodilator spirometry, chest CT imaging, symptom assessment, and longitudinal clinical follow-up. Participants with complete data required to construct both CT-based and ESI-based classifications were included. Details of COPDGene design, imaging protocols, and follow-up have been previously reported (17).


## Original multidimensional diagnostic framework


The framework proposed by Bhatt and colleagues (11) integrates three domains: spirometric airflow obstruction, respiratory symptoms, and CT-defined structural abnormalities. The major diagnostic criterion is post-bronchodilator FEV₁/FVC below 0.70. Five minor criteria comprise two structural criteria—visual emphysema (Fleischner assessment at least mild) and airway wall thickening (Fleischner assessment definite) (18)—together with three symptom criteria: modified Medical Research Council dyspnea score of 2 or greater, St. George’s Respiratory Questionnaire total score of 25 or greater, and chronic bronchitis. Participants meeting the major criterion together with at least one minor criterion are classified as COPD-major; participants meeting at least three of five minor criteria without the major criterion are classified as COPD-minor; participants meeting the major criterion alone are classified as Airflow Limitation (AFL)-only-noCOPD; and the remaining participants are classified as noCOPD.


## ESI-based spirometric representation of the structural component


The CT-defined structural component was represented using ESI while preserving all other components of the original multidimensional framework. ESI was calculated from absolute values of standard spirometric measurements, including PEF, FVC, and expiratory flows measured after expiration of 25%, 50%, and 75% of FVC (FEF25%, FEF50%, and FEF75%), using a previously validated algorithm (13, 14). ESI ranges from 0 to 10 and reflects expiratory flow-volume curve morphology independently of ethnic and anthropometric reference equations.

Optimal ESI thresholds reproducing the CT-derived structural classification were identified using a single-variable classification tree (rpart) in a randomly selected training cohort (80% of participants) and evaluated in the remaining testing cohort (20%). The final thresholds were subsequently applied to the entire study population. To preserve the original diagnostic architecture, in which the structural domain contributes up to two of five minor criteria, the ESI-based representation was implemented as a two-threshold scoring rule: ESI values below the lower threshold (ESI < 1) contribute zero minor criteria; values from the lower threshold up to but not including the upper threshold (1 ≤ ESI < 2.5) contribute one; values at or above the upper threshold (ESI ≥ 2.5) contribute two. Complete threshold-selection results are reported in {{REF:S1}}.


## Diagnostic subgroup definitions


Participants were classified according to both the original CT-based framework and the ESI-based framework. Agreement and discordance between classifications were evaluated by defining four groups: Both-COPD, Bhatt-only-COPD, ESI-only-COPD, and Both-noCOPD. For analyses examining the relationship between spirometric measures and structural lung abnormalities, participants were also stratified by smoking and spirometric status (never smokers, Global Initiative for Chronic Obstructive Lung Disease [GOLD] 0, preserved-ratio impaired spirometry [PRISm], and GOLD stages 1–4).


## Clinical outcomes


Clinical outcomes included all-cause mortality, respiratory mortality, prospective exacerbation rate, and longitudinal decline in FEV₁. Mortality, exacerbations, and repeated spirometric measurements were analyzed using available COPDGene follow-up data.


## Statistical analysis


Classification agreement between CT-based and ESI-based frameworks was assessed using sensitivity, specificity, overall agreement, and Cohen’s κ coefficient. Associations between ESI and quantitative CT measures of emphysema (%LAA−950HU [19] and parametric response mapping (PRM) emphysema [20]) were evaluated using Pearson correlation coefficients.

Associations with clinical outcomes were assessed using Cox proportional-hazards models for mortality, negative-binomial regression models for exacerbations, and linear mixed-effects models for longitudinal FEV₁ decline. Two primary adjustment sets were used. For mortality and exacerbation outcomes, models were adjusted for age, sex, race, current smoking status, pack-years, and body mass index. For FEV₁ decline, where FEV₁ in milliliters was the outcome, baseline height replaced body mass index as the anthropometric adjustment (retaining age, sex, race, current smoking status, and pack-years). Sensitivity analyses stratified by GOLD stage — including the continuous-ESI models — omitted body mass index because GOLD-stratum indicators absorb the between-stratum variation. To confirm that the primary conclusions were robust to covariate choice, every reported association was additionally refit adjusting only for age, sex, and race. No estimate changed direction, and no significance status changed at the p = 0.05 threshold under this minimal adjustment (analysis reproducible from the HTML report generated by the analysis Rmd). Pairwise Wald contrasts among the three COPD-positive cross-classification groups were single-step-adjusted using the multcomp package. Pre-specified sensitivity analyses included exclusion of participants with ESI=10, use of an alternative four-criterion framework replacing only the emphysema criterion, and analyses restricted to severe exacerbations. Statistical analyses were performed using R (version 4.5.2), with two-sided P<0.05 considered significant.
