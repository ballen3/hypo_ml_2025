#!/bin/bash 
#SBATCH --account=arsef
#SBATCH --job-name=merops_array_1
#SBATCH -p ceres
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --cpus-per-task=8
#SBATCH --array=0-918%20 
#SBATCH --mem=32G
#SBATCH -t 5-00:00:00
#SBATCH --mail-user=bma66@cornell.edu
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH -o /project/arsef/projects/hypo_ml_2025/logs/merops/%x.%j.%N.o
#SBATCH -e /project/arsef/projects/hypo_ml_2025/logs/merops/%x.%j.%N.e

module load blast+/2.15.0 # or source your environment

echo "=== JOB START ==="
date; hostname; pwd         
echo "Running on SLURM_ARRAY_TASK_ID: $SLURM_ARRAY_TASK_ID"

## Record software versions in output/log 
#(!!remember to change this if you change versions!!)
echo "*** Software Versions ***"
echo "BLAST Version: blast+/2.15.0"


# Set input and output directories
DATA_DIR=/project/arsef/projects/hypo_ml_2025/data/faa
DB_PATH=/project/arsef/projects/hypo_ml_2025/data/databases/merops_pepunit_db/merops_pepunit_db

# Timestamp-based run ID
RUN_ID=$(date +%Y%m%d_%H%M%S)_${SLURM_ARRAY_TASK_ID}
RUNDIR="/90daydata/arsef/merops/${RUN_ID}"
INPUT_90dd="${RUNDIR}/input"
OUTPUT_BASE_90dd="${RUNDIR}/output"

mkdir -p "$INPUT_90dd"
mkdir -p "$OUTPUT_BASE_90dd"

# Load list of input files
FAA_FILES=("$DATA_DIR"/*.faa)

# Check for out-of-bounds array index
if [ "$SLURM_ARRAY_TASK_ID" -ge "${#FAA_FILES[@]}" ]; then
    echo "Error: SLURM_ARRAY_TASK_ID=$SLURM_ARRAY_TASK_ID exceeds available input files (${#FAA_FILES[@]})."
    exit 1
fi

# Define input and output paths
INPUT="${FAA_FILES[$SLURM_ARRAY_TASK_ID]}"
BASENAME=$(basename "$INPUT" .faa)
OUTPUT_90dd="${OUTPUT_BASE_90dd}/${BASENAME}"

mkdir -p "$OUTPUT_90dd"

# Copy input to 90-day input dir
cp "$INPUT" "${INPUT_90dd}/${BASENAME}.faa"

# Move into the output dir for this task
cd "$OUTPUT_90dd" || { echo "Failed to cd into output dir: $OUTPUT_90dd"; exit 1; }

# Run BLAST
blastp \
  -query "$INPUT" \
  -db "$DB_PATH" \
  -out "${OUTPUT_90dd}/${BASENAME}_vs_merops.tsv" \
  -evalue 1e-5 \
  -outfmt 6 \
  -max_target_seqs 5 \
  -num_threads 4

