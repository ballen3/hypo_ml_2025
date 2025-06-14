#!/bin/bash

# Purpose: remove * from .faa protein sequences to prep for input to interproscan
# Usage: 04_ips_faa_clean.sh /path/to/file.faa
# Outputs: cleaned .faa file path (in temp dir)

INPUT="$1"
TEMP_DIR="${2:-/tmp}"
BASENAME=$(basename "$INPUT" .faa)

mkdir -p "$TEMP_DIR"


if [[ ! -f "$INPUT" ]]; then
    echo "Error: file at $INPUT not found." >&2
    exit 1
fi

CLEANED="${TEMP_DIR}/${BASENAME}_cleaned.faa"

sed 's/\*//g' "$INPUT" > "$CLEANED"

if [[ ! -f "$CLEANED" ]]; then
    echo "Failed to clean $BASENAME" >&2
    exit 2
fi
echo "$CLEANED"