#!/bin/bash 
#SBATCH --job-name="interpro_test1"
#SBATCH -p ceres
#SBATCH -N 1
#SBATCH -n 40
#SBATCH -t 01:00:00
#SBATCH --mail-user=bma66@cornell.edu
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH -o /project/arsef/projects/hypo_ml_2025/tests/test_oe/%x.%j.%N.o
#SBATCH -e /project/arsef/projects/hypo_ml_2025/tests/test_oe/%x.%j.%N.e

cd /project/arsef/projects/hypo_ml_2025/tests/

echo "=== JOB START ==="
date
hostname
pwd

module load interproscan/5.74-105.0 
#already initialized 
echo "Interproscan version: 5.74-105.0"
# gives an overview of the families that a protein belongs to and the domains and sites it contains.

INPUT_DIR="/project/arsef/projects/hypo_ml_2025/tests/test_data"
OUTPUT_DIR="/project/arsef/projects/hypo_ml_2025/tests/test_outputs/ips_test_output"
TEMP_DIR="$OUTPUT_DIR/temp"

mkdir -p "$OUTPUT_DIR"
mkdir -p "$TEMP_DIR"

echo "Running Interproscan on: $INPUT_DIR"
echo "Output will be saved to: $OUTPUT_DIR"

for file in "$INPUT_DIR"/*.faa; do
    echo "Processing: "$file""
    BASENAME=$(basename "$file" .faa)
    CLEANED="$TEMP_DIR/${BASENAME}_clean.faa"
    # Remove asterisks 
    sed 's/*//g' "$file" > "$CLEANED"

    interproscan.sh --cpu 40 \
    --input "$CLEANED" \
    --output-dir "$OUTPUT_DIR" \
    --tempdir "$TEMP_DIR" \
    --iprlookup \
    --goterms \
    --disable-precalc \
    --pathways
done

echo "=== JOB END ==="
date