#!/bin/bash 
#SBATCH --account=arsef
#SBATCH --job-name="orthofinder_core_90dd"
#SBATCH -p ceres
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --cpus-per-task=64
#SBATCH --mem=128G 
#SBATCH -t 5-00:00:00
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
INPUT_DIR="/home/brooke.allen/hypo/data/OF_core_faa"
PERM_OUTPUT_BASE="/project/arsef/projects/hypo_ml_2025/output/of_output/of_core"
RUN_ID=$(date +%Y%m%d_%H%M%S)
RUNDIR="/90daydata/arsef/orthofinder_run_${RUN_ID}"
FINAL_OUTPUT_DIR="${PERM_OUTPUT_BASE}/${RUN_ID}"

echo "Creating working directory in: $RUNDIR"
mkdir -p "$RUNDIR"
mkdir -p "$FINAL_OUTPUT_DIR"
mkdir -p "$RUNDIR/faa_core"

# Copy input to 90daydata
echo "Copying input data to /90daydata..."
rsync -av "$INPUT_DIR"/ "$RUNDIR/faa_core/"

# Run OrthoFinder in 90daydata
cd "$RUNDIR"
echo "Running OrthoFinder in: $RUNDIR"
orthofinder -f "$RUNDIR/faa_core/" -o "$RUNDIR/of_core_output" -t 64 -a 64

# Copy only final results back to /project
# (!!) the next OF run looks for "Results_*" inside the "OrthoFinder" directory so be careful renaming directories
RESULTS_DIR=$(find "$RUNDIR/of_core_output" -type d -name "Results*" | head -n 1)
if [ -d "$RESULTS_DIR" ]; then
    echo "Copying final results to: $FINAL_OUTPUT_DIR"
    rsync -av "$RESULTS_DIR/" "$FINAL_OUTPUT_DIR/"
else
    echo "WARNING: No Results* directory found — skipping copy!"
fi

echo "=== JOB END ==="
date

echo "Job stats:"
seff $SLURM_JOB_ID