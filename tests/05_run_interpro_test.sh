#!/bin/bash 
#SBATCH --job-name="run_interpro_test"
#SBATCH -p ceres
#SBATCH -N 1
#SBATCH -n 40
#SBATCH -t 4:00:00
#SBATCH --mail-user=bma66@cornell.edu
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH -o /project/arsef/projects/hypo_ml_2025/tests/test_oe/%x.%j.%N.o
#SBATCH -e /project/arsef/projects/hypo_ml_2025/tests/test_oe/%x.%j.%N.e

# ~~ Usage ~~
# sbatch 02_run_interproscan_test.sh [num_parallel_jobs]
# If no value is given, defaults to 2 parallel jobs

# Interproscan gives an overview of the families that a protein belongs to \
    # and the domains and sites it contains.

echo "=== JOB START ==="
date; hostname; pwd

## Load necessary modules
module load interproscan/5.74-105.0 
module load parallel/20230222

# record software versions in output/log 
#(!!remember to change this if you change versions!!)
echo "== Software Versions =="
echo "Interproscan version: 5.74-105.0"
echo "Parallel version: 20230222"
# NOTE: Interproscan on Scinet has already been initialized, that step is not included here
# If you are not working on Scinet you may need to do that step first (only needs to be done once after install)

WORK_DIR="/project/arsef/projects/hypo_ml_2025/tests/"
CLEAN_SCRIPT="/project/arsef/projects/hypo_ml_2025/tests/04_ips_faa_clean.sh"
INTERPRO_SCRIPT="/project/arsef/projects/hypo_ml_2025/tests/03_interpro_test.sh"
IPS_CPUS=4
TEMP_DIR="/project/arsef/projects/hypo_ml_2025/tests/test_outputs/ips_test_output/temp"
DATA_DIR="/project/arsef/projects/hypo_ml_2025/tests/test_data/"
OUTPUT_DIR="/project/arsef/projects/hypo_ml_2025/tests/test_outputs/ips_test_output"
NUM_JOBS="${1:-2}" # input the number of parallel jobs you want when you sbatch or it defaults to 2

# move into the directory you want the scripts to work from
cd "$WORK_DIR"
# makes these dirs if they don't already exist 
mkdir -p "$OUTPUT_DIR" "$TEMP_DIR"


# Make sure called scripts are executable
chmod +x "$CLEAN_SCRIPT" "$INTERPRO_SCRIPT" || {
    echo "Failed to make scripts executable. Check permissions." >&2
    exit 1
}


# Find .faa files that do not have corresponding .tsv outputs yet
find "$DATA_DIR" -name "*.faa" | sort | uniq | while read -r faa_file; do
    base=$(basename "$faa_file" .faa)
    expected_output="${OUTPUT_DIR}/${base}.tsv"

    if [[ ! -f "$expected_output" ]]; then
        echo "$faa_file"
    fi
done > files_to_run.txt

# checks status of the list of input files
if [[ ! -s files_to_run.txt ]]; then
    echo "files_to_run.txt is empty or missing"
    exit 0
else
    echo "== Updated files_to_run.txt =="
fi

# Line dividing job info and interpro run for output/log readability 
echo "================================"

# disables the /dev/tty prompt/
export PARALLEL_DISABLE=1

# run interproscan in parallel
parallel --jobs "$NUM_JOBS" --dry-run --verbose --halt soon,fail=1 \
  "$INTERPRO_SCRIPT" {} "$CLEAN_SCRIPT" "$TEMP_DIR" "$OUTPUT_DIR" "$IPS_CPUS" \
  :::: files_to_run.txt

# checks status of the parallel interpro run
if [[ $? -eq 0 ]]; then
    echo "Interpro parallel job finished successfully."
else
    echo "Interpro parallel job failed with error code $?" >&2
fi

echo "=== JOB COMPLETE ==="
date