#!/usr/bin/env python3
"""Compare Pete's PJC docx against the .md sources the build reads from.

His edits live only in his docx. The build regenerates the document from
METHODS.md / RESULTS.md / etc., so any edit of his not ported back into those
files is silently reverted on the next build. That has happened three times.

Run this every time he hands over a PJC version, before touching anything:

    python3 diff_pjc.py

His docx is the starting point, not a variant to reconcile against mine. Every
paragraph reported is his text to adopt. Where mine differs, mine is the one
that goes, unless it is a factual correction, and then it is raised with him
rather than applied over his wording.
"""
import difflib
import os
import re
import sys

from docx import Document
from docx.text.paragraph import Paragraph

HERE = os.path.dirname(os.path.abspath(__file__))
PJC = os.path.join(HERE, "manuscript",
                   "CT-free MD-COPD manuscript draft v1_PJC.docx")
SECTIONS = {"ABSTRACT": "ABSTRACT.md", "INTRODUCTION": "INTRODUCTION.md",
            "METHODS": "METHODS.md", "RESULTS": "RESULTS.md",
            "DISCUSSION": "DISCUSSION.md"}


def pjc_paragraphs(path):
    d, out, sec = Document(path), {}, None
    for ch in d.element.body.iterchildren():
        if not ch.tag.endswith("}p"):
            continue
        p = Paragraph(ch, d)
        t = p.text.strip()
        if not t:
            continue
        if p.style.name.startswith("Heading"):
            # Only a top-level heading changes section. Anything after the
            # prose sections (REFERENCES, TABLES, FIGURES) is not source
            # material and must not be diffed against the .md files.
            if p.style.name == "Heading 1":
                sec = t.upper() if t.upper() in SECTIONS else None
            continue
        if sec:
            out.setdefault(sec, []).append(t)
    return out


def source_paragraphs(path):
    out, buf = [], []
    for line in open(path):
        line = line.rstrip("\n")
        if line.startswith(("#", "**[", "*(", "---")) or not line.strip():
            if buf:
                out.append(" ".join(buf))
                buf = []
            continue
        buf.append(line.strip())
    if buf:
        out.append(" ".join(buf))
    return out


def norm(t):
    t = re.sub(r"\{[^}]*\}", "", t)      # claim ids
    t = re.sub(r"\*\*|__|(?<!\w)\*(?!\s)|(?<!\s)\*(?!\w)", "", t)  # emphasis
    return re.sub(r"\s+", " ", t).strip()


def main():
    adopt = "--adopt" in sys.argv
    if not os.path.exists(PJC):
        raise SystemExit(f"no PJC version at {PJC}")
    pjc = pjc_paragraphs(PJC)
    n_diff = 0
    for sec, fn in SECTIONS.items():
        path = os.path.join(HERE, fn)
        if not os.path.exists(path) or sec not in pjc:
            continue
        mine = [norm(x) for x in source_paragraphs(path)]
        for t in (norm(x) for x in pjc[sec]):
            if t in mine:
                continue
            best = max(mine, key=lambda m: difflib.SequenceMatcher(None, t, m).ratio())
            ratio = difflib.SequenceMatcher(None, t, best).ratio()
            # No similarity threshold. A one-word edit ("benefit" to "benefits")
            # scored above the old 0.995 cutoff and was never reported, so it
            # would have been reverted. Every non-identical paragraph is shown.
            n_diff += 1
            print(f"\n=== {sec} / {fn}  (similarity {ratio:.3f}) ===")
            sm = difflib.SequenceMatcher(None, best.split(), t.split())
            for op, i1, i2, j1, j2 in sm.get_opcodes():
                if op == "equal":
                    continue
                print(f"  source: {' '.join(best.split()[i1:i2])[:200]!r}")
                print(f"  PJC   : {' '.join(t.split()[j1:j2])[:200]!r}")
    print(f"\n{n_diff} paragraph(s) differ. His version is the starting point: "
          f"adopt each one.\nRaise factual problems with him instead of editing "
          f"over his wording.")
    if adopt:
        import pjc_guard
        pjc_guard.record()
        print("\nRecorded as reviewed. The builders will run again.\n"
              "Port his edits into the .md sources before building.")
    elif n_diff:
        print("\nThe builders will refuse to run until this is reviewed with:\n"
              "    python3 diff_pjc.py --adopt")
    return 0


if __name__ == "__main__":
    sys.exit(main())
