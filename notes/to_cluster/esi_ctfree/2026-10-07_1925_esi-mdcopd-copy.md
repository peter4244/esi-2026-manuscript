# ESI CT-free: copy the Bhatt MD-COPD classification file into pheno/

thread: esi-mdcopd-copy
status: open
kind: write-new

**What this is for.** The CT-free analysis uses Bhatt et al.'s per-participant MD-COPD classification as its
reference. It is not on the cluster. Pete has it on the Mac and decided (2026-10-07) that it goes in the shared
COPDGene phenotype folder with the other main COPDGene files:

- **source (on the Mac):** `/Users/petecastaldi/Desktop/COPDGene/Pheno/Visit3/COPDGene_Multidimensional_COPD_plus.csv`
- **destination (on Channing):** `/proj/regeps/regep00/studies/COPDGene/data/pheno/COPDGene_Multidimensional_COPD_plus.csv`

**Rules for this note**
- **write-new:** one new file at the destination. If the destination already exists, **stop** at step 2 and
  report with `status: awaiting-pete`. Do not overwrite, rename, move or delete anything.
- Do not `chmod`, `chgrp` or `git add` anything, and do not touch the `.git` folder in `pheno/`.
- **Print no participant data:** the header line, counts and checksums only. Never print a data row.
- Run each command as written. If one errors, stop and report it as printed.

---

## Step 1. The source file, on the Mac

Run these three in a shell on the Mac (not on Channing):

```
wc -l < "/Users/petecastaldi/Desktop/COPDGene/Pheno/Visit3/COPDGene_Multidimensional_COPD_plus.csv"
```

```
head -1 "/Users/petecastaldi/Desktop/COPDGene/Pheno/Visit3/COPDGene_Multidimensional_COPD_plus.csv"
```

```
md5 -q "/Users/petecastaldi/Desktop/COPDGene/Pheno/Visit3/COPDGene_Multidimensional_COPD_plus.csv"
```

Expected: about 10,133 lines (the de-identified copy has 10,133), a header whose first column is `sid`, and a
32-character hash. **If the first column is not `sid`, stop and report** with `status: awaiting-claude`. If the
Mac refuses to read the file (`Operation not permitted`), stop and report.

## Step 2. The destination, on Channing

```
ls -la /proj/regeps/regep00/studies/COPDGene/data/pheno/COPDGene_Multidimensional_COPD_plus.csv
```

Expected: `No such file or directory`. **If the file exists, stop** and report with `status: awaiting-pete`.

```
ls -ld /proj/regeps/regep00/studies/COPDGene/data/pheno
```

Report the line as printed. If the copy in step 3 is refused for permissions, stop and report.

## Step 3. Copy

From the Mac:

```
scp "/Users/petecastaldi/Desktop/COPDGene/Pheno/Visit3/COPDGene_Multidimensional_COPD_plus.csv" channing:/proj/regeps/regep00/studies/COPDGene/data/pheno/
```

## Step 4. Check the copy, on Channing

```
md5sum /proj/regeps/regep00/studies/COPDGene/data/pheno/COPDGene_Multidimensional_COPD_plus.csv
```

```
wc -l < /proj/regeps/regep00/studies/COPDGene/data/pheno/COPDGene_Multidimensional_COPD_plus.csv
```

```
ls -la /proj/regeps/regep00/studies/COPDGene/data/pheno/COPDGene_Multidimensional_COPD_plus.csv
```

Expected: the md5 equals step 1's hash, and the line count equals step 1's. Report all three outputs and say
whether the md5 matches.

---

## Report

Write `notes/from_cluster/esi_ctfree/2026-10-07_HHMM_esi-mdcopd-copy.md` with header

```
thread: esi-mdcopd-copy
status: close-proposed
```

(or `awaiting-pete` / `awaiting-claude` if a step said to stop), one section per step with outputs as printed,
and as the very last line:

```
=== END esi-mdcopd-copy ===
```

=== END esi-mdcopd-copy ===
