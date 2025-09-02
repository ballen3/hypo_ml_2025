#!/bin/bash 
#SBATCH --account=arsef
#SBATCH --job-name="orthofinder_3_long"
#SBATCH --qos=long
#SBATCH -p ceres
#SBATCH -N 1
#SBATCH -n 128
#SBATCH --mem=1800G 
#SBATCH -t 60-00:00:00
#SBATCH --mail-user=bma66@cornell.edu
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH -o /project/arsef/projects/hypo_ml_2025/logs/%x.%j.%N.o
#SBATCH -e /project/arsef/projects/hypo_ml_2025/logs/%x.%j.%N.e

cd /project/arsef/projects/hypo_ml_2025/

echo "=== JOB START ==="
date
hostname
pwd

module load orthofinder/3.0.1b1
echo "OrthoFinder version: 3.0.1b1"

INPUT_DIR="/project/arsef/projects/hypo_ml_2025/data/faa"
OUTPUT_DIR="/project/arsef/projects/hypo_ml_2025/output/$(date +%Y%m%d_%H%M%S)"

echo "Running OrthoFinder on: $INPUT_DIR"
echo "Output will be saved to: $OUTPUT_DIR"

orthofinder -f "$INPUT_DIR" -o "$OUTPUT_DIR" -t 128 -a 128

echo "=== JOB END ==="
date
