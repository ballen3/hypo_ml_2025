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

## Mark current file as in-progress, only if it isnt already there or complete
if ! grep -Fxq "$INPUT" "$OUTPUT_DIR/completed_files.txt" && \
   ! grep -Fxq "$INPUT" "$OUTPUT_DIR/in_progress.txt"; then
    echo "$INPUT" >> "$OUTPUT_DIR/in_progress.txt"
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

## You can comment-out the interproscan lines above and uncomment the line below to do a "dry-run" test without running IPS
#echo "Pretending to run InterProScan for $CLEANED for a test!"


## Check if interproscan succeeded by looking for the expected .tsv file
EXPECTED_TSV="${OUTPUT_DIR}/${BASENAME}_clean.tsv"

## Updating tracking files post IPS run completion/failure
if [[ -f "$EXPECTED_TSV" && -s "$EXPECTED_TSV" ]]; then
    echo "InterProScan completed successfully for $BASENAME at [$(date)]"

    # Add to completed_files.txt
    {
        flock 200
        if ! grep -Fxq "$INPUT" "$OUTPUT_DIR/completed_files.txt"; then
            echo "$INPUT" >> "$OUTPUT_DIR/completed_files.txt"
        fi
    } 200>"$OUTPUT_DIR/completed_files.txt.lock"

    # Remove from in_progress.txt
    {
        flock 201
        if grep -Fxq "$INPUT" "$OUTPUT_DIR/in_progress.txt"; then
            sed -i "\|^$INPUT\$|d" "$OUTPUT_DIR/in_progress.txt"
        fi
    } 201>"$OUTPUT_DIR/in_progress.txt.lock"

    # Remove cleaned .faa
    echo "removing $CLEANED ..."
    rm -f "$CLEANED" || echo "Warning: could not remove $CLEANED" >&2
else
    echo "InterProScan did NOT complete successfully for $BASENAME. No .tsv output found." >&2

    # Add to failed_files.txt
    {
        flock 202
        echo "$INPUT" >> "$OUTPUT_DIR/failed_files.txt"
    } 202>"$OUTPUT_DIR/failed_files.txt.lock"
fi




