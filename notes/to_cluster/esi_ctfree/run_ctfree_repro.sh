#!/bin/bash
#SBATCH --job-name=esi_ctfree_repro
#SBATCH --partition=r9
#SBATCH --qos=linux01
#SBATCH --cpus-per-task=1
#SBATCH --mem=16G
#SBATCH --output=/d/tmp/repjc/esi_ctfree_repro_20261007/%x_%j.out
#SBATCH --error=/d/tmp/repjc/esi_ctfree_repro_20261007/%x_%j.err

# CT-free MD-COPD reproduction on Channing (note esi-repro_r2). Submit from the clone root:
#   sbatch run_ctfree_repro.sh
# Renders the analysis (rewrites ctfree/assets/), runs verify.R, then compares with the laptop's assets.

export LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
RS=/app/R-4.5.1@i86-rhel9.0/bin/Rscript
cd "$SLURM_SUBMIT_DIR" || exit 1
echo "clone: $(pwd)  commit: $(git log -1 --format=%h)  host: $(hostname)  start: $(date)"

echo "=== render"
$RS ctfree/render_ctfree_2026.9.3.R
echo "render exit: $?  $(date)"

echo "=== verify.R"
$RS ctfree/verify.R
echo "verify exit: $?  $(date)"

echo "=== compare with laptop assets"
$RS ctfree_compare_assets.R
echo "compare exit: $?  end: $(date)"
