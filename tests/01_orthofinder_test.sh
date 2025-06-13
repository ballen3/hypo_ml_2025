#!/bin/bash 
#SBATCH --job-name="orthofinder_test1"
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

module load orthofinder/3.0.1b1
echo "OrthoFinder version: 3.0.1b1"

INPUT_DIR="/project/arsef/projects/hypo_ml_2025/tests/test_data"
OUTPUT_DIR="/project/arsef/projects/hypo_ml_2025/tests/test_outputs/of_test_output"

echo "Running OrthoFinder on: $INPUT_DIR"
echo "Output will be saved to: $OUTPUT_DIR"

orthofinder -f "$INPUT_DIR" -o "$OUTPUT_DIR"

echo "=== JOB END ==="
date
