#!/bin/bash 
base="/project/arsef/projects/allen_phd/output/antismash"

for d in "$base"/*/; do
  dir=$(basename "$d")
  for f in "$d"/*.region*.gbk; do
    [ -e "$f" ] || continue
    echo mv "$f" "$d/${dir}_$(basename "$f")"
  done
done