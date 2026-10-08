#!/bin/bash
#SBATCH --job-name=esi_ctfree_rs
#SBATCH --partition=r9
#SBATCH --qos=linux01
#SBATCH --cpus-per-task=1
#SBATCH --mem=16G
#SBATCH --output=/d/tmp/repjc/esi_ctfree_rs_20261008/%x_%j.out
#SBATCH --error=/d/tmp/repjc/esi_ctfree_rs_20261008/%x_%j.err

# FEV1 random-slope sensitivity (note esi-rs). Submit from the esi-ctfree-resp-20261008 clone root:
#   sbatch run_ctfree_rs.sh
# Re-renders the analysis (bootstrap caches are reused, so every existing table should be unchanged),
# adds fev1_decline_random_slope.csv, runs verify.R, and compares all tables with the v6 source tables
# kept in ctfree_assets_6118470/.

export LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
RS=/app/R-4.5.1@i86-rhel9.0/bin/Rscript
cd "$SLURM_SUBMIT_DIR" || exit 1
echo "clone: $(pwd)  commit: $(git log -1 --format=%h)  host: $(hostname)  start: $(date)"
md5sum ctfree/ESI_ctfree_analysis_2026.9.3.Rmd
echo "=== render"
$RS ctfree/render_ctfree_2026.9.3.R
echo "render exit: $?  $(date)"
echo "=== verify.R"
$RS ctfree/verify.R
echo "verify exit: $?  $(date)"
echo "=== compare with the v6 source tables"
$RS ctfree_compare_assets.R ctfree_assets_6118470
echo "compare exit: $?  $(date)"
echo "=== new table"
cat ctfree/assets/fev1_decline_random_slope.csv
echo "end: $(date)"
