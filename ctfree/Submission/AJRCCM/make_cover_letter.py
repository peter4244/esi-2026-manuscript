#!/usr/bin/env python3
"""Cover letter .docx from COVER_LETTER.md (blank-line paragraphs; lines starting
"- " become bullets). Refuses to overwrite a .docx saved after the .md."""
import os
import sys
import docx
from docx.shared import Pt, Inches

HERE = os.path.dirname(os.path.abspath(__file__))
SRC, OUT = os.path.join(HERE, "COVER_LETTER.md"), os.path.join(HERE, "Cover letter AJRCCM.docx")
if os.path.exists(OUT) and os.path.getmtime(OUT) > os.path.getmtime(SRC) and "--force" not in sys.argv:
    raise SystemExit(f"{OUT} was saved after {SRC}; port its edits first")
d = docx.Document()
for s in d.sections:
    s.left_margin = s.right_margin = s.top_margin = s.bottom_margin = Inches(1)
st = d.styles["Normal"]
st.font.name, st.font.size = "Arial", Pt(11)
st.paragraph_format.space_after = Pt(8)
for b in open(SRC).read().strip().split("\n\n"):
    lines = b.split("\n")
    if all(l.startswith("- ") for l in lines):
        for l in lines:
            d.add_paragraph(l[2:], style="List Bullet")
    else:
        p = d.add_paragraph()
        for i, l in enumerate(lines):
            if i:
                p.add_run().add_break()
            p.add_run(l)
d.core_properties.author, d.core_properties.title, d.core_properties.comments = "Peter J. Castaldi", "Cover letter", ""
d.save(OUT)
print("wrote", OUT)
