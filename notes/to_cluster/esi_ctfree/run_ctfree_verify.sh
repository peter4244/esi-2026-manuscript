#!/bin/bash
#SBATCH --job-name=esi_ctfree_verify
#SBATCH --partition=r9
#SBATCH --qos=linux01
#SBATCH --cpus-per-task=1
#SBATCH --mem=16G
#SBATCH --output=/d/tmp/repjc/esi_ctfree_verify_20261008/%x_%j.out
#SBATCH --error=/d/tmp/repjc/esi_ctfree_verify_20261008/%x_%j.err

# Five-step verification, cluster checks (note esi-verify). Submit from the reproduction clone root:
#   sbatch run_ctfree_verify.sh
# 1) independent recomputation (step 1b) -> rc/*.csv ; 2) result-correctness checks C1-C4 (step 2) -> C*.log
# Each part runs even if an earlier one fails. Writes only under /d/tmp/repjc/esi_ctfree_verify_20261008/.

export LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
RS=/app/R-4.5.1@i86-rhel9.0/bin/Rscript
OUT=/d/tmp/repjc/esi_ctfree_verify_20261008
cd "$SLURM_SUBMIT_DIR" || exit 1
echo "clone: $(pwd)  commit: $(git log -1 --format=%h)  host: $(hostname)  start: $(date)"

echo "=== step1b recompute"
$RS ctfree/verification_5step_2026-10-08/step1b_cluster/recompute_ctfree.R "$OUT/rc" > "$OUT/recompute.log" 2>&1
echo "recompute exit: $?  $(date)"

cd ctfree || exit 1
for c in C1_cause_of_death_coverage C2_conventional_spirometry_comparator C3_fev1_model_checks C4_join_integrity; do
  echo "=== step2 $c"
  $RS "verification_5step_2026-10-08/step2_cluster_checks/$c.R" > "$OUT/$c.log" 2>&1
  echo "$c exit: $?  $(date)"
done
echo "end: $(date)"
