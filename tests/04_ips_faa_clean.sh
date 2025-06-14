#!/bin/bash

# Purpose: remove * from .faa protein sequences to prep for input to interproscan
# Usage: 04_ips_faa_clean.sh /path/to/file.faa
# Outputs: cleaned .faa file path (in temp dir)

INPUT="$1"

if [[ ! -f "$INPUT" ]]; then
    echo "Error: file at $INPUT not found." >&2
    exit 1
fi

BASENAME=$(basename "$INPUT" .faa)
TEMP_DIR="${TEMP_DIR:-/tmp}"

CLEANED="${TEMP_DIR}/${BASENAME}"_cleaned.faa

sed 's/\*//g' "$INPUT" > "$CLEANED"

if [[ -f "$CLEANED" ]]; then
    echo "cleaned $BASENAME sent to $CLEANED"
else
    echo "Failed to clean $BASENAME" >&2
    exit 2
fi