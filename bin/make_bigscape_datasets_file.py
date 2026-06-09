#!/usr/bin/env python3

# [note!!] this file needs to be exactly named 'datasets.tsv', and to be placed at the input folder's root folder.
# where each 'dataset' is a directory containting antismash GBK region files for one genome.
# Columns filled with the following information (in exactly the same order):
# 1. Dataset name
# 2. Path to dataset folder (relative to input folder's root folder)
# 3. Path to taxonomy file (see <taxonomy_X.tsv> files)
# 4. Description of the dataset

# 1. /home/brooke.allen/hypo/data/lists/host/real_host_metadata_pruned.csv 'OME' column 0
# 2. /home/brooke.allen/hypo/output/bigslice_input/*
# 3. /home/brooke.allen/hypo/output/bigslice_input/taxonomy.tsv
# 4. OME dataset 

import csv
from pathlib import Path


# Paths
input_root = Path("/home/brooke.allen/hypo/output/bigslice_input")  # BigSlice input folder
metadata_csv = Path("/home/brooke.allen/hypo/data/lists/host/real_host_metadata_pruned.csv")
taxonomy_file = Path("taxonomy/taxonomy.tsv")  # Relative to input root
output_file = input_root / "datasets.tsv"

# Column index for OME in CSV (0-based)
COL_OME = 0

# Load list of dataset names from CSV
dataset_names = []
with open(metadata_csv, newline="") as csvfile:
    reader = csv.reader(csvfile)
    next(reader) # Skip header
    for row in reader:
        ome = row[COL_OME].strip()
        dataset_names.append(ome)


# Write datasets.tsv
with open(output_file, "w", newline="") as tsvfile:
    writer = csv.writer(tsvfile, delimiter="\t")
    
    # Add required header
    writer.writerow(["# Dataset name", "Path to folder", "Path to taxonomy", "Description"])
    
    for ome in dataset_names:
        # Relative path to dataset folder from input_root
        dataset_path = ome + "/"  # BigSlice expects trailing slash
        
        # Relative path to taxonomy file from input_root
        taxonomy_path = taxonomy_file  # just "taxonomy.tsv"
        
        description = f"{ome} dataset"
        
        writer.writerow([
            ome,            # Column 1: Dataset name
            dataset_path,   # Column 2: Path relative to input root
            taxonomy_path,  # Column 3: Path to taxonomy file (relative)
            description     # Column 4: Description
        ])

print(f"datasets.tsv written to {output_file}")


