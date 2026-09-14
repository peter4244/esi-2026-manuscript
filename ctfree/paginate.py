"""Find the page that text lands on, by rendering a .docx through LibreOffice.

python-docx writes a document without laying it out, so page numbers exist only
after a rendering. The supplement's contents use this to fill in the pages its
headings fall on. LibreOffice and Word paginate slightly differently; the
contents field is also marked for Word to refresh when the file is opened.
"""
import os
import re
import shutil
import subprocess
import tempfile
import unicodedata

import fitz

SOFFICE = shutil.which("soffice") or "/Applications/LibreOffice.app/Contents/MacOS/soffice"


def _key(text):
    """Compare text without case, spacing, punctuation or subscript glyphs."""
    return re.sub(r"[^0-9a-z]+", "", unicodedata.normalize("NFKC", text).lower())


def pdf_pages(docx_path):
    """The text of each rendered page, in page order."""
    if not os.path.exists(SOFFICE):
        raise SystemExit("LibreOffice (soffice) is needed to find page numbers; install it "
                         "or build without the contents")
    work = tempfile.mkdtemp(prefix="paginate_")
    try:
        # A private profile, so a running LibreOffice does not swallow the job.
        r = subprocess.run([SOFFICE, "--headless", f"-env:UserInstallation=file://{work}/profile",
                            "--convert-to", "pdf", "--outdir", work, docx_path],
                           capture_output=True, text=True, timeout=600)
        pdf = os.path.join(work, os.path.splitext(os.path.basename(docx_path))[0] + ".pdf")
        if r.returncode != 0 or not os.path.exists(pdf):
            raise SystemExit(f"LibreOffice could not render {docx_path}: {r.stderr[-400:]}")
        with fitz.open(pdf) as doc:
            return [_key(p.get_text()) for p in doc]
    finally:
        shutil.rmtree(work, ignore_errors=True)


def pages_of(pages, text):
    """Every page (1-based) whose text contains text."""
    k = _key(text)
    hits = [i + 1 for i, p in enumerate(pages) if k in p]
    if not hits:
        raise SystemExit(f"not found on any rendered page: {text[:70]}")
    return hits


def last_page_of(pages, text):
    """The last page holding text. A heading also appears in the contents, which
    come first, so its own page is the last one it is found on."""
    return pages_of(pages, text)[-1]
