# Proposed text: Methods vs code (O-m-1 to O-m-6) and deposit statements (O-r-1)

Not applied. Each item: where, current text, proposed text, and the code it was checked against. Numbers in the
proposals come from the code or `ctfree/assets/` (checked 2026-10-08).

## O-m-1 + O-m-2. Threshold selection (main Methods, "ESI and modified classifications", 3rd paragraph)

Checked: `ESI_ctfree_analysis_2026.9.3.Rmd` search grids (`KS <- 1:3`; `G4` = k 2–4 × ESI 0.50–4.00 by 0.25, 45
rules); `cv-fit` refits by macro-F1 only, folds stratified on MD-COPD-CT category, seed 20260901, 5 × 5; κ and
balanced accuracy are computed on the full cohort only.

**Current:** "For both modified classifications, the number of minor criteria required for COPD diagnosis was derived
from concordance with MD-COPD-CT categories without using outcome data. Candidate thresholds were evaluated by
five-fold cross-validation repeated five times using Cohen's κ, mean per-category sensitivity, and macro-F1. Final
thresholds were selected by macro-F1. Thresholds were refitted within each training fold, and final thresholds were
selected in the full cohort; agreement is therefore reported for the full cohort."

**Proposed:** "For both modified classifications, the number of minor criteria required for COPD diagnosis and, for
MD-COPD-ESI, the ESI value defining the ESI criterion were derived from concordance with MD-COPD-CT categories
without using outcome data. Candidates were 1 to 3 of 3 criteria for MD-NoCT and 2 to 4 of 4 criteria with ESI
thresholds from 0.50 to 4.00 in steps of 0.25 for MD-COPD-ESI. Candidates were compared on Cohen's κ, mean
per-category sensitivity, and macro-F1 in the full cohort, and final thresholds were selected by macro-F1. To assess
overfitting, the selection was repeated within each training fold of five-fold cross-validation, stratified on
MD-COPD-CT category and repeated five times, and agreement was evaluated in the held-out folds; agreement is
reported for the full cohort."

**Table S2 legend, first sentence. Current:** "Category sizes and performance metrics are shown for each candidate rule
against MD-COPD-CT as the reference classification." **Proposed:** "Category sizes and performance metrics against
MD-COPD-CT as the reference classification are shown for each MD-NoCT rule and for MD-COPD-ESI rules requiring ≥2 of
4 criteria at selected ESI thresholds; the full search is described in the Methods."

## O-m-3. FEV₁ model (main Methods, "Statistical analysis"; and Table S6 legend)

Checked: `fev1-decline` chunk: age, current smoking and pack-years come from each visit's row; height, sex, race
from baseline; baseline FEV₁ enters only as an interaction with time; all participants with baseline spirometry are
in the model (9,240; 5,414 with a follow-up visit); P values from lmerTest (Satterthwaite).

**Main Methods. Current:** "…adjusted for height, sex, race, age, smoking status, pack-years, and baseline
post-bronchodilator FEV₁." **Proposed:** "…adjusted for baseline height, sex, and race; age, current smoking status,
and pack-years at each visit; and baseline post-bronchodilator FEV₁ entered as an interaction with follow-up time.
All participants with baseline spirometry were included, including those without a follow-up visit, and P values
used Satterthwaite degrees of freedom."

**Table S6 legend. Current:** "…adjusted for height, sex, race, age, smoking status, pack-years, and baseline
post-bronchodilator FEV₁ entered as an interaction with follow-up time." **Proposed:** "…adjusted for baseline height,
sex, and race, for age, current smoking status, and pack-years at each visit, and for baseline post-bronchodilator
FEV₁ entered as an interaction with follow-up time."

## O-m-4. Who is in the common-reference models (main Methods, "Statistical analysis", common-reference paragraph)

Checked: each classification's models use the common reference plus that classification's AFL-only, COPD-minor and
COPD-major (`consensus-reference`, `fev1-decline` chunks).

**Proposed addition** after "…compared with a common reference group classified as noCOPD by all three
multidimensional classifications.": "Participants classified as noCOPD by a given classification but not by all
three were excluded from that classification's models."

## O-m-5. Visual CT rules (Supplemental Methods, "Visual CT assessment"; Figure 1 legend)

Checked: MD-COPD-CT categories come from the source report's per-participant file; the ≥2 / =2 / missing-as-not-met
rules in the code feed only the AUCs (Figure 1), the discordance profiles (Figure S2) and an internal check.

