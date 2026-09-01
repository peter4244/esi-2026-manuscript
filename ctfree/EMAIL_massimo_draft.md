# Draft email to Massimo

Subject: **ESI manuscript: why we have reworked it, with the numbers**

---

Dear Massimo,

I want to explain a change of direction on the ESI manuscript before you see
the new draft, because it started from something we had not looked at closely
enough.

**The headline agreement was correct but it was measuring the easy part.**

We reported 91% agreement and kappa 0.82 between the CT-based MD-COPD
classification and our ESI-based version. Those numbers are right, and the
Methods said plainly that they were computed at the binary level, COPD versus
no COPD. What we never reported was agreement in each of the four diagnostic
categories. Here is the full cross-classification, with the CT-based
classification in the rows:

| CT-based ↓ / ESI-based → | noCOPD | AFL-only | COPD-minor | COPD-major | total |
|---|---|---|---|---|---|
| **noCOPD** | **4,109** | 0 | 94 | 0 | 4,203 |
| **AFL-only-noCOPD** | 0 | **21** | 0 | 149 | 170 |
| **COPD-minor** | 538 | 0 | **548** | 0 | 1,086 |
| **COPD-major** | 0 | 63 | 0 | **3,880** | 3,943 |
| **total** | 4,647 | 84 | 642 | 4,029 | 9,402 |

Reading down the diagonal:

| category | concordant | of | |
|---|---|---|---|
| noCOPD | 4,109 | 4,203 | 97.8% |
| COPD-major | 3,880 | 3,943 | 98.4% |
| **COPD-minor** | **548** | **1,086** | **50.5%** |
| **AFL-only-noCOPD** | **21** | **170** | **12.4%** |

The two large categories agree almost perfectly. The two categories that
MD-COPD actually adds to conventional spirometry do not. Our rule reproduced
half of COPD-minor and one in eight of AFL-only-noCOPD.

The reason the overall figure looks so good is arithmetic. noCOPD and
COPD-major are 86.6% of the cohort and supply 93.4% of all the concordance.
Collapsing to a binary also merges COPD-minor with COPD-major and
AFL-only-noCOPD with noCOPD, which hides both of the disagreements above,
because both are movements across that binary boundary.

I do not think this was concealed; it simply was not computed. But it is
easily computed by a reviewer, and the word "reproduced" in our abstract
invites exactly that check.

**Why the thresholds needed to change.**

Looking into it, the thresholds were never fitted for this purpose. The
classification tree was fitted to predict the visual CT structural score, and
the ten-candidate grid that followed was scored on binary COPD agreement. So
the two categories where we perform worst were not part of what we optimized.

We refitted, over the full parameter space, with two changes to the rule. The
ESI threshold moves from 1.00 to 1.25, and the minor-criterion count moves from
three of five to two of four. The count change matters because dropping the two
CT criteria and adding one ESI criterion changes the scale of the count; three
was calibrated for five criteria, not four. Fitting used only the CT-based
labels, with no mortality or exacerbation data, and was cross-validated.

| rule | held-out macro-F1 |
|---|---|
| original (ESI ≥ 1.00, ≥ 3 of 4, two-threshold scoring) | 0.675 |
| **revised (ESI ≥ 1.25, ≥ 2 of 4)** | **0.753** |

What that buys, per category:

| category | original | revised |
|---|---|---|
| COPD-minor | 548 of 1,086 (50.5%) | **988 of 1,086 (91.0%)** |
| AFL-only-noCOPD | 21 of 170 (12.4%) | **77 of 170 (45.3%)** |

AFL-only-noCOPD remains the weakest category, and the revised paper says so.
The revised rule is also simpler than the one it replaces: a single ESI
threshold instead of the two-threshold 0/1/2 scoring, which we found was doing
almost no work.

**What the paper now argues.**

Reproducing the CT-based categories turned out to be the wrong target. The
question that matters is whether a CT-free classification keeps what MD-COPD
adds over the fixed ratio. So the paper now compares four classifications on
the same participants: the fixed ratio alone, MD-COPD with CT, MD-COPD with the
CT criteria simply removed, and MD-COPD with ESI in their place.

The result is a stronger case for ESI than the old framing gave us. Removing
the CT criteria without replacing them moves 949 participants out of
COPD-major, because for 24% of that category a CT finding is the only minor
criterion they meet. With ESI that loss falls to 233. And the category those
participants land in, AFL-only-noCOPD, carries 6.6 times the respiratory
mortality of its reference when CT is simply dropped, but no significant excess
when ESI replaces it. In other words, symptom criteria alone will tell 949
people they do not have COPD when they do, and ESI is what prevents that.

One finding we report against ourselves: the symptoms-only version has the best
discrimination of the four schemas on every outcome. It achieves that by making
COPD-major smaller and more severe while mislabeling the people it removes. We
state this in the Results rather than the supplement, because a reviewer will
find it and the answer is better made by us.

I will send the draft separately. Happy to go through any of this on a call.

Best,
Pete

---

## Numbers used, with their sources

| | value | artifact |
|---|---|---|
| cross-classification, original rule | table above | `manuscript_assets/Table_6.csv` |
| overall agreement, kappa | 91.0%, 0.82 | `manuscript_assets/Table_Agreement_stats.txt` |
| cross-classification, revised rule | table above | `ctfree/assets/crossclass.csv` |
| held-out macro-F1 | 0.675, 0.753 | `ctfree/assets/schema_fit.csv` |
| 949 / 233 / 24.1% | | `ctfree/assets/reclassification.csv` |
| 6.6x respiratory mortality | | `ctfree/assets/schema_risk.csv` |
