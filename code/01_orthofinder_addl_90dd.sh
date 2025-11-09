#!/bin/bash 
#SBATCH --account=arsef
#SBATCH --job-name="orthofinder_addl_90dd_7"
#SBATCH -p ceres
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --cpus-per-task=64
#SBATCH --mem=256G 
#SBATCH -t 5-00:00:00
#SBATCH --mail-user=bma66@cornell.edu
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH -o /project/arsef/projects/hypo_ml_2025/logs/orthofinder/%x.%j.%N.o
#SBATCH -e /project/arsef/projects/hypo_ml_2025/logs/orthofinder/%x.%j.%N.e

#Author: Brooke Allen
#Date: 2024-06-17
#Written for use on the USDA CERES cluster 
#Description: Run OrthoFinders 'scalable implementation' on additional genomes after running the core set. 
#To use:
    #1. Run the core set first (01_orthofinder_core_90dd.sh)
    #2. Update the job name and output paths in the SBATCH directives above
    #3. Load the appropriate OrthoFinder module
    #3. Update the INPUT_DIR (additional files), CORE_DIR (core set), and PERM_OUTPUT_BASE (final output dir) variables 
    #4. Updata the TMPDIR and XDG_CACHE_HOME paths 
    #5. Optionally set a custom RUN_ID (defaults to timestamp)
    #6. Run this script with sbatch
# Outputs:
#   - Working files in $RUNDIR on fast scratch
#   - Final results in $FINAL_OUTPUT_DIR


echo "=== JOB START ==="
date
hostname
pwd
echo "====================="

# Load OrthoFinder module
module load orthofinder/3.0.1b1
VERSION=$(orthofinder -v)
echo "OrthoFinder version: $VERSION"
echo "Python version: $(python --version)"
echo "====================="
# Define paths
INPUT_DIR="/project/arsef/projects/hypo_ml_2025/data/of_addl_faa"
CORE_DIR="/home/brooke.allen/hypo/output/of_output/of_core"
PERM_OUTPUT_BASE="/project/arsef/projects/hypo_ml_2025/output/of_output/of_full"

# Redirect all temporary and cache files to 90daydata
# Orthofinder was defaulting to my home dir and running out of space
export TMPDIR="/90daydata/arsef/of_tmp"
export TEMP="$TMPDIR"
export TMP="$TMPDIR"
export XDG_CACHE_HOME="/90daydata/arsef/of_cache"
mkdir -p "$TMPDIR"
mkdir -p "$XDG_CACHE_HOME"

# Optional: confirm it's set
echo "Temporary directory: $TMPDIR"
echo "Cache directory: $XDG_CACHE_HOME"
echo "====================="

#------------------------------------------------------------------------
# Use provided RUN_ID or generate a new one (defaults to timestamp)
# To provide a RUN_ID, before running sbatch, do:
# export RUN_ID="2123123123"
# sbatch your_script.sh
if [ -z "$RUN_ID" ]; then
    RUN_ID=$(date +%Y%m%d_%H%M%S)
fi
RUNDIR="/90daydata/arsef/orthofinder_run_${RUN_ID}"
FINAL_OUTPUT_DIR="${PERM_OUTPUT_BASE}/${RUN_ID}"

echo "Creating working directory in: $RUNDIR"
mkdir -p "$RUNDIR"
mkdir -p "$FINAL_OUTPUT_DIR"
echo "====================="

# Copy addl input to 90daydata
echo "Copying input data to /90daydata..."
rsync -av "$INPUT_DIR"/ "$RUNDIR/faa_addl/"

# Copy core results to 90daydata 
# (!!) OrthoFinder needs the whole Results_* directory, named exactly like that (eg. Results_Sep29), to work
echo "Copying core data to /90daydata..."
CORE_RESULTS_DIR=$(find "$CORE_DIR" -maxdepth 1 -type d -name "Results_*" | head -n 1)
if [ -z "$CORE_RESULTS_DIR" ]; then
    echo "ERROR: No Results_* directory found in CORE_DIR ($CORE_DIR)"
    exit 1
fi
CORE_RESULTS_BASENAME=$(basename "$CORE_RESULTS_DIR")
rsync -av "$CORE_RESULTS_DIR"/ "$RUNDIR/$CORE_RESULTS_BASENAME/"

echo "*** Count and list files in faa_addl ***"
ls "$RUNDIR/faa_addl" | wc -l 
ls "$RUNDIR/faa_addl"

echo "*** Count and list files in Results_* ***"
ls "$RUNDIR/Results_*" | wc -l 
ls "$RUNDIR/Results_*"

# Run OrthoFinder in 90daydata
echo "Running OrthoFinder in: $RUNDIR"
cd "$RUNDIR"
orthofinder \
    --assign "faa_addl" \
    --core "$CORE_RESULTS_BASENAME" \
    -t 64 -a 64

# Copy only final results back to /project
RESULTS_DIR=$(find "$RUNDIR" -maxdepth 1 -type d -name "Results_*" | head -n 1)
if [ -d "$RESULTS_DIR" ]; then
    echo "Copying final results to: $FINAL_OUTPUT_DIR"
    rsync -av "$RESULTS_DIR/" "$FINAL_OUTPUT_DIR/"
else
    echo "WARNING: No Results* directory found — skipping copy!"
fi

echo "=== JOB END ==="
date