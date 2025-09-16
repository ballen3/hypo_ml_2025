#!/bin/bash 
#SBATCH --account=arsef
#SBATCH --job-name=repeatmodeler_array_test_6
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

module load repeatmodeler/2.0.5
#module load blast+/2.15.0

echo "=== JOB START ==="
date; hostname; pwd         
echo "Running on SLURM_ARRAY_TASK_ID: $SLURM_ARRAY_TASK_ID"

## Record software versions in output/log 
#(!!remember to change this if you change versions!!)
echo "*** Software Versions ***"
echo "RepeatModeler Version: 2.0.5"   
#echo "blast+ Version: 2.15.0"  

# Set input and output directories
DATA_DIR=/project/arsef/projects/hypo_ml_2025/tests/test_data/test_fna
OUT_DIR=/project/arsef/projects/hypo_ml_2025/tests/test_outputs/rpmodler_test_output
DB_PATH=/project/arsef/projects/hypo_ml_2025/data/databases/repeatmodeler_db

# Make sure output dir exists
mkdir -p "$OUT_DIR"

# Get list of .fna files into an array
FASTA_FILES=($DATA_DIR/*.fna)

# Select the input file based on array index
INPUT="${FASTA_FILES[$SLURM_ARRAY_TASK_ID]}"
BASENAME=$(basename "$INPUT" .fna)
DB_NAME="${BASENAME}_db"

# Check if database exists; if not, create it
if [ ! -f "$OUT_DIR/${DB_NAME}.nhr" ]; then
    echo "Database not found. Creating it now..."
    (cd "$OUT_DIR" && BuildDatabase -name "$DB_NAME" -engine rmblast "$INPUT")

    # Check if creation succeeded
    if [ ! -f "$OUT_DIR/${DB_NAME}.nhr" ]; then
        echo "Database creation failed. Exiting."
        exit 1
    fi
fi

# Run RepeatModeler
RepeatModeler -database "$OUT_DIR/${DB_NAME}" -threads 16 -LTRStruct -dir "$OUT_DIR/${BASENAME}_repeatmodeler_output"


# Example commands to run manually
#BuildDatabase -name BLD.DB -engine rmblast contigs_filter1_nematoda_nohit.fa
#RepeatModeler -database BLD.DB -engine ncbi -threads 16