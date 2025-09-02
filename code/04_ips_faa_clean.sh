#!/bin/bash

# Purpose: remove * from .faa protein sequences to prep for input to interproscan
# Usage: 04_ips_faa_clean.sh /path/to/file.faa
# Outputs: cleaned .faa file path (in temp dir)

## Shouldn't have to change any of these at this level.
INPUT="$1"
TEMP_DIR="${2:-/tmp}"
BASENAME=$(basename "$INPUT" .faa)

## makes the temp_dir if it doesn't already exist (redundant but whatever)
mkdir -p "$TEMP_DIR"

## Error if an input isn't found
if [[ ! -f "$INPUT" ]]; then
    echo "Cleaning Error: file at $INPUT not found." >&2
    exit 1
fi

## Remove asterisks (*) from protein sequences and write cleaned file to temp directory
CLEANED="${TEMP_DIR}/${BASENAME}_clean"
if ! sed 's/\*//g' "$INPUT" > "$CLEANED"; then
    echo "Cleaning Error: sed failed to process $INPUT" >&2
    exit 3
fi

## Error if the cleaned file is not created
if [[ ! -f "$CLEANED" ]]; then
    echo "Cleaning Error: Failed to clean * from $BASENAME" >&2
    exit 2
fi

## Print the cleaned file path for downstream scripts to capture and use as input
echo "$CLEANED"