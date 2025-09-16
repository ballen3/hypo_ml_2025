#!/bin/bash
#SBATCH --account=arsef
#SBATCH --job-name="bigscape_90dd_3"
#SBATCH -p ceres
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G 
#SBATCH -t 24:00:00
#SBATCH --mail-user=bma66@cornell.edu
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH -o /project/arsef/projects/hypo_ml_2025/logs/%x.%j.%N.o
#SBATCH -e /project/arsef/projects/hypo_ml_2025/logs/%x.%j.%N.e


echo "=== JOB START ==="
date; hostname; pwd

# Load Conda environment
source /software/el9/apps/miniconda/24.7.1-2/etc/profile.d/conda.sh
conda activate bigscape

echo "*** Software Versions ***"
echo "BiG-SCAPE Version: 2.0.0-beta.8"

# Paths
BIGSCAPE_DIR="/project/arsef/projects/hypo_ml_2025/programs/BiG-SCAPE"
PFAM_DB="/project/arsef/projects/hypo_ml_2025/data/databases/Pfam-A.hmm"
SOURCE_DIR="/project/arsef/projects/hypo_ml_2025/output/as_output"

# Temporary directories
RUN_ID=$(date +%Y%m%d_%H%M%S)
RUNDIR="/90daydata/arsef/bigscape_${RUN_ID}"
INPUT_FLAT="$RUNDIR/input_flat"
OUTPUT_DIR="$RUNDIR/output"

mkdir -p "$INPUT_FLAT"
mkdir -p "$OUTPUT_DIR"

echo "Syncing .region*.gbk files into: $INPUT_FLAT (skipping existing files)"
# Find all .region*.gbk files and copy only them into a flat directory
find "$SOURCE_DIR" -type f -name "*.region*.gbk" -exec rsync -av --ignore-existing {} "$INPUT_FLAT/" \;

echo "Total .gbk files copied:"
ls "$INPUT_FLAT"/*.gbk | wc -l

# Run BiG-SCAPE
cd "$BIGSCAPE_DIR"

echo "[$(date)] Starting BiG-SCAPE"
echo "Input directory: $INPUT_FLAT"
echo "Output directory: $OUTPUT_DIR"

python bigscape.py \
  cluster \
  --input-dir "$INPUT_FLAT" \
  --output-dir "$OUTPUT_DIR" \
  -p "$PFAM_DB" \
  --include-singletons \

echo "[$(date)] BiG-SCAPE run complete"


