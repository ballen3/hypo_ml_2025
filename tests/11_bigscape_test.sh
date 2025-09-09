#!/bin/bash
#SBATCH --account=arsef
#SBATCH --job-name="bigscape_test_3"
#SBATCH -p ceres
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G 
#SBATCH -t 24:00:00
#SBATCH --mail-user=bma66@cornell.edu
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH -o /project/arsef/projects/hypo_ml_2025/tests/test_oe/%x.%j.%N.o
#SBATCH -e /project/arsef/projects/hypo_ml_2025/tests/test_oe/%x.%j.%N.e

set -euo pipefail

echo "=== JOB START ==="
date; hostname; pwd

## Load necessary modules
source /software/el9/apps/miniconda/24.7.1-2/etc/profile.d/conda.sh
conda activate bigscape

echo "*** Software Versions ***"
echo "BigScape Version: 2.0.0-beta.8"

# Input is the folder with symlinks to all .region*.gbk files
BIGSCAPE_DIR="/project/arsef/projects/hypo_ml_2025/programs/BiG-SCAPE"
INPUT_DIR="/project/arsef/projects/hypo_ml_2025/tests/test_outputs/as_test_output/test_gbks"
OUTPUT_DIR="/project/arsef/projects/hypo_ml_2025/tests/test_outputs/bs_test_output"
PFAM_DB="/project/arsef/projects/hypo_ml_2025/data/databases/Pfam-A.hmm"

mkdir -p "$OUTPUT_DIR"

cd "$BIGSCAPE_DIR"

echo "[$(date)] Running BigScape on all genomes"
echo "Input dir: $INPUT_DIR"
echo "Output dir: $OUTPUT_DIR"

python bigscape.py \
  cluster \
  --input-dir "$INPUT_DIR" \
  --output-dir "$OUTPUT_DIR" \
  -p "$PFAM_DB" \
  --include-singletons 

echo "[$(date)] BigScape run finished"

