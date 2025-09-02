#!/bin/bash 
#SBATCH --account=arsef
#SBATCH --job-name="edta_test1"
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

source activate EDTA
echo "EDTA Version: "
# whole-genome de-novo TE annotation

#input = The genome file [FASTA].
INPUT_DIR="/project/arsef/projects/hypo_ml_2025/tests/test_data" 
OUTPUT_DIR="/project/arsef/projects/hypo_ml_2025/tests/edta_test_output"




done

echo "=== JOB END ==="
date
