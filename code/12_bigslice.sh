#!/bin/bash 
#SBATCH --account=arsef
#SBATCH --job-name="bigslice_full_test_17"
#SBATCH -p ceres
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --cpus-per-task=16
#SBATCH --mem=128G
#SBATCH -t 72:00:00
#SBATCH --mail-user=bma66@cornell.edu
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH -o /home/brooke.allen/hypo/logs/bigslice/%x.%j.%N.o
#SBATCH -e /home/brooke.allen/hypo/logs/bigslice/%x.%j.%N.e

echo "=== JOB START ==="
date; hostname; pwd

## Load necessary modules
source /software/el9/apps/miniconda/24.7.1-2/etc/profile.d/conda.sh
conda activate ~/hypo/programs/bigslice_hpc/

## Record software versions in output/log
echo "*** Software Versions ***"
echo "=== ENV CHECK ==="
which python
python -c "import pyhmmer; print('pyhmmer', pyhmmer.__version__)"
which bigslice
bigslice --version
python -c "import sys; print(sys.executable)"
echo "TMPDIR=$TMPDIR"

# Paths for permanent storage
permanent_input="/project/arsef/projects/hypo_ml_2025/output/bigslice_input"
permanent_output="/project/arsef/projects/hypo_ml_2025/output/bigslice_output_5"

# Use local scratch on compute node
scratch_input="$TMPDIR/bigslice_input"
scratch_output="$TMPDIR/bigslice_output"

# Copy input to local scratch
echo "Copying input to local scratch..."
cp -r "$permanent_input" "$scratch_input"

# Pfam database
export BIGSLICEDB_HMM="/home/brooke.allen/hypo/data/databases/Pfam-A.hmm"
if [ ! -f "$BIGSLICEDB_HMM" ]; then
    echo "ERROR: Pfam HMM database not found at $BIGSLICEDB_HMM"
    exit 1
fi
echo "Pfam HMM database found at $BIGSLICEDB_HMM"

# Run BigSlice on local scratch
echo "Running BigSlice..."
bigslice cluster -i "$scratch_input" "$scratch_output" \
    --threshold 0.25 \
    -t 16

# Copy results back to permanent storage
echo "Copying results back to permanent storage..."
cp -r "$scratch_output" "$permanent_output"

echo "=== JOB END ==="
date
 