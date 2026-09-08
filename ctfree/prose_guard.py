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
    "This reference is smaller and at lower risk than any single "
    "classification's own noCOPD group":
        "2026-09-08, common-reference setup paragraph.",
}


def norm(t):
    return re.sub(r"\s+", " ", t).strip().lower()


def check(build_name="this build"):
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
