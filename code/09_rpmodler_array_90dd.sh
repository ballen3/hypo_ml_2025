#!/bin/bash 
#SBATCH --account=arsef
#SBATCH --job-name=repeatmodeler_array_90dd_1
#SBATCH -p ceres
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --cpus-per-task=16
#SBATCH --array=0-918%20
#SBATCH --mem=64G
#SBATCH -t 5-00:00:00
#SBATCH --mail-user=bma66@cornell.edu
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH -o /project/arsef/projects/hypo_ml_2025/logs/rpm/%x.%j.%N.o
#SBATCH -e /project/arsef/projects/hypo_ml_2025/logs/rpm/%x.%j.%N.e

# Load module
module load repeatmodeler/2.0.5

echo "=== JOB START ==="
date; hostname; pwd         
echo "Running on SLURM_ARRAY_TASK_ID: $SLURM_ARRAY_TASK_ID"

# Software version logging
echo "*** Software Versions ***"
echo "RepeatModeler Version: 2.0.5"

# Set permanent data dir (where input .fna files are)
DATA_DIR="/project/arsef/projects/hypo_ml_2025/data/fna"

# Timestamp-based run ID
RUN_ID=$(date +%Y%m%d_%H%M%S)_${SLURM_ARRAY_TASK_ID}
RUNDIR="/90daydata/arsef/rpmodler/${RUN_ID}"
INPUT_90dd="${RUNDIR}/input"
OUTPUT_BASE_90dd="${RUNDIR}/output"

mkdir -p "$INPUT_90dd"
mkdir -p "$OUTPUT_BASE_90dd"

# Load list of input files
FNA_FILES=("$DATA_DIR"/*.fna)

# Check for out-of-bounds array index
if [ "$SLURM_ARRAY_TASK_ID" -ge "${#FNA_FILES[@]}" ]; then
    echo "Error: SLURM_ARRAY_TASK_ID=$SLURM_ARRAY_TASK_ID exceeds available input files (${#FNA_FILES[@]})."
    exit 1
fi

# Define input and output paths
INPUT="${FNA_FILES[$SLURM_ARRAY_TASK_ID]}"
BASENAME=$(basename "$INPUT" .fna)
DB_NAME="${BASENAME}_db"
OUTPUT_90dd="${OUTPUT_BASE_90dd}/${BASENAME}"

mkdir -p "$OUTPUT_90dd"

# Copy input to 90-day input dir
cp "$INPUT" "${INPUT_90dd}/${BASENAME}.fna"

# Move into the output dir for this task
cd "$OUTPUT_90dd" || { echo "Failed to cd into output dir: $OUTPUT_90dd"; exit 1; }

# Build RepeatModeler database (if not already exists)
if [ ! -f "${DB_NAME}.nhr" ]; then
    echo "[$(date)] Building RepeatModeler database: $DB_NAME"
    BuildDatabase -name "$DB_NAME" -engine rmblast "$INPUT_90dd/${BASENAME}.fna"

    if [ ! -f "${DB_NAME}.nhr" ]; then
        echo "Database creation failed. Exiting."
        exit 1
    fi
else
    echo "Database already exists. Skipping BuildDatabase."
fi

# Run RepeatModeler
echo "[$(date)] Running RepeatModeler..."
RepeatModeler \
  -database "$DB_NAME" \
  -threads 16 \
  -LTRStruct \
  -dir "$OUTPUT_90dd"

echo "[$(date)] RepeatModeler finished for $BASENAME"

# Rename RM output directory and files
# Identify RM_* dir created by RepeatModeler
RM_DIR_ORIG=$(find "$OUTPUT_90dd" -maxdepth 1 -type d -name "RM_*" | head -n 1)

if [ -z "$RM_DIR_ORIG" ]; then
    echo "No RM_* directory found! Exiting."
    exit 1
fi

# Construct new name and move
RM_BASENAME="$(basename "$RM_DIR_ORIG")"
RM_DIR_RENAMED="${OUTPUT_90dd}/${BASENAME}_${RM_BASENAME}"

mv "$RM_DIR_ORIG" "$RM_DIR_RENAMED"

# Rename all files inside RM dir to include BASENAME
for f in "$RM_DIR_RENAMED"/*; do
    mv "$f" "${RM_DIR_RENAMED}/${BASENAME}_$(basename "$f")"
done

echo "[$(date)] Renamed output dir to: $RM_DIR_RENAMED"

# Example commands to run manually
#BuildDatabase -name BLD.DB -engine rmblast contigs_filter1_nematoda_nohit.fa
#RepeatModeler -database BLD.DB -engine ncbi -threads 16