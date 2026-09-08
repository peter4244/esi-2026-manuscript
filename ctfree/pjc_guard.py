"""Refuse to build a manuscript that would overwrite unadopted PJC edits.

Pete edits the rendered .docx. The builders regenerate it from the .md sources,
so any edit of his not ported back is destroyed on the next build. This has now
happened four times, the last because diff_pjc.py was run and its output piped
away unread.

The guard: record the mtime of the PJC file at the moment its differences were
last reviewed, in .pjc_adopted. If the PJC is newer than that, the build stops
and prints the differences. Reviewing is an explicit act:

    python3 diff_pjc.py --adopt

which prints every difference and then records the mtime. There is no way to
build past a newer PJC without seeing the diff first.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
PJC = os.path.join(HERE, "manuscript",
                   "CT-free MD-COPD manuscript draft v1_PJC.docx")
STAMP = os.path.join(HERE, ".pjc_adopted")


def pjc_mtime():
    return os.path.getmtime(PJC) if os.path.exists(PJC) else None


def adopted_mtime():
    try:
        return float(open(STAMP).read().strip())
    except (OSError, ValueError):
        return None


def record():
    m = pjc_mtime()
    if m is not None:
        with open(STAMP, "w") as f:
            f.write(repr(m))
    return m


def check(build_name="this build"):
    """Stop the build if the PJC has changed since its edits were reviewed."""
    m = pjc_mtime()
    if m is None:
        return
    a = adopted_mtime()
    if a is not None and m <= a + 1e-6:
        return
    import time
    when = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(m))
    sys.stderr.write(
        f"\nREFUSING TO BUILD.\n"
        f"  {os.path.basename(PJC)} was saved at {when} and its differences\n"
        f"  have not been reviewed. {build_name} would overwrite Pete's edits.\n\n"
        f"  Run:  python3 diff_pjc.py --adopt\n"
        f"  Read every difference, port his edits into the .md sources, then\n"
        f"  build again.\n\n")
    raise SystemExit(2)
