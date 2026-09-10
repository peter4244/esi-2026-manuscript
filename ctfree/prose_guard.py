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
        'clinical outcomes opening (2026-09-10 16:48)':
            'The benefits of the MD-COPD classification over fixed ratio result from the creation of the AFL-only pathway, where the COPD diagnosis is removed from low-risk ',
        'AFL-only outcomes (2026-09-10 16:48)':
            'For the AFL-only pathway, while the ESI classification “over-diagnosed” this pathway relative to MD-COPD, the individuals classified through this pathway remain',
        'cross-tabulation opening (2026-09-10 16:48)':
            'Since the NoCT classification misdiagnosed high risk individuals as not having COPD, we discarded this classification and focused on the cross-tabulation of the',
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
