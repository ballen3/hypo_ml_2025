#!/bin/bash
#SBATCH --account=arsef
#SBATCH --job-name="align_scgs_1"
#SBATCH -p ceres
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --cpus-per-task=4
#SBATCH --mem=1G
#SBATCH -t 1:00:00
#SBATCH --mail-user=bma66@cornell.edu
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH -o /project/arsef/projects/hypo_ml_2025/logs/%x.%j.%N.o
#SBATCH -e /project/arsef/projects/hypo_ml_2025/logs/%x.%j.%N.e

# Input folder with your original alignments
INPUT_DIR="/home/brooke.allen/hypo/tree/brooke1/canopy_995/single_copy_sequences"

# Output folder for trimmed alignments
OUTPUT_DIR="/project/arsef/projects/hypo_ml_2025/tree/alignments"
mkdir -p "$OUTPUT_DIR"

for f in "$INPUT_DIR"/*.faa; do
    BASENAME=$(basename "$f" .faa)
    mafft --auto --thread 4 "$f" > "$OUTPUT_DIR/$BASENAME.aln"
done