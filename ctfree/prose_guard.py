"""Fail the build if a phrase Pete has deleted reappears in the sources.

He edits the rendered .docx; the builders regenerate it from the .md sources.
When he deletes a clause and I later rewrite that paragraph, the clause comes
back, and he has to delete it again. This makes the second reinstatement
impossible instead of relying on me to remember.

To add an entry: paste the phrase he removed, with a one-line note saying when
and where. Matching ignores line wrapping and is case-insensitive.
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SOURCES = ("ABSTRACT.md", "INTRODUCTION.md", "METHODS.md", "RESULTS.md",
           "DISCUSSION.md")

# Phrase -> why it is banned.
DELETED = {
    "adjusted IRR for the ESI classification of 1.25":
        "Results AFL-only paragraph; crude-only rewrite at Pete's request, 2026-09-13",
    "remained at low risk for all-cause and respiratory mortality":
        "Results AFL-only paragraph; crude all-cause is 1.29 (1.04-1.59), respiratory untestable; removed 2026-09-13",
    'in which the models for all three classifications were refitted':
        "Methods diagnostic-groups sentence; deleted in Pete's 2026-09-13 18:17 PJC",
    'without adjustment for multiple comparisons':
        'Methods cross-classification paragraph; deleted 2026-09-13 18:17',
    'in which both models were refitted':
        'Methods FEV1 paragraph; deleted 2026-09-13 18:17',
    '(entered as its interaction with follow-up time), as in the original MD-COPD report':
        'Methods FEV1 paragraph; deleted 2026-09-13 18:17',
    "Across the entire cohort, ESI showed significant associations with quantitative CT measures":
        "Results ESI-quantitative CT paragraph; Pete deleted it in the 2026-09-13 18:30 PJC",
    "It follows the exclusion chain of the source MD-COPD report":
        "Results study population commentary; Pete had it removed 2026-09-13",
    "so the cohort is entirely ever-smokers":
        "Results study population commentary; removed 2026-09-13",
    "the rate ratio was given alone and flagged":
        "Methods crude-ratio paragraph; Pete rewrote the sentence in the 2026-09-13 17:56 PJC",
    "The analytic cohort is therefore entirely ever-smokers":
        "Methods study population; Pete deleted it in the 2026-09-13 17:47 PJC",
    "the never-smoking controls COPDGene also enrolled were excluded":
        "Methods study population; rewritten by Pete 2026-09-13 17:47",
    "Since the two CT minor criteria are not available for this classification":
        "Methods classifications paragraph; deleted 2026-09-13 17:47",
    "uses traditional COPD spirometric definition":
        "Methods classifications paragraph; rewritten by Pete 2026-09-13 17:47",
    "consistent with the original MD-COPD report":
        "Methods models paragraph; Pete deleted it in the 2026-09-13 07:06 PJC",
    "; for the fixed ratio, post-bronchodilator FEV₁/FVC below 0.70)":
        "Methods COPD versus no COPD paragraph; deleted 2026-09-13 07:06",
    "conveys precision the data do not carry":
        "Methods commentary; removed at Pete's direction (menu, 2026-09-13)",
    "Exacerbation counts are overdispersed and clustered within participant":
        "Methods commentary; removed 2026-09-13",
    "since a main effect would have the visit 1 outcome predicting itself":
        "Methods commentary; removed 2026-09-13",
    "because the groups overlap":
        "Methods commentary; removed 2026-09-13",
    "since both classifications label the same participants":
        "Methods commentary; removed 2026-09-13",
    "divided by the observed rate in the common reference group":
        "Methods overclaim: S5 and the cross-classification use other references; fixed 2026-09-13",
    "identifies clinically important disease that the fixed FEV₁/FVC ratio misses":
        "Abstract Rationale clause; Pete deleted it in the 2026-09-13 06:51 PJC",
    "reclassifies a subset of subjects with COPD who do not carry increased risk for mortality":
        "Abstract Rationale clause; deleted 2026-09-13 06:51",
    "Analysis of membership in each of the four MD-COPD diagnostic pathways showed that":
        "Abstract Results clause; deleted 2026-09-13 06:51",
    "When compared against a common reference set of subjects without COPD":
        "Abstract Results clause; deleted 2026-09-13 06:51",
    "avoided significant underdiagnosis that was observed in the absence of CT without ESI substitution":
        "Introduction closing clause; deleted 2026-09-13 06:51",
    "which is the comparison this study requires":
        "Methods commentary; Pete had the reference paragraphs redrafted without it, 2026-09-13",
    "Two analyses use a different reference":
        "Methods commentary; redrafted 2026-09-13",
    "All comparisons between the multidimensional classifications are made against a single common reference":
        "Methods overclaim; redrafted 2026-09-13 as a scoped paragraph per analysis",
    "This demonstrates that removing the CT criteria results in an AFL-only group that is contaminated":
        "Results AFL-only paragraph; Pete deleted it in the 2026-09-11 13:01 PJC",
    "All-cause mortality rose monotonically across the four groups":
        "Results cross-tabulation outcomes paragraph; deleted 2026-09-11 13:01",
    "In this obstructed group, mortality and exacerbation risk was much higher":
        "Results obstructed outcomes paragraph; deleted 2026-09-11 13:01",
    "There were no significant differences between the three multidimensional classifications for this outcome":
        "Results FEV1 sentence; deleted 2026-09-11 13:01",
    "At the level of COPD versus no COPD, agreement was":
        "Results agreement sentence; deleted 2026-09-11 13:01",
    "groups did not have significant differences in CT quantitative emphysema":
        "Results non-obstructed paragraph; deleted 2026-09-11 13:01",
    "was tested with the corrected resampled t-test":
        "Methods sentence cut at Pete's direction (menu, 2026-09-10): no result reports it",
    "the two were compared by likelihood ratio test on 2 degrees of freedom":
        "Methods paragraph cut at Pete's direction (menu, 2026-09-10): no result reports it",
    "Discrimination was summarized with the C-index":
        "Methods paragraph cut at Pete's direction (menu, 2026-09-10): no result reports it",
    "which withholds a COPD diagnosis from participants who would otherwise "
    "receive one with the fixed ratio":
        "2026-09-08, AFL-only paragraph. Deleted repeatedly; the group is "
        "already defined in Methods and in Table 1.",
    "rather than as COPD versus no COPD":
        "2026-09-08, Methods, agreement sentence.",
    "ESI-MD-COPD":
        "2026-09-10, renamed throughout to 'the ESI classification'.",
    "NoCT-MD-COPD":
        "2026-09-10, renamed throughout to 'the NoCT classification'.",
    "NoCOPD-MD-COPD":
        "2026-09-10, a typo for NoCT-MD-COPD; now 'the NoCT classification'.",
    "This reference is smaller and at lower risk than any single "
    "classification's own noCOPD group":
        "2026-09-08, common-reference setup paragraph.",
}


def norm(t):
    return re.sub(r"\s+", " ", t).strip().lower()


def check(build_name="this build"):
    """Banned phrases, then his authored paragraphs."""
    bad = []
    for fn in SOURCES:
        path = os.path.join(HERE, fn)
        if not os.path.exists(path):
            continue
        body = norm(open(path).read())
        for phrase, why in DELETED.items():
            if norm(phrase) in body:
                bad.append((fn, phrase, why))
    if not bad:
        return
    sys.stderr.write(f"\nREFUSING TO BUILD. {build_name} contains text Pete "
                     f"deleted.\n\n")
    for fn, phrase, why in bad:
        sys.stderr.write(f"  {fn}: \"{phrase[:70]}...\"\n      {why}\n\n")
    sys.stderr.write("  Remove it from the source. If he has since asked for it "
                     "back, delete\n  the entry from prose_guard.DELETED in the "
                     "same commit.\n\n")
    raise SystemExit(2)

# Paragraphs Pete has authored or rewritten. A wholesale regeneration of one of
# these is the failure this catches: applying a formatting rule by rewriting the
# paragraph rather than by editing it in place undoes restructuring he did
# drafts ago. The build fails if a fingerprint no longer appears in the source.
# When he supplies a new version, replace the entry in the same commit.
OWNED = {
    "RESULTS.md": {
        'agreement section opening (2026-09-10 16:48)':
            'The cross-classification between MD-COPD and the two CT-free classifications is shown in Figure 1, and overall the ESI classification correctly classified 87.9%',
        'clinical outcomes opening (2026-09-13 18:30, slip fixed at his request)':
            'The benefit of the MD-COPD classification over the fixed ratio results from removing the COPD diagnosis from low-risk individuals with airflow obstruc',
        'AFL-only outcomes (crude only, rewritten at his request 2026-09-13)':
            'Crude risks for the AFL-only pathway are shown in Figure 2, with crude and adjusted risks in Supplemental Figure S1. While the ESI classification over',
        'FEV1 paragraph (2026-09-11 13:01)':
            'While all three groups had significant FEV₁ decline in COPD major pathway subjects, only MD-COPD also had significant decline in the COPD minor pathway',
        'COPD-minor comparison (2026-09-11, his wording)':
            'For the COPD minor pathway group, the three multidimensional classifications had similar risk profiles, with the NoCT and ESI estimates numerically lower than MD-COPD on all three outcomes.',
        'cross-tabulation opening (2026-09-10 16:48)':
            'Since the NoCT classification misdiagnosed high risk individuals as not having COPD, we discarded this classification and focused on the cross-tabulation of the',
        'non-obstructed paragraph (2026-09-11 13:01)':
            'In the non-obstructed subgroup (n = 5,156), COPD diagnoses occurred only via the COPD minor pathway.',
        'obstructed paragraph (2026-09-11 13:01)':
            'In the obstructed subgroup (n = 4,084), COPD diagnoses occurred only via the COPD major pathway in which only one minor criterion was necessary for diagnosis.',
        'cross-tabulation outcomes (2026-09-11 13:01)':
            'We also evaluated outcome risks for all-cause mortality and exacerbations by cross-tabulated diagnostic category within obstructed and non-obstructed subjects',
    },
}


def check_owned(build_name="this build"):
    """His paragraphs must still be present, in his words."""
    missing = []
    for fn, entries in OWNED.items():
        path = os.path.join(HERE, fn)
        if not os.path.exists(path):
            continue
        body = norm(open(path).read())
        for label, text in entries.items():
            if norm(text) not in body:
                missing.append((fn, label, text))
    if not missing:
        return
    sys.stderr.write(f"\nREFUSING TO BUILD. {build_name} has lost text Pete "
                     f"wrote.\n\n")
    for fn, label, text in missing:
        sys.stderr.write(f"  {fn}: {label}\n      expected: \"{text[:70]}...\"\n\n")
    sys.stderr.write("  Restore his wording. If he asked for the change, update "
                     "the entry in\n  prose_guard.OWNED in the same commit.\n\n")
    raise SystemExit(2)
