# Results — CT-free MD-COPD paper

*(Pete's draft of 2026-09-10 16:48, adopted verbatim. Do not rewrite a
paragraph here; edit it in place or replace it with a version he supplies.)*

## Study population

The analytic cohort comprised 9,240 COPDGene participants (Supplemental Table S1). It follows the exclusion chain of the source MD-COPD report, which removes never-smokers, so the cohort is entirely ever-smokers. It comprised 4,037 smokers without airflow obstruction (GOLD 0), 1,119 participants with PRISm, and 4,084 participants with GOLD 1 to 4 airflow obstruction. Mean baseline ESI increased monotonically with severity, from 0.90 in GOLD 0 to 8.30 in GOLD 4 participants.

Across the entire cohort, ESI showed significant associations with quantitative CT measures of emphysema, including the percentage of low attenuation area below −950 Hounsfield units (%LAA−950HU; r = 0.78) and PRM-defined emphysema (r = 0.81). The strength of these relationships varied according to disease severity, with weak correlations observed in groups with minimal structural abnormalities (GOLD 0, r = 0.08) and stronger relationships among participants with established airflow obstruction (GOLD 3, r = 0.58) (Supplemental Table S2).


## Selection of diagnostic thresholds for the CT-free classifications

Both CT-free classifications required a threshold for the number of minor criteria sufficient for the COPD-minor pathway, and the ESI classification additionally required an ESI threshold. We explored multiple measures for identifying optimal threshold values, evaluating their performance using five-fold cross validation. Our final thresholds were based on the macro-F1 measure, which had the desirable effect of giving equal importance to correct assignment for each of the four groups despite the large difference in sample size between groups (Supplemental Table S3). The selected rules assigned COPD-minor at ≥ 2 minor criteria for both the ESI and NoCT classifications, and the optimal ESI threshold for recovery of MD-COPD subgroups was ≥ 1.50.


## Agreement between MD-COPD and CT-free classifications

The cross-classification between MD-COPD and the two CT-free classifications is shown in Figure 1, and overall the ESI classification correctly classified 87.9% of subjects compared to 83.9% for the NoCT classification (p<0.005). At the level of COPD versus no COPD, agreement was 87.9% and 83.9% (p<0.005) for the ESI and NoCT classifications, respectively. At the level of the four diagnostic pathways, both classifications had excellent agreement with MD-COPD for the no COPD and COPD major pathway groups (>98% accuracy for both), but agreement was weaker for the COPD minor and airflow limitation only (AFL-only) pathways (Supplemental Table S4). For COPD minor, the ESI-based and NoCT classifications had 54% and 56% accuracy, respectively (p<0.005). For AFL-only, the ESI classification outperformed the NoCT classification (36% versus 25% accuracy, p<0.005), but both groups assigned substantially more subjects to AFL-only than the MD-COPD classification. For the NoCT classification, no threshold could recover the participants with airflow limitation whose only minor criterion was a CT finding.


## Clinical outcomes by diagnostic group

The benefits of the MD-COPD classification over fixed ratio result from the creation of the AFL-only pathway, where the COPD diagnosis is removed from low-risk individuals, and the COPD-minor pathway that moves a high-risk subset of non-obstructed smokers into the COPD category. To determine whether the ESI and NoCT classifications retained this property, we compared the risk of mortality and exacerbations for the AFL-only and COPD-minor groups across the three multidimensional classifications. To ensure comparable assessment, we defined a noCOPD group that consisted of subjects assigned as noCOPD by all three methods (Figure 2 and Supplemental Table S5).

For the AFL-only pathway, while the ESI classification “over-diagnosed” this pathway relative to MD-COPD, the individuals classified through this pathway remained at low risk for all-cause and respiratory mortality (p>0.05 for both crude and adjusted hazard ratios), and there was a modest increase in risk for respiratory exacerbations (adjusted IRR for the ESI classification of 1.25 [1.05 - 1.50] versus 1.36 [1.08 - 1.73] for MD-COPD). Under the NoCT classification, this group carried substantially elevated risk on every outcome (p<0.005 for all-cause mortality, respiratory mortality, and respiratory exacerbations). This demonstrates that removing the CT criteria results in an AFL-only group that is contaminated by individuals at elevated risk of COPD-related outcomes.

For the COPD minor pathway group, the three multidimensional classifications had similar risk profiles with no significant differences in crude or adjusted risk of all three outcomes (Figure 3, Supplemental Table S5).

