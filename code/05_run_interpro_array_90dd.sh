#!/bin/bash 
#SBATCH --account=arsef
#SBATCH --job-name=interpro_array_2
#SBATCH -p ceres
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --cpus-per-task=20
#SBATCH --mem=64G 
#SBATCH -t 5-00:00:00
#SBATCH --mail-user=bma66@cornell.edu
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH -o /project/arsef/projects/hypo_ml_2025/logs/ips_array_logs/%x.%A_%a.%N.o
#SBATCH -e /project/arsef/projects/hypo_ml_2025/logs/ips_array_logs/%x.%A_%a.%N.e
#SBATCH --array=0-918%20  # <-- Adjust this based on number of .faa files minus 1

echo "=== JOB START ==="
date; hostname; pwd

# Load required module
module load interproscan/5.74-105.0 

# Software version log
echo "*** Software Versions ***"
echo "InterProScan version: 5.74-105.0"

# === Define paths ===
WORK_DIR="/project/arsef/projects/hypo_ml_2025"
DATA_DIR="${WORK_DIR}/data/faa"
CLEAN_SCRIPT="${WORK_DIR}/code/04_ips_faa_clean.sh"
INTERPRO_SCRIPT="${WORK_DIR}/code/03_interpro_array.sh"
LOG_DIR="${WORK_DIR}/logs/ips_array_logs"
IPS_CPUS=20

# Make scripts executable
chmod +x "$INTERPRO_SCRIPT" "$CLEAN_SCRIPT"

# Get list of .faa input files
FASTA_FILES=($DATA_DIR/*.faa)
INPUT="${FASTA_FILES[$SLURM_ARRAY_TASK_ID]}"

if [[ -z "$INPUT" || ! -f "$INPUT" ]]; then
    echo "No valid input file found for SLURM_ARRAY_TASK_ID=$SLURM_ARRAY_TASK_ID"
    exit 1
fi

BASENAME=$(basename "$INPUT" .faa)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# === Create scratch workspace ===
SCRATCH_DIR="/90daydata/arsef/ips_${BASENAME}_${TIMESTAMP}"
SCRATCH_TEMP="${SCRATCH_DIR}/temp"
SCRATCH_OUTPUT="${SCRATCH_DIR}/output"

mkdir -p "$SCRATCH_TEMP" "$SCRATCH_OUTPUT"

# Copy .faa input to scratch dir
cp "$INPUT" "${SCRATCH_DIR}/${BASENAME}.faa"
cd "$SCRATCH_DIR" || { echo "Failed to cd into scratch dir"; exit 1; }

# Run processing script from within scratch
"$INTERPRO_SCRIPT" "${SCRATCH_DIR}/${BASENAME}.faa" "$CLEAN_SCRIPT" "$SCRATCH_TEMP" "$SCRATCH_OUTPUT" "$IPS_CPUS" "$LOG_DIR"

# Move final output back to project directory
DEST_TSV="${WORK_DIR}/output/ips_output/${BASENAME}.tsv"
OUT_TSV="${SCRATCH_OUTPUT}/${BASENAME}_clean.tsv"

if [[ -f "$OUT_TSV" ]]; then
    cp "$OUT_TSV" "$DEST_TSV"
    echo "Output copied to $DEST_TSV"
else
    echo "ERROR: Expected output TSV not found at $OUT_TSV"
    exit 2
fi

# Clean up scratch dir
#rm -rf "$SCRATCH_DIR"
#echo "Cleaned up $SCRATCH_DIR"

echo "=== JOB COMPLETE ==="
date
