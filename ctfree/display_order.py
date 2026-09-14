"""Tables and figures are numbered in the order the text first cites them, and
every one is cited. Pete's rule, 2026-09-10; checked at every build, which
stops on a violation rather than relying on anyone to remember.

Scans Introduction, Methods, Results and Discussion in that order. The Abstract
is excluded, since abstracts do not cite display items. Ranges such as
"Figures 2 to 4" and "Supplemental Tables S3a to S3c" count as citing every item
in the range.
"""
import os
import re

PROSE = ("INTRODUCTION.md", "METHODS.md", "RESULTS.md", "DISCUSSION.md")
CITE = re.compile(
    r"(Supplemental\s+Tables?|Supplemental\s+Figures?|Tables?|Figures?)\s+(S?\d+[a-c]?)"
    r"(?:\s*(?:to|-|–)\s*(S?\d+[a-c]?))?"
    r"((?:\s*(?:,|and)\s*(?:S?\d+[a-c]?))*)")


def _split(tok):
    m = re.fullmatch(r"(S?)(\d+)([a-c]?)", tok)
    return m.group(1), int(m.group(2)), m.group(3)


def _range(a, b):
    pa, na, la = _split(a)
    pb, nb, lb = _split(b)
    if na == nb and la and lb:
        return [f"{pa}{na}{chr(c)}" for c in range(ord(la), ord(lb) + 1)]
    return [f"{pa}{n}" for n in range(na, nb + 1)]


def cited_in_order(here):
    text = " ".join(open(os.path.join(here, f)).read()
                    for f in PROSE if os.path.exists(os.path.join(here, f)))
    text = re.sub(r"\{[^}]*\}", "", text)
    seq = {"Table": [], "Figure": [], "Supplemental Table": [], "Supplemental Figure": []}
    for m in CITE.finditer(text):
        head = m.group(1)
        kind = (("Supplemental Figure" if "Figure" in head else "Supplemental Table")
                if head.startswith("Supplemental")
                else "Table" if head.startswith("Table") else "Figure")
        items = _range(m.group(2), m.group(3)) if m.group(3) else [m.group(2)]
        items += re.findall(r"S?\d+[a-c]?", m.group(4) or "")
        for it in items:
            if it not in seq[kind]:
                seq[kind].append(it)
    return seq


def check(here, produced, build_name="this build"):
    """produced: {"Table": ["1", "2"], "Figure": [...], "Supplemental Table": [...]}
    in numbering order. Stops the build if citation order and numbering order
    disagree, or if anything is produced but never cited, or cited but absent."""
    seq = cited_in_order(here)
    problems = []
    for kind, ids in produced.items():
        first = [i for i in seq.get(kind, []) if i in ids]
        if first != [i for i in ids if i in first]:
            problems.append(f"{kind}s are first cited in the order {first}, "
                            f"but numbered {ids}")
        never = [i for i in ids if i not in seq.get(kind, [])]
        if never:
            problems.append(f"{kind} never cited in the text: {never}")
        absent = [i for i in seq.get(kind, []) if i not in ids]
        if absent:
            problems.append(f"{kind} cited but not produced: {absent}")
    if problems:
        raise SystemExit(f"\nREFUSING TO BUILD. {build_name}: display items out of "
                         "order or uncited.\n  " + "\n  ".join(problems) + "\n")
