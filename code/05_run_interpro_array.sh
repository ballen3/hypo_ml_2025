#!/bin/bash 
#SBATCH --account=arsef
#SBATCH --job-name=interpro_array_1
#SBATCH -p ceres
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --cpus-per-task=20
#SBATCH --mem=64G 
#SBATCH -t 5-00:00:00
#SBATCH --mail-user=bma66@cornell.edu
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH -o /project/arsef/projects/hypo_ml_2025/logs/ips_array_logs/%x.%A_%a.%N.o
#SBATCH -e /project/arsef/projects/hypo_ml_2025/logs/ips_array_logs/%x.%A_%a.%N.e
#SBATCH --array=0-918%20  # <-- Adjust this based on number of .faa files minus 1

# ~~ Usage ~~ #
# sbatch --array=0-<N> 05_run_interproscan_array.sh
# where <N> = number of input files - 1

echo "=== JOB START ==="
date; hostname; pwd

## Load necessary modules
module load interproscan/5.74-105.0 

## Record software versions in output/log 
echo "*** Software Versions ***"
echo "Interproscan version: 5.74-105.0"

# Set paths
WORK_DIR="/project/arsef/projects/hypo_ml_2025"
CLEAN_SCRIPT="${WORK_DIR}/code/04_ips_faa_clean.sh"
INTERPRO_SCRIPT="${WORK_DIR}/code/03_interpro_array.sh"
TEMP_DIR="${WORK_DIR}/output/ips_output/temp"
DATA_DIR="${WORK_DIR}/data/faa" 
OUTPUT_DIR="${WORK_DIR}/output/ips_output"
LOG_DIR="${WORK_DIR}/logs/ips_array_logs"
IPS_CPUS=20

chmod +x "$INTERPRO_SCRIPT" "$CLEAN_SCRIPT"

# Create directories if needed
mkdir -p "$TEMP_DIR" "$OUTPUT_DIR" "$LOG_DIR"

# Get array of .faa files
FASTA_FILES=($DATA_DIR/*.faa)

# Select file based on SLURM_ARRAY_TASK_ID
INPUT="${FASTA_FILES[$SLURM_ARRAY_TASK_ID]}"

if [[ -z "$INPUT" || ! -f "$INPUT" ]]; then
    echo "No valid input file found for SLURM_ARRAY_TASK_ID=$SLURM_ARRAY_TASK_ID"
    exit 1
fi

# Run interproscan script
"$INTERPRO_SCRIPT" "$INPUT" "$CLEAN_SCRIPT" "$TEMP_DIR" "$OUTPUT_DIR" "$IPS_CPUS" "$LOG_DIR"

echo "=== JOB COMPLETE ==="
date

