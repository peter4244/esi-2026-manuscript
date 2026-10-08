thread: esi-mdcopd-copy
status: close-proposed

## Step 1. Source file, on the Mac

```
$ wc -l < "/Users/petecastaldi/Desktop/COPDGene/Pheno/Visit3/COPDGene_Multidimensional_COPD_plus.csv"
10133

$ head -1 "/Users/petecastaldi/Desktop/COPDGene/Pheno/Visit3/COPDGene_Multidimensional_COPD_plus.csv"
sid,visitnum,MultiDim_COPD_Subtype,MultiDim_COPD_score

$ md5 -q "/Users/petecastaldi/Desktop/COPDGene/Pheno/Visit3/COPDGene_Multidimensional_COPD_plus.csv"
4441da74a18ba9125c5db4096055cdf9
```

Matches expectation: 10,133 lines, first column `sid`, 32-character hash.

## Step 2. Destination, on Channing

```
$ ls -la /proj/regeps/regep00/studies/COPDGene/data/pheno/COPDGene_Multidimensional_COPD_plus.csv
ls: cannot access /proj/regeps/regep00/studies/COPDGene/data/pheno/COPDGene_Multidimensional_COPD_plus.csv: No such file or directory

$ ls -ld /proj/regeps/regep00/studies/COPDGene/data/pheno
drwxrws---. 17 regep00 regeps 169984 Oct  4 09:12 /proj/regeps/regep00/studies/COPDGene/data/pheno
```

File did not exist (as expected for write-new); directory writable. Proceeded to copy.

## Step 3. Copy

```
$ scp "/Users/petecastaldi/Desktop/COPDGene/Pheno/Visit3/COPDGene_Multidimensional_COPD_plus.csv" channing:/proj/regeps/regep00/studies/COPDGene/data/pheno/
```

Exit code 0, no errors.

## Step 4. Check the copy, on Channing

```
$ md5sum /proj/regeps/regep00/studies/COPDGene/data/pheno/COPDGene_Multidimensional_COPD_plus.csv
4441da74a18ba9125c5db4096055cdf9  /proj/regeps/regep00/studies/COPDGene/data/pheno/COPDGene_Multidimensional_COPD_plus.csv

$ wc -l < /proj/regeps/regep00/studies/COPDGene/data/pheno/COPDGene_Multidimensional_COPD_plus.csv
10133

$ ls -la /proj/regeps/regep00/studies/COPDGene/data/pheno/COPDGene_Multidimensional_COPD_plus.csv
-rw-r--r--. 1 repjc regeps 140472 Oct  7 19:29 /proj/regeps/regep00/studies/COPDGene/data/pheno/COPDGene_Multidimensional_COPD_plus.csv
```

MD5 matches step 1 (`4441da74a18ba9125c5db4096055cdf9`). Line count matches step 1 (10,133). Copy verified
byte-identical to the Mac source.

=== END esi-mdcopd-copy ===
