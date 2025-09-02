#!/bin/bash 
#SBATCH --account=arsef
#SBATCH --job-name="dbcan_1"
#SBATCH -p ceres
#SBATCH -N 1
#SBATCH -n 60
#SBATCH --mem=64G 
#SBATCH -t 5-00:00:00
#SBATCH --mail-user=bma66@cornell.edu
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH -o /project/arsef/projects/hypo_ml_2025/logs/%x.%j.%N.o
#SBATCH -e /project/arsef/projects/hypo_ml_2025/logs/%x.%j.%N.e

echo "=== JOB START ==="
date; hostname; pwd

## Load necessary modules
source activate run_dbcan_env

## Record software versions in output/log 
#(!!remember to change this if you change versions!!)
echo "*** Software Versions ***"
echo "dbcan Version: 5.1.2"

# Define directories
WORK_DIR="/project/arsef/projects/hypo_ml_2025/"
INPUT="$WORK_DIR/data/faa"
OUTPUT="$WORK_DIR/output/dbcan_$(date +%Y%m%d_%H%M%S)"
DB_DIR="$WORK_DIR/run_dbcan-master/db"

mkdir -p "$OUTPUT"

# Loop through .faa files
echo "Starting batch processing..."

for faa_file in "$INPUT"/*.faa; do
    if [[ -f "$faa_file" ]]; then
        base_name=$(basename "$faa_file" .faa)
        sample_outdir="$OUTPUT/${base_name}_dbcan"

        echo "Processing: $base_name"
        mkdir -p "$sample_outdir"

        run_dbcan CAZyme_annotation \
            --input_raw_data "$faa_file" \
            --output_dir "$sample_outdir" \
            --db_dir "$DB_DIR" \
            --mode protein

        echo "Finished: $base_name"
        echo "Results saved in: $sample_outdir"
    else
        echo "No .faa files found in: $INPUT"
    fi
done

echo "=== JOB END ==="
date