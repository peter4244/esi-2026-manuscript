#!/bin/bash
#SBATCH --job-name=esi_ctfree_resp
#SBATCH --partition=r9
#SBATCH --qos=linux01
#SBATCH --cpus-per-task=1
#SBATCH --mem=16G
#SBATCH --output=/d/tmp/repjc/esi_ctfree_resp_20261008/%x_%j.out
#SBATCH --error=/d/tmp/repjc/esi_ctfree_resp_20261008/%x_%j.err

# Respiratory-mortality rerun (note esi-resp). Submit from the esi-ctfree-resp-20261008 clone root:
#   sbatch run_ctfree_resp.sh
# Renders the analysis with respiratory mortality censored at the cause-of-death window (rewrites
# ctfree/assets/), runs verify.R (respiratory claims are expected to fail: their values change),
# compares with the first cluster run's tables (ctfree_assets_prev/), then checks C3 and C5.

export LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
RS=/app/R-4.5.1@i86-rhel9.0/bin/Rscript
OUT=/d/tmp/repjc/esi_ctfree_resp_20261008
cd "$SLURM_SUBMIT_DIR" || exit 1
echo "clone: $(pwd)  commit: $(git log -1 --format=%h)  host: $(hostname)  start: $(date)"
md5sum ctfree/ESI_ctfree_analysis_2026.9.3.Rmd ctfree/verify.R

echo "=== render"
$RS ctfree/render_ctfree_2026.9.3.R
echo "render exit: $?  $(date)"

echo "=== verify.R"
$RS ctfree/verify.R
echo "verify exit: $?  $(date)"

echo "=== compare with the first cluster run"
$RS ctfree_compare_assets.R ctfree_assets_prev
echo "compare exit: $?  $(date)"

cd ctfree || exit 1
for c in C3_fev1_model_checks C5_zero_followup; do
  echo "=== step2 $c"
  $RS "verification_5step_2026-10-08/step2_cluster_checks/$c.R" > "$OUT/$c.log" 2>&1
  echo "$c exit: $?  $(date)"
done
echo "end: $(date)"
