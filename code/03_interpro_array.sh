#!/bin/bash
set -x  # Print commands as they execute

## Shouldn't have to change any of these at this level.
INPUT="$1"         # .faa file to process
CLEAN_SCRIPT="$2"  # The cleaning script path
TEMP_DIR="$3"      # Temporary cleaned .faa data directory
OUTPUT_DIR="$4"    # Where results should go
IPS_CPUS="${5:-8}" # Number of CPUs for interproscan, default to 4 if not set
BASENAME=$(basename "$INPUT" .faa) 
LOG_DIR="$6"
LOG_FILE="${LOG_DIR}/${BASENAME}_ips.log"


## Run 'metadata' reporting
echo "[$(date)] Starting $BASENAME on $(hostname)"

## Check required arguments 
if [[ -z "$INPUT" || -z "$CLEAN_SCRIPT" || -z "$TEMP_DIR" || -z "$OUTPUT_DIR" || -z "$LOG_DIR" ]]; then
    echo "Usage: $0 <input_file> <clean_script> <temp_dir> <output_dir> <ips_cpus> <log_dir>" >&2

    echo "ips_cpus defaults to 4 if not provided" >&2
    exit 1
fi

## run script to remove * from .faa input files ("clean" them)
CLEANED=$("$CLEAN_SCRIPT" "$INPUT" "$TEMP_DIR") || { echo "Cleaning failed"; exit 2; }
if [[ ! -f "$CLEANED" ]]; then
    echo "Cleaning Error: file at $CLEANED not found." >&2
    exit 2
fi

## Run InterProScan
{
    echo "[$(date)] Starting InterProScan for $BASENAME"
    stdbuf -oL interproscan.sh --cpu "$IPS_CPUS" \
    --input "$CLEANED" \
    --output-dir "$OUTPUT_DIR" \
    --tempdir "$TEMP_DIR" \
    --iprlookup \
    --goterms \
    --disable-precalc \
    --pathways
    echo "[$(date)] Finished InterProScan for $BASENAME"
} &> "$LOG_FILE"



# Check output
EXPECTED_TSV="${OUTPUT_DIR}/${BASENAME}_clean.tsv"

if [[ -f "$EXPECTED_TSV" && -s "$EXPECTED_TSV" ]]; then
    echo "InterProScan succeeded for $BASENAME"
    echo "Removing cleaned file: $CLEANED"
    rm -f "$CLEANED" || echo "Warning: could not remove $CLEANED" >&2
else
    echo "InterProScan failed or no output found for $BASENAME" >&2
fi



