#!/bin/bash 
#SBATCH --account=arsef
#SBATCH --job-name=repeatmasker_array_90dd_1
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

################################################################################
# RepeatMasker SLURM Array Job Script
#
# Purpose:
#   Runs RepeatMasker on a set of genome (.fna) files using
#   a RepeatModeler-generated library. Designed for array jobs
#   so each task processes one genome.
#
# Usage:
#   1. Place your input genomes in a directory (default: FNA_DIR).
#   2. Make sure the RepeatModeler libraries exist for each genome.
#   3. Submit the script as an array job:
#        sbatch --array=0-N script_name.sh
#      where N = number of genomes - 1.
#
# Requirements:
#   - RepeatMasker module installed and available on the system.
#   - RepeatModeler-generated library for each genome.
#
# Variables you can modify:
#   FNA_DIR   : Directory containing input genome .fna files.
#   RUNDIR    : Base directory for task-specific run folders.
#   RM_LIB    : Path to the RepeatModeler library for each genome.
################################################################################


# Load modules
module load repeatmasker/4.1.5  

echo "=== JOB START ==="
date; hostname; pwd         
echo "Running on SLURM_ARRAY_TASK_ID: $SLURM_ARRAY_TASK_ID"

# Software version logging
echo "*** Software Versions ***"
RepeatMasker -v

# Set permanent data dir (where input .fna files are)
FNA_DIR="/project/arsef/projects/hypo_ml_2025/data/fna/"
# Load list of input files
FNA_FILES=("$FNA_DIR"/*.fna)

# Check for out-of-bounds array index
if [ "$SLURM_ARRAY_TASK_ID" -ge "${#FNA_FILES[@]}" ]; then
    echo "Error: SLURM_ARRAY_TASK_ID=$SLURM_ARRAY_TASK_ID exceeds available input files (${#FNA_FILES[@]})."
    exit 1
fi

# Define input genome based on array index
ARRAY_GENOME="${FNA_FILES[$SLURM_ARRAY_TASK_ID]}"
BASENAME=$(basename "$ARRAY_GENOME" .fna)

# Timestamp-based run ID 
RUN_ID=${BASENAME}_$(date +%Y%m%d_%H%M%S)_${SLURM_ARRAY_TASK_ID}

# Define 90-day directories
RUNDIR="/90daydata/arsef/rpmasker/${RUN_ID}"
INPUT_DIR="${RUNDIR}/input"
OUTPUT_DIR="${RUNDIR}/output"
# Set RepeatModeler library path
RM_LIB="/home/brooke.allen/hypo/output/rpmodeler/${BASENAME}/${BASENAME}_consensi.fa.classified"

# Create necessary directories
mkdir -p "$INPUT_DIR" "$OUTPUT_DIR"

# Copy input to 90-day input dir 
#you can skip this and run directly from permanent storage if preferred (faster & less space but less reproducible)
# If you dont copy, change the RepeatMasker command accordingly to $ARRAY_GENOME. 
# Could also symlink instead of copy if space is an issue, but can break if original is deleted or moved.
# NOTE: Makes $INPUT_DIR obsolete if you dont copy
cp "$ARRAY_GENOME" "${INPUT_DIR}/${BASENAME}.fna"

# Move into the output dir for this task 
cd "$OUTPUT_DIR" || { echo "Failed to cd into output dir: $OUTPUT_DIR"; exit 1; }
 
# Check if the RepeatModeler library exists before running RepeatMasker
if [ -f "$RM_LIB" ]; then
    echo "[$(date)] Running RepeatMasker on $BASENAME using RepeatModeler library..."
    echo "Input genome: $ARRAY_GENOME"
    echo "Output directory: $OUTPUT_DIR"
    echo "RepeatModeler library: $RM_LIB"
# Run RepeatMasker using RepeatModeler library
# NOTE: Without -engine rmblast you get an hmmer error because the library is fasta
    RepeatMasker \
        -pa 4 \
        -gff \
        -engine rmblast \
        -lib "$RM_LIB" \
        -dir "$OUTPUT_DIR" \
        "$INPUT_DIR/${BASENAME}.fna" || { echo "RepeatMasker failed for $BASENAME"; exit 1; }

    echo "[$(date)] RepeatMasker finished for $BASENAME"
else
    echo "RepeatModeler library not found: $RM_LIB"
    echo "Skipping RepeatMasker."
fi

echo "=== JOB END ==="
date
