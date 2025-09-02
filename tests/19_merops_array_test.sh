#!/bin/bash 
#SBATCH --account=arsef
#SBATCH --job-name=merops_blast_array_test_2
#SBATCH -p ceres
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --cpus-per-task=8
#SBATCH --array=0-3
#SBATCH --mem=8G
#SBATCH -t 24:00:00
#SBATCH --mail-user=bma66@cornell.edu
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH -o /project/arsef/projects/hypo_ml_2025/tests/test_oe/%x.%j.%N.o
#SBATCH -e /project/arsef/projects/hypo_ml_2025/tests/test_oe/%x.%j.%N.e

module load blast+  # or source your environment

# Set input and output directories
DATA_DIR=/project/arsef/projects/hypo_ml_2025/tests/test_data/test_faa
OUT_DIR=/project/arsef/projects/hypo_ml_2025/tests/test_outputs/merops_test_output
DB_PATH=/project/arsef/projects/hypo_ml_2025/data/databases/merops_pepunit_db/merops_pepunit_db

# Make sure output dir exists
mkdir -p "$OUT_DIR"

# Get list of .faa files into an array
FASTA_FILES=($DATA_DIR/*.faa)

# Select the input file based on array index
INPUT="${FASTA_FILES[$SLURM_ARRAY_TASK_ID]}"
BASENAME=$(basename "$INPUT" .faa)

# Run BLAST
blastp \
  -query "$INPUT" \
  -db "$DB_PATH" \
  -out "$OUT_DIR/${BASENAME}_vs_merops.tsv" \
  -evalue 1e-5 \
  -outfmt 6 \
  -max_target_seqs 1 \
  -num_threads 4

