#!/bin/bash
#SBATCH --job-name=esi_ctfree_c3b
#SBATCH --partition=r9
#SBATCH --qos=linux01
#SBATCH --cpus-per-task=1
#SBATCH --mem=16G
#SBATCH --output=/d/tmp/repjc/esi_ctfree_c3b_20261008/%x_%j.out
#SBATCH --error=/d/tmp/repjc/esi_ctfree_c3b_20261008/%x_%j.err

# FEV1-model check C3b (note esi-c3b). Submit from the esi-ctfree-resp-20261008 clone root:
#   sbatch run_ctfree_c3b.sh
# Re-runs the analysis code in memory up to the discordance section (output redirected to a temporary
# folder; nothing in ctfree/assets is written) and fits random-intercept vs random-slope FEV1 models.

export LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
RS=/app/R-4.5.1@i86-rhel9.0/bin/Rscript
cd "$SLURM_SUBMIT_DIR/ctfree" || exit 1
echo "clone: $SLURM_SUBMIT_DIR  commit: $(git log -1 --format=%h)  host: $(hostname)  start: $(date)"
$RS verification_5step_2026-10-08/step2_cluster_checks/C3b_fev1_model_checks.R
echo "C3b exit: $?  end: $(date)"
