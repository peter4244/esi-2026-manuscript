"""Refuse to write a .docx that Microsoft Word has open.

The builders overwrite their output documents. If Pete has one open in Word,
the rebuild silently diverges from what he is looking at, and his next save
either clobbers the rebuild or loses edits he made in the open copy. This
happened on 2026-09-13 when a rebuild ran without the manual check.
"""
import subprocess


def word_open_files(lsof_output=None):
    """Paths Word currently holds open. lsof_output is injectable for testing."""
    if lsof_output is None:
        try:
            lsof_output = subprocess.run(["lsof", "-c", "Microsoft Word"], capture_output=True,
                                         text=True, timeout=30).stdout
        except (OSError, subprocess.TimeoutExpired):
            return []
    return [line.split(None, 8)[-1] for line in lsof_output.splitlines() if ".docx" in line]


def check(paths, build_name="this build", lsof_output=None):
    """Stop the build if any output path is open in Word."""
    held = word_open_files(lsof_output)
    hits = [p for p in paths if any(h.endswith(p.split("/")[-1]) for h in held)]
    if hits:
        raise SystemExit(f"\nREFUSING TO BUILD. {build_name}: Word has these files open:\n  "
                         + "\n  ".join(hits) + "\nClose them in Word, then build again.\n")
