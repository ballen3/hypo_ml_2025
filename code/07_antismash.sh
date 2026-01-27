#!/bin/bash 
#SBATCH --account=arsef
#SBATCH --job-name="antismash_redo_1"
#SBATCH -p ceres
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --cpus-per-task=8
#SBATCH --array=0-918%15
#SBATCH --mem=64G 
#SBATCH -t 24:00:00
#SBATCH --mail-user=bma66@cornell.edu
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH -o /project/arsef/projects/hypo_ml_2025/logs/antismash/%x.%j.%N.o
#SBATCH -e /project/arsef/projects/hypo_ml_2025/logs/antismash/%x.%j.%N.e

echo "=== JOB START ==="
date; hostname; pwd

## Load necessary modules
source /software/el9/apps/miniconda/24.7.1-2/etc/profile.d/conda.sh
conda activate antismash

## Record software versions in output/log
echo "*** Software Versions ***"
echo "Antismash Version: 8.0.2"

ASSEMBLIES="/project/arsef/projects/hypo_ml_2025/data/fna"
ANNOTATIONS="/project/arsef/projects/hypo_ml_2025/data/gff3"
ANTISMASH_OUT="/project/arsef/projects/hypo_ml_2025/output/as_output"

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
GFF="$ANNOTATIONS/${SAMPLE_NAME}.gff3"

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

