#!/bin/bash 
#SBATCH --account=arsef
#SBATCH --job-name=phobius_additional
#SBATCH -p ceres
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --cpus-per-task=1
#SBATCH --array=0-334%20 #335 total .faa files as of 01-23-2026
#SBATCH --mem=32G
#SBATCH -t 5-00:00:00
#SBATCH --mail-user=bma66@cornell.edu
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH -o /project/arsef/projects/hypo_ml_2025/logs/phobius/%x.%j.%N.o
#SBATCH -e /project/arsef/projects/hypo_ml_2025/logs/phobius/%x.%j.%N.e

# === Environment Setup ===
source /software/el9/apps/miniconda/24.7.1-2/etc/profile.d/conda.sh
conda activate phobius_env

echo "=== JOB START ==="
date; hostname; pwd         
echo "Running on SLURM_ARRAY_TASK_ID: $SLURM_ARRAY_TASK_ID"

echo "*** Software Versions ***"
echo "Phobius Version: 1.01"

# === Define Paths ===
DATA_DIR="/home/brooke.allen/hypo/data/full_db_addl_files/db_addl_faa"
RUN_ID=$(date +%Y%m%d_%H%M%S)_${SLURM_ARRAY_TASK_ID}
RUNDIR="/90daydata/arsef/phobius_addl_${RUN_ID}"
INPUT_90dd="${RUNDIR}/input"
TEMP_DIR="${RUNDIR}/input/temp_cleaned"
OUTPUT_BASE_90dd="${RUNDIR}/output"

# Make sure output and temp dirs exist
mkdir -p "$INPUT_90dd"
mkdir -p "$OUTPUT_BASE_90dd"
mkdir -p "$TEMP_DIR"

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

# Input File Check
if [[ ! -f "$INPUT" ]]; then
    echo "ERROR: Input file not found at $INPUT" >&2
    exit 1
fi

# Copy input to 90-day input dir
#cp "$INPUT" "${INPUT_90dd}/${BASENAME}.faa"

# Move into the output dir for this task
cd "$OUTPUT_90dd" || { echo "Failed to cd into output dir: $OUTPUT_90dd"; exit 1; }

# === Clean Input: Remove '*' Characters ===
CLEANED="${TEMP_DIR}/${BASENAME}_clean.faa"

# === Clean only if cleaned file doesn't exist ===
# (remove '*' characters and replace 'J' with 'X')
if [[ -s "$CLEANED" ]]; then
    echo "Cleaned file already exists, reusing: $CLEANED"
else
    echo "Cleaning input file (removing '*' characters)..."
    sed '/^>/! s/\*//g' "$INPUT" | tr 'J' 'X' > "$CLEANED" || {
    echo "ERROR: sed/tr failed" >&2
    exit 2
}

    # Check if cleaning succeeded
    if [[ ! -s "$CLEANED" ]]; then
        echo "ERROR: Cleaning failed — cleaned file is missing or empty: $CLEANED" >&2
        exit 2
    fi

    echo "Created cleaned file: $CLEANED"
fi

test -s "$CLEANED" && echo "Cleaned file exists and is not empty" || echo "Cleaned file missing or empty"


# === Run Phobius ===
echo "Running: phobius.pl -short $CLEANED > $OUTPUT_90dd/${BASENAME}_phobius.short.out"
phobius.pl -short "$CLEANED" > "$OUTPUT_90dd/${BASENAME}_phobius.short.out"

OUTPUT_FILE="$OUTPUT_90dd/${BASENAME}_phobius.short.out"

if [[ -s "$OUTPUT_FILE" ]]; then
    rm "$CLEANED"
    echo "Deleted temporary cleaned file: $CLEANED"
else
    echo "WARNING: Output file not found or empty — keeping cleaned file for debugging: $CLEANED"
fi

# === Done ===
echo "=== JOB END ==="
date

