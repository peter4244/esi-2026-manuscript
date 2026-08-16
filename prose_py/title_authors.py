"""Title, authors, affiliations, and keywords block for the main manuscript.

Emitted first in the document, before the abstract. Follows the AJRCCM
convention: centered title (bold), author list (comma-separated, superscript
affiliation numbers), affiliation footnotes (one per line), keywords line.
"""
from docx.enum.text import WD_PARAGRAPH_ALIGNMENT
from docx.shared import Pt

from tables.docx_helpers import FONT_NAME, BODY_FS


TITLE = ("The Emphysema Severity Index: A Spirometric Representation of "
         "CT-Defined Structural Abnormalities in a Multidimensional COPD "
         "Framework")

AUTHORS = ("Peter J. Castaldi¹,²; Matteo Paoletti³; Mariaelena Occhipinti⁴; "
           "Alessandra Sorano³; Federico Lavorini³; Enrico Maiorino¹; "
           "Craig P. Hersh¹,⁵; Edwin K. Silverman¹,⁵; Massimo Pistolesi³")

AFFILIATIONS = [
    "¹ Channing Division of Network Medicine, Brigham and Women's Hospital, "
    "Boston, MA, USA",
    "² Division of General Internal Medicine and Primary Care, Brigham and "
    "Women's Hospital, Boston, MA, USA",
    "³ Department of Experimental and Clinical Medicine, University of "
    "Florence, Florence, Italy",
    "⁴ Division of Radiology, Fondazione Toscana Gabriele Monasterio, Pisa, "
    "Italy",
    "⁵ Division of Pulmonary and Critical Care Medicine, Brigham and "
    "Women's Hospital, Boston, MA, USA",
]

KEYWORDS = ("Key words: Chronic Obstructive Pulmonary Disease; Spirometry; "
            "Pulmonary Emphysema; Computed Tomography; Respiratory Function "
            "Tests")


def _para(doc, text, bold=False, size=None, align=None):
    p = doc.add_paragraph()
    if align is not None:
        p.alignment = align
    r = p.add_run(text)
    r.font.name = FONT_NAME
    r.font.size = Pt(size if size is not None else BODY_FS)
    r.bold = bold
    return p


def build(doc):
    _para(doc, TITLE, bold=True, size=BODY_FS + 2,
          align=WD_PARAGRAPH_ALIGNMENT.CENTER)
    _para(doc, "")
    _para(doc, AUTHORS, align=WD_PARAGRAPH_ALIGNMENT.CENTER)
    _para(doc, "")
    for aff in AFFILIATIONS:
        _para(doc, aff)
    _para(doc, "")
    _para(doc, KEYWORDS)
