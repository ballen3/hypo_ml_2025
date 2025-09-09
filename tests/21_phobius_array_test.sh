#!/bin/bash 
#SBATCH --account=arsef
#SBATCH --job-name=phobius_array_test_5
#SBATCH -p ceres
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --cpus-per-task=8
#SBATCH --array=0-3
#SBATCH --mem=32G
#SBATCH -t 24:00:00
#SBATCH --mail-user=bma66@cornell.edu
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH -o /project/arsef/projects/hypo_ml_2025/tests/test_oe/%x.%j.%N.o
#SBATCH -e /project/arsef/projects/hypo_ml_2025/tests/test_oe/%x.%j.%N.e

# === Environment Setup ===
source /software/el9/apps/miniconda/24.7.1-2/etc/profile.d/conda.sh
conda activate phobius_env

echo "=== JOB START ==="
date; hostname; pwd         
echo "Running on SLURM_ARRAY_TASK_ID: $SLURM_ARRAY_TASK_ID"

echo "*** Software Versions ***"
echo "Phobius Version: 1.01"

# === Define Paths ===
DATA_DIR=/project/arsef/projects/hypo_ml_2025/tests/test_data/test_faa
OUT_DIR=/project/arsef/projects/hypo_ml_2025/tests/test_outputs/phobius_test_output
TEMP_DIR=/project/arsef/projects/hypo_ml_2025/tests/test_data/test_faa/phobius_temp_cleaned
#PHOBIUS=/project/arsef/projects/hypo_ml_2025/phobius/phobius.pl

# Make sure output and temp dirs exist
mkdir -p "$OUT_DIR"
mkdir -p "$TEMP_DIR"

# === Select Input File Based on Array Index ===
FASTA_FILES=($DATA_DIR/*.faa)
INPUT="${FASTA_FILES[$SLURM_ARRAY_TASK_ID]}"
BASENAME=$(basename "$INPUT" .faa)

# === Input File Check ===
if [[ ! -f "$INPUT" ]]; then
    echo "ERROR: Input file not found at $INPUT" >&2
    exit 1
fi

# === Clean Input: Remove '*' Characters ===
CLEANED="${TEMP_DIR}/${BASENAME}_clean.faa"

# === Clean only if cleaned file doesn't exist ===
if [[ -s "$CLEANED" ]]; then
    echo "Cleaned file already exists, reusing: $CLEANED"
else
    echo "Cleaning input file (removing '*' characters)..."
    sed '/^>/! s/\*//g' "$INPUT" > "$CLEANED"

    # Check if cleaning succeeded
    if [[ ! -s "$CLEANED" ]]; then
        echo "ERROR: Cleaning failed — cleaned file is missing or empty: $CLEANED" >&2
        exit 2
    fi

    echo "Created cleaned file: $CLEANED"
fi

test -s "$CLEANED" && echo "Cleaned file exists and is not empty" || echo "Cleaned file missing or empty"

# === Run Phobius ===
echo "Running: $PHOBIUS $CLEANED > $OUT_DIR/${BASENAME}_phobius.out"
phobius.pl "$CLEANED" > "$OUT_DIR/${BASENAME}_phobius.out"

OUTPUT_FILE="$OUT_DIR/${BASENAME}_phobius.out"

if [[ -s "$OUTPUT_FILE" ]]; then
    rm "$CLEANED"
    echo "Deleted temporary cleaned file: $CLEANED"
else
    echo "WARNING: Output file not found or empty — keeping cleaned file for debugging: $CLEANED"
fi

# === Done ===
echo "=== JOB END ==="
date

