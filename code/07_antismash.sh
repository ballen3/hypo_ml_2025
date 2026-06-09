#!/bin/bash 
#SBATCH --account=arsef
#SBATCH --job-name="antismash_array"
#SBATCH -p ceres
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --cpus-per-task=8
#SBATCH --array=0-334
#SBATCH --mem=64G 
#SBATCH -t 24:00:00
#SBATCH --mail-user=bma66@cornell.edu
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH -o /project/arsef/projects/hypo_ml_2025/logs/antismash/%x.%j.%N.o
#SBATCH -e /project/arsef/projects/hypo_ml_2025/logs/antismash/%x.%j.%N.e

# Change array. Should be n files - 1. If you have 100 files, array should be 0-99. 
# Run as: sbatch 07_antismash.sh /path/fna /path/gff /path/out

echo "=== JOB START ==="
date; hostname; pwd

## Load necessary modules
source /software/el9/apps/miniconda/24.7.1-2/etc/profile.d/conda.sh
conda activate antismash

## Record software versions in output/log
echo "*** Software Versions ***"
antismash --version

# Hardcoded paths (for testing, or if you don't want to pass as args)
#ASSEMBLIES="/home/brooke.allen/hypo/data/full_db_addl_files/db_addl_fna"
#ANNOTATIONS="/home/brooke.allen/hypo/data/full_db_addl_files/db_addl_gff3"
#ANTISMASH_OUT="/project/arsef/projects/hypo_ml_2025/output/as_output/as_output_addl"

# command line args
ASSEMBLIES=${1:-} #path to fna (input)
ANNOTATIONS=${2:-} #path to gff3 (input)
ANTISMASH_OUT=${3:-} #path to output directory for antismash results

if [ -z "$ASSEMBLIES" ] || [ -z "$ANNOTATIONS" ] || [ -z "$ANTISMASH_OUT" ]; then
  echo "Usage: sbatch 07_antismash.sh <assemblies> <annotations> <outdir>"
  exit 1
fi

mkdir -p "$ANTISMASH_OUT"

# Collect FASTA files
FASTA_FILES=($ASSEMBLIES/*.fna)

# Select FASTA for this array task
FASTA="${FASTA_FILES[$SLURM_ARRAY_TASK_ID]}"

# Bounds check (protect against oversized arrays)
if [ -z "$FASTA" ]; then
  echo "[$(date)] No FASTA for task $SLURM_ARRAY_TASK_ID, exiting."
  exit 0
fi

# Sample name
SAMPLE_NAME=$(basename "$FASTA" ".fna")

# Output directory and GFF path
OUTDIR="$ANTISMASH_OUT/$SAMPLE_NAME"
GFF="$ANNOTATIONS/${SAMPLE_NAME}.gff3" # Adjusted to match fixed GFF naming

# GFF existence check
if [ ! -f "$GFF" ]; then
  echo "[$(date)] ERROR: Annotation GFF file $GFF not found."
  exit 1
fi

echo "[$(date)] SLURM_ARRAY_TASK_ID=$SLURM_ARRAY_TASK_ID"
echo "[$(date)] FASTA=$FASTA"
echo "[$(date)] Starting antiSMASH for $SAMPLE_NAME"

antismash "$FASTA" \
  --taxon fungi \
  --output-dir "$OUTDIR" \
  --output-basename "$SAMPLE_NAME" \
  --cb-general --cb-knownclusters --cb-subclusters \
  --asf --pfam2go --clusterhmmer --cassis --cc-mibig --tfbs \
  --genefinding-gff3 "$GFF" \
  --cpus "$SLURM_CPUS_PER_TASK"

echo "[$(date)] Finished antiSMASH for $SAMPLE_NAME"

