#!/bin/bash 
#SBATCH --account=arsef
#SBATCH --job-name=merops_array_3
#SBATCH -p ceres
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --cpus-per-task=8
#SBATCH --array=0-334%20 
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


# -------------------------------
# MEROPS BLAST database notes:
# -------------------------------
# - The database is built from pepunit.lib, a MEROPS peptide-unit FASTA.
# - Some headers contain non-ASCII characters (e.g., en-dash 0x96).
#   BLAST prints a warning but still adds the sequence to the DB.
# - The database files (merops_pepunit_db.*) are complete and usable.
# - To avoid warnings, you can replace non-ASCII chars in headers:
#     perl -pe 's/\x96/-/' pepunit.lib > pepunit_fixed.lib
#     makeblastdb -in pepunit_fixed.lib -dbtype prot -out merops_pepunit_db_clean
# - BLAST expects the -db argument to point to the database **prefix**, not a specific file.
# -------------------------------

# Set input and output directories
DATA_DIR=/home/brooke.allen/hypo/data/full_db_addl_files/db_addl_faa
DB_PATH=/project/arsef/projects/hypo_ml_2025/data/databases/merops_pepunit_db/merops_pepunit_db_clean
# Remember to also change the array size above as needed if you change input files!

# Timestamp-based run ID
RUN_ID=$(date +%Y%m%d_%H%M%S)_${SLURM_ARRAY_TASK_ID}
RUNDIR="/90daydata/arsef/db_addl_merops/${RUN_ID}"
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
  -qcov_hsp_perc 50 \
  -max_target_seqs 5 \
  -num_threads 8