For the COPD major pathway group, risk was the highest under every classification, and the estimates were largest for the NoCT classification on all three outcomes (Figure 4, Supplemental Table S5). This is a consequence of the previously described AFL-only misclassification, because the 833 misclassified AFL-only participants for the NoCT classification carry an elevated risk for mortality and exacerbations that is higher than NoCOPD subjects but lower than COPD major pathway subjects, simultaneously contaminating the AFL-only group and resulting in a smaller but higher risk COPD major pathway subset.

Finally, we estimated annualized change in FEV₁ for every group against the same common reference, adjusting for multiple covariates including baseline post-bronchodilator FEV₁. There were no significant differences between the three multidimensional classifications for this outcome, and COPD-major declined faster than the reference group under all three (Supplemental Table S6).


## Emphysema and Airway Wall Thickness by MD-COPD and ESI classifications

Since the NoCT classification misdiagnosed high risk individuals as not having COPD, we discarded this classification and focused on the cross-tabulation of the ESI classification compared to MD-COPD. To better understand the clinical characteristics and risk profile of these classifications, we examined the levels of CT emphysema and airway wall thickening in both classifications stratified by the presence of airflow obstruction (Figure 5).

In the non-obstructed subgroup (n = 5,156), 72.6% of participants were classified as noCOPD by both classifications, 14.1% as COPD by both, 11.9% by ESI alone and 1.4% by CT alone. CT-only-COPD participants showed a higher prevalence of visually assessed emphysema, although groups did not have significant differences in CT quantitative emphysema. In contrast, ESI-only-COPD participants showed higher ESI values, while having no visual emphysema. Interestingly, this group did have nominally higher levels of quantitative emphysema than the CT-only group (Figure 5).

All-cause mortality rose monotonically across the four groups, from 1.5 deaths per 100 person years in the Both-noCOPD group to 2.1, 2.3, and 2.8 in the CT-only, ESI-only, and Both COPD minor pathway groups, respectively. Exacerbation risk increased from 11.2 per 100 person-years in the Both-noCOPD group to 21.7 in the CT-only-COPD group, 31.0 in the ESI-only-COPD group and 42.9 in the Both-COPD group. Respiratory deaths were too few for estimation. After adjustment, using the Both-noCOPD group as the reference, all three COPD minor groups had significantly higher risk for all-cause mortality and respiratory exacerbations, but the difference between COPD-minor groups was not significant (Figure 6, Supplemental Table S7).

In the obstructed subgroup (n = 4,084), 4.7% of participants were classified as AFL-only by both classifications, 84.7% as COPD-major by both, 2.0% by ESI alone and 8.6% by CT alone. CT-only-COPD participants showed a high prevalence of visually assessed emphysema (77.7%) and airway wall thickening (47.4%), against none in either of the other two non-COPD-major groups. In contrast, ESI-only-COPD participants showed higher ESI values, while having no visual emphysema. Interestingly, this group did have nominally higher levels of quantitative emphysema than the CT-only group (Figure 5).

In this obstructed group, mortality and exacerbation risk was much higher in the Both COPD group relative to both the CT-only and ESI-only COPD subjects. Crude all-cause mortality rates were 1.8 in the ESI-only-COPD group and 2.1 in the CT-only-COPD group, against 5.6 in the Both-COPD group. The rate of exacerbations was 14.6 and 13.1 against 62.2; and respiratory deaths were 2, 0 and 2 in the Both-AFL-only, ESI-only-COPD and CT-only-COPD groups against 592 in the Both-COPD group (Figure 6).


## Relationship of ESI to the visual CT criteria

We examined how closely ESI tracks the visual CT emphysema and airway wall thickness criteria for which it is a surrogate. Mean ESI increased monotonically across both scales, from 1.04 to 6.62 across the six levels of visual emphysema and from 0.96 to 3.32 across the three levels of airway wall thickening (Supplemental Table S8). Among participants with airflow limitation, ESI discriminated both visual emphysema and definite wall thickening with an area under the curve of 0.75, whereas among those with preserved spirometry the values fell to 0.56 and 0.61 (Table 2). This also corresponds to the impact of the ESI criterion on the multidimensional classification where it’s benefit was primarily concentrated in improving the classification of subjects with airflow limitation, whereas it was less impactful in the subset with preserved spirometry.
