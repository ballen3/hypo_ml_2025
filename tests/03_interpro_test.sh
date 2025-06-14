#!/bin/bash
set -x  # Print commands as they execute

INPUT="$1"         # .faa file to process
CLEAN_SCRIPT="$2"  # The cleaning script path
TEMP_DIR="$3"      # Temporary cleaned .faa data directory
OUTPUT_DIR="$4"    # Where results should go
IPS_CPUS="${5:-4}" # Number of CPUs for interproscan, default to 4 if not set

# Redirect stderr to a debug log (create one log per input file)
LOG_BASE=$(basename "$1" .faa)
exec 2>> "/project/arsef/projects/hypo_ml_2025/tests/test_oe/${LOG_BASE}_debug.log"

# Check required arguments
if [[ -z "$INPUT" || -z "$CLEAN_SCRIPT" || -z "$TEMP_DIR" || -z "$OUTPUT_DIR" ]]; then
    echo "Usage: $0 <input_file> <clean_script> <temp_dir> <output_dir> [ips_cpus]" >&2
    echo "       ips_cpus defaults to 4 if not provided" >&2
    exit 1
fi

BASENAME=$(basename "$INPUT" .faa)
echo "[$(date)] Starting $BASENAME on $(hostname)"

if [[ ! -x "$CLEAN_SCRIPT" ]]; then
    echo "Cleaning script $CLEAN_SCRIPT is not executable." >&2
    exit 2
fi

# run script to remove * from .faa input files
CLEANED=$("$CLEAN_SCRIPT" "$INPUT" "$TEMP_DIR") || { echo "Cleaning failed"; exit 2; }

if [[ ! -f "$CLEANED" ]]; then
    echo "Cleaning Error: file at $CLEANED not found." >&2
    exit 2
fi

echo "Starting Interproscan on: $INPUT"
echo "Output will be saved to: $OUTPUT_DIR"
# run interproscan
interproscan.sh --cpu "$IPS_CPUS" \
--input "$CLEANED" \
--output-dir "$OUTPUT_DIR" \
--tempdir "$TEMP_DIR" \
--iprlookup \
--goterms \
--disable-precalc \
--pathways || { echo "InterProScan failed for $BASENAME" >&2; exit 3; }


echo "removing $CLEANED ..."
rm -f "$CLEANED" || echo "Warning: could not remove $CLEANED" >&2

echo "[$(date)] Finished $BASENAME"