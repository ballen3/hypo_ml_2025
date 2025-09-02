#!/bin/bash 
#SBATCH --account=arsef
#SBATCH --job-name="orthofinder_4_long"
#SBATCH --qos=long
#SBATCH -p ceres
#SBATCH -N 1
#SBATCH -n 128
#SBATCH --mem=1800G 
#SBATCH -t 60-00:00:00
#SBATCH --mail-user=bma66@cornell.edu
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH -o /project/arsef/projects/hypo_ml_2025/logs/%x.%j.%N.o
#SBATCH -e /project/arsef/projects/hypo_ml_2025/logs/%x.%j.%N.e

echo "=== JOB START ==="
date
hostname
pwd

module load orthofinder/3.0.1b1
echo "OrthoFinder version: 3.0.1b1"

# Define paths
INPUT_DIR="/project/arsef/projects/hypo_ml_2025/data/faa"
PERM_OUTPUT_BASE="/project/arsef/projects/hypo_ml_2025/output/of_output"
RUN_ID=$(date +%Y%m%d_%H%M%S)
RUNDIR="/90daydata/arsef/orthofinder_run_${RUN_ID}"
FINAL_OUTPUT_DIR="${PERM_OUTPUT_BASE}/${RUN_ID}"

echo "Creating working directory in: $RUNDIR"
mkdir -p "$RUNDIR"
mkdir -p "$FINAL_OUTPUT_DIR"

# Copy input to 90daydata
echo "Copying input data to /90daydata..."
rsync -av "$INPUT_DIR"/ "$RUNDIR/faa/"

# Run OrthoFinder in 90daydata
cd "$RUNDIR"
echo "Running OrthoFinder in: $RUNDIR"
orthofinder -f "$RUNDIR/faa" -o "$RUNDIR/of_output" -t 128 -a 128

# Copy only final results back to /project
RESULTS_DIR=$(find "$RUNDIR/of_output" -type d -name "Results*" | head -n 1)
if [ -d "$RESULTS_DIR" ]; then
    echo "Copying final results to: $FINAL_OUTPUT_DIR"
    rsync -av "$RESULTS_DIR/" "$FINAL_OUTPUT_DIR/"
else
    echo "WARNING: No Results* directory found — skipping copy!"
fi

echo "=== JOB END ==="
date
