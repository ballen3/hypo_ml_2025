#!/bin/bash 
#SBATCH --account=arsef
#SBATCH --job-name="antismash_test_8"
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

echo "=== JOB START ==="
date; hostname; pwd

## Load necessary modules
source /software/el9/apps/miniconda/24.7.1-2/etc/profile.d/conda.sh
conda activate antismash

## Record software versions in output/log 
#(!!remember to change this if you change versions!!)
echo "*** Software Versions ***"
echo "Antismash Version: 8.0.2"

ASSEMBLIES="/project/arsef/projects/hypo_ml_2025/tests/test_data/test_fna"
ANNOTATIONS="/project/arsef/projects/hypo_ml_2025/tests/test_data/test_gff"
ANTISMASH_OUT="/project/arsef/projects/hypo_ml_2025/tests/test_outputs/as_test_output"

mkdir -p logs
mkdir -p "$ANTISMASH_OUT"

# Get array of fasta files 
FASTA_FILES=($ASSEMBLIES/*.fna)

# Select the fasta for this task
FASTA="${FASTA_FILES[$SLURM_ARRAY_TASK_ID]}"

# Extract sample name like your basename call
SAMPLE_NAME=$(basename "$FASTA" ".fna")

# Define output dir & GFF path
OUTDIR="$ANTISMASH_OUT/$SAMPLE_NAME"
GFF="$ANNOTATIONS/${SAMPLE_NAME}.gff3"

# Skip if output exists
if [ -d "$OUTDIR" ]; then
  echo "[$(date)] Skipping $SAMPLE_NAME, output already exists."
  exit 0
fi

if [ ! -f "$GFF" ]; then
    echo "[$(date)] ERROR: Annotation GFF file $GFF not found. Exiting."
    exit 1
fi

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
