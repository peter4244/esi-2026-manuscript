thread: esi-repro
status: open

Pete gave his "go" in the Copilot chat at 21:26. Part 2 submitted.

## Step 1. Submit

```
$ cd /proj/regeps/regep00/studies/COPDGene/analyses/repjc/COPDGene/ESI_MDCOPD_2026/esi-ctfree-repro-20261007 && sbatch run_ctfree_repro.sh
Submitted batch job 6116301
```

**Job ID: 6116301.** Submitted 2026-10-07 21:26.

Log files will be `/d/tmp/repjc/esi_ctfree_repro_20261007/esi_ctfree_repro_6116301.out` and `.err`.

Now polling with `sacct -j 6116301 --format=JobID,State,Elapsed,MaxRSS,ExitCode` at no more than once a
minute until the state is terminal. No resubmission, no `scancel`, no edits. The final report will follow
as `2026-10-07_HHMM_esi-repro_r3.md` (or a later date if the job runs past midnight).

=== END esi-repro_r3_submitted ===
