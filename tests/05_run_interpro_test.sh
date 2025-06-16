#!/bin/bash 
#SBATCH --job-name="run_interpro_test"
#SBATCH -p ceres
#SBATCH -N 1
#SBATCH -n 32
#SBATCH --mem=64G 
#SBATCH -t 24:00:00
#SBATCH --mail-user=bma66@cornell.edu
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH -o /project/arsef/projects/hypo_ml_2025/tests/test_oe/%x.%j.%N.o
#SBATCH -e /project/arsef/projects/hypo_ml_2025/tests/test_oe/%x.%j.%N.e

# ~~ Usage ~~ #
# sbatch 02_run_interproscan_test.sh [num_parallel_jobs]
# If no value is given, defaults to 2 parallel jobs

# Interproscan gives an overview of the families that a protein belongs to \
    # and the domains and sites it contains.

echo "=== JOB START ==="
date; hostname; pwd

## Load necessary modules
module load interproscan/5.74-105.0 
module load parallel/20230222

## Record software versions in output/log 
#(!!remember to change this if you change versions!!)
echo "*** Software Versions ***"
echo "Interproscan version: 5.74-105.0"
echo "Parallel version: 20230222"
# NOTE: Interproscan on Scinet has already been initialized, that step is not included here
# If you are not working on Scinet you may need to do that step first (only needs to be done once after install)

WORK_DIR="/project/arsef/projects/hypo_ml_2025/tests/" # Base working directory for this pipeline
CLEAN_SCRIPT="/project/arsef/projects/hypo_ml_2025/tests/04_ips_faa_clean.sh" # Path to the script that cleans input .faa files
INTERPRO_SCRIPT="/project/arsef/projects/hypo_ml_2025/tests/03_interpro_test.sh" # Path to the script that runs InterProScan
TEMP_DIR="/project/arsef/projects/hypo_ml_2025/tests/test_outputs/ips_test_output/temp" # Temporary directory for intermediate cleaned files
DATA_DIR="/project/arsef/projects/hypo_ml_2025/tests/test_data/" # Directory containing original .faa input files
OUTPUT_DIR="/project/arsef/projects/hypo_ml_2025/tests/test_outputs/ips_test_output" # Directory to store final InterProScan outputs and logs
LOG_DIR="/project/arsef/projects/hypo_ml_2025/tests/test_oe" # Directory containing stderr and stout files
IPS_CPUS=20  # Number of CPUs to allocate for each InterProScan job
NUM_JOBS="${1:-2}" # Number of parallel jobs to run; can be passed as an argument (defaults to 2)
LOG_DIR="/project/arsef/projects/hypo_ml_2025/tests/test_outputs/test_oe"

## Move into the directory you want the scripts to work from
cd "$WORK_DIR"
## Makes these dirs if they don't already exist 
mkdir -p "$OUTPUT_DIR" "$TEMP_DIR" "$LOG_DIR"


## Make sure called scripts are executable
chmod +x "$CLEAN_SCRIPT" "$INTERPRO_SCRIPT" || {
    echo "Failed to make scripts executable. Check permissions." >&2
    exit 1
}


### Building tracking files
## Create the files so they exist to search in the first check
touch "$OUTPUT_DIR/completed_files.txt"
touch "$OUTPUT_DIR/in_progress.txt"

## Populate completed_files.txt based on existing .tsv outputs
find "$DATA_DIR" -name "*.faa" | sort | uniq | while read -r faa_file; do
    BASENAME=$(basename "$faa_file" .faa)
    EXPECTED_TSV="${OUTPUT_DIR}/${BASENAME}_clean.tsv"

    # If output .tsv exists and is non-empty, count it as complete
    if [[ -s "$EXPECTED_TSV" ]]; then
        if ! grep -Fxq "$faa_file" "$OUTPUT_DIR/completed_files.txt"; then
            echo "$faa_file" >> "$OUTPUT_DIR/completed_files.txt"
        fi
    fi
done

## Remove blank lines from tracking files (defensive cleanup)
sed -i '/^$/d' "$OUTPUT_DIR/completed_files.txt" 2>/dev/null || true
sed -i '/^$/d' "$OUTPUT_DIR/in_progress.txt" 2>/dev/null || true

## Populate files_to_run
find "$DATA_DIR" -name "*.faa" | sort | uniq | while read -r faa_file; do
    BASENAME=$(basename "$faa_file" .faa)
    EXPECTED_TSV="${OUTPUT_DIR}/${BASENAME}_clean.tsv"

    # Check if already in completed_files.txt OR tsv exists (meaning completed)
    if grep -Fxq "$faa_file" "$OUTPUT_DIR/completed_files.txt" || [[ -s "$EXPECTED_TSV" ]]; then
        continue
    elif grep -Fxq "$faa_file" "$OUTPUT_DIR/in_progress.txt"; then
        continue
    else
        echo "$faa_file"
    fi
done > files_to_run.txt

## Checks that the list of input files exists and is not empty
if [[ ! -s files_to_run.txt ]]; then
    echo "files_to_run.txt is empty or missing"
    exit 0
else
    echo "====> Updated files_to_run.txt <===="
fi
###

# Line dividing job info and interpro run for output/log readability 
echo "================================"


# disables the /dev/tty prompt/
export PARALLEL_DISABLE=1


# run interproscan in parallel
# You can use --dry-run flag to make sure all inputs are correct before spending time to run it in full. 
parallel --jobs "$NUM_JOBS" --verbose \
  "$INTERPRO_SCRIPT" '{}' "$CLEAN_SCRIPT" "$TEMP_DIR" "$OUTPUT_DIR" "$IPS_CPUS" "$LOG_DIR" \
  :::: files_to_run.txt

# checks status of the parallel interpro run
if [[ $? -eq 0 ]]; then
    echo "====> Interproscan parallel job finished successfully. <===="
else
    echo "====> Interproscan parallel job failed with error code $? <====" >&2
fi

echo "=== JOB COMPLETE ==="
date