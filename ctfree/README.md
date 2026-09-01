# CT-free MD-COPD

A separate paper from the v15 manuscript in the parent directory, sharing its
code and methodology but not its claims. Start with [CLAIMS.md](CLAIMS.md).

## The question

MD-COPD is defined partly by CT findings. CT is often unavailable. Can the
classification, and the benefit it carries over the fixed ratio, be preserved
using spirometry and symptoms alone?

## Why this is not the v15 paper

v15 asks whether an ESI-based framework reproduces the CT-based one, and
answers with 91% agreement and kappa 0.82 at the binary COPD-versus-noCOPD
level. Per category that agreement is much weaker: 50.5% for COPD-minor and
12.4% for AFL-only-noCOPD, because the binary figure is carried by noCOPD and
COPD-major, which are 86.6% of the cohort and already agree at 97.8% and 98.4%.

Reproducing the CT classification is also the wrong target. What matters is
whether a CT-free classification keeps MD-COPD's advantage over the fixed
ratio, and whether its category labels still mean what they say. Those are the
questions here.

## What the analysis does

Four schemas on the same 9,402 participants, defined in CLAIMS.md. The two
CT-free schemas are fitted to approximate the CT-based one, by the same
objective, over their full parameter spaces, outcome-blind, and cross-validated
5 by 5 stratified on the reference categories.

## Running it

All three resolve their own location, so they run from any working directory
and the paths below can be pasted anywhere. In order:

```
Rscript /Users/petecastaldi/claude_projects/projects/ESI_2024/ctfree/gate_fixedratio.R
Rscript /Users/petecastaldi/claude_projects/projects/ESI_2024/ctfree/analysis.R
Rscript /Users/petecastaldi/claude_projects/projects/ESI_2024/ctfree/verify.R
```

The first asks whether MD-COPD beats the fixed ratio at all, the second fits
and scores the four schemas, the third checks every claim against the
artifacts. `config_paths.R` supplies the five COPDGene inputs and is
git-ignored; the classification analysis needs only two of them.

## Files

| | |
|---|---|
| `CLAIMS.md` | every claim, with the artifact and field that produces it |
| `gate_fixedratio.R` | the nested likelihood ratio test the reframe presupposes |
| `analysis.R` | schema fitting, cross-validation, labels and risk |
| `verify.R` | the registry; fails loudly on drift |
| `_locate.R` | resolves the paper's own directory so nothing depends on the caller's cwd |
| `assets/` | artifacts, and `VERIFICATION.csv` |

## Three traps, recorded so they are not walked into again

**Metrics that ignore over-calling pick a schema that mislabels people.**
Cohen's kappa, mean recall and the C-index each select the CT-free schema that
puts 1,119 participants in AFL-only-noCOPD to capture the 170 real ones. That
group carries 6.6x respiratory mortality, so the label is false. Macro-averaged
F1 is used instead: symmetric across categories, but balancing precision
against recall within each.

**The schema with the best discrimination is the one that must be rejected.**
Dropping the structural criterion entirely beats every other schema on
C-index and AIC, by concentrating risk into a smaller COPD-major group and
calling the remainder healthy. Discrimination is indifferent to whether labels
are true. The paper has to state this and answer it, not omit it.

**Both CT-free schemas must be fitted over their full parameter space.** The
symptoms-only schema needs its count threshold refitted because dropping two
criteria changes the scale. Allowing that for one schema and not the other
rigs the comparison.