**Supplement. Current:** "…For MD-COPD-CT classification, visual emphysema was considered present at mild severity
or greater (score ≥2); thus, trace emphysema did not satisfy the imaging criterion. Airway wall thickening was
visually categorized as absent, borderline, or definite and was considered present for MD-COPD-CT only when definite
(score 2). Participants with missing visual CT scores (n = 4) were considered not to meet the corresponding imaging
criterion."

**Proposed:** "…MD-COPD-CT categories were taken from the per-participant classification of the source report (S3),
in which visual emphysema was considered present at mild severity or greater (score ≥2), so that trace emphysema did
not satisfy the imaging criterion, and airway wall thickening, categorized as absent, borderline, or definite, was
considered present only when definite (score 2). The same definitions were used for the analyses of the individual
imaging criteria (Figure 1 and Supplemental Figure S2), in which the 4 participants without visual scores were
counted as not meeting either criterion."

**Figure 1 legend, addition** (in `figure1_esi_ct.R`, which writes the legend): after "…participants had a visual
score for each criterion." add: "AUCs include the 4 participants without visual scores as criterion-negative."

## O-m-6. Omissions

Checked: bootstrap P = min(1, 2 × min(share ≤ 0, share ≥ 0)); every reported comparison used 1,000 resamples
(B_eff = 1,000 in `group_vs_mdcopd.csv`, `fev1_noct_vs_esi.csv`, `agreement_by_group.csv`); McNemar
`correct = FALSE`; visit-1 post-bronchodilator ESI replicates averaged; missing minor criteria coded as not met.

1. **Supplemental Methods, end of the bootstrap paragraph ("…obtained from 1,000 paired participant-level bootstrap
   resamples."), add:** "Two-sided bootstrap P values were twice the smaller of the proportions of resampled
   differences at or below and at or above zero, capped at 1; with 1,000 resamples, values below 0.005 are reported
   as P < 0.005. Resamples in which a model failed to fit were excluded; every reported comparison retained all
   1,000 resamples."
2. **Main Methods, "…compared between MD-NoCT and MD-COPD-ESI using McNemar's test."** → "…using McNemar's test
   without continuity correction."
3. **Main Methods, "Baseline post-bronchodilator ESI was used for classification."** → "Baseline post-bronchodilator
   ESI was used for classification, averaging replicate measurements at the baseline visit."
4. **Main Methods, MD-COPD-CT classification paragraph, add at the end:** "Missing minor criteria were counted as not
   met."
5. **Bronchodilator change.** Methods say "mean and 95% CI (paired t-test)" and Results say the change was
   statistically significant, but the analysis code stores only n, mean and SD; the CI is computed in `verify.R`.
   The paired-t CI and P are exact functions of n, mean and SD, so nothing changes numerically. Options: (a) add the
   CI and P to the analysis code (shows up after the next cluster run; no text change), or (b) leave the code and
   keep the text. Recommend (a), bundled with the next cluster run.

## R version (main Methods, last sentence)

**Current:** "Analyses were performed in R version 4.5.2." **Proposed:** "Analyses were performed in R version 4.5.1."
The paper's numbers come from the Channing runs, which used R 4.5.1 (`ctfree/SOFTWARE_VERSIONS.md`); the laptop
(R 4.5.2) only drew figures and built the documents from the aggregate tables.

## O-r-1. Statements and the data-file list (need facts from Pete; bracketed items unconfirmed)

1. **Data availability.** "COPDGene data are available to qualified investigators through the COPDGene Study
   (www.copdgene.org) [and dbGaP, accession phs000179]."
2. **Code availability.** "The analysis code is available at [repository / archive URL and DOI]." (changit is
   internal and the GitHub repository is private; a citable archive would need to be chosen.)
3. **Funding / acknowledgment.** "[COPDGene's standard funding statement (NHLBI U01 HL089897 and U01 HL089856; COPD
   Foundation Industry Advisory Board) — current wording from the COPDGene publications committee]; [authors' grants]."
4. **Ethics.** "COPDGene was approved by the institutional review boards of all participating centers, and all
   participants provided written informed consent."
5. **Supplement, "COPDGene files used": add the ESI values file.** "**copdgene_pft_esi**: Emphysema Severity Index
   values computed from the spirometric flow-volume curves at each visit, before and after bronchodilator; used for
   baseline post-bronchodilator ESI and the bronchodilator change." The last line of that list ("Emphysema Severity
   Index values were computed from the COPDGene spirometric flow-volume curves as described in the main text.")
   would then be redundant and could go.
