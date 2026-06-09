#!/usr/bin/env python3

# Genome folder	Kingdom	Phylum	Class	Order	Family	Genus	Species	Organism
# BiG-SLiCE requires its users to manually supply taxonomy metadata (if possible) for each dataset in the form of tab-separated file (.tsv) 
#   containing this information (in this exact order):
# 1. Genome folder name (ends with '/') (eg. NC_003888.3/)
# 2. Kingdom / Domain name
# 3. Phylum name
# 4. Class name
# 5. Order name
# 6. Family name
# 7. Genus name
# 8. Species name
# 9. Organism / Strain name

# 1. /home/brooke.allen/hypo/output/bigslice_input/*
# 2. Fungi
# 3. /home/brooke.allen/hypo/data/lists/host/real_host_metadata_pruned.csv column 6 'phylum' 5
# 3. /home/brooke.allen/hypo/data/lists/host/real_host_metadata_pruned.csv column 7 'class'
# 4. /home/brooke.allen/hypo/data/lists/host/real_host_metadata_pruned.csv column 8 'order'
# 5. /home/brooke.allen/hypo/data/lists/host/real_host_metadata_pruned.csv column 9 'family'
# 6. /home/brooke.allen/hypo/data/lists/host/real_host_metadata_pruned.csv column 10 'genus'
# 7. /home/brooke.allen/hypo/data/lists/host/real_host_metadata_pruned.csv column 11 'species'
# 8. /home/brooke.allen/hypo/data/lists/host/real_host_metadata_pruned.csv column 12 'strain'


#!/usr/bin/env python3
import csv
from pathlib import Path

# -----------------------------
# Paths
# -----------------------------
genome_folder_base = Path("/home/brooke.allen/hypo/output/bigslice_input")
metadata_csv = Path("/home/brooke.allen/hypo/data/lists/host/real_host_metadata_pruned.csv")
output_tsv = genome_folder_base / "taxonomy" / "taxonomy.tsv"

# Ensure taxonomy directory exists
output_tsv.parent.mkdir(parents=True, exist_ok=True)

# -----------------------------
# Column indices in CSV (0-based)
# -----------------------------
COL_OME = 0       # Genome folder identifier
COL_PHYLUM = 5    
COL_CLASS = 6
COL_ORDER = 7
COL_FAMILY = 8
COL_GENUS = 9
COL_SPECIES = 10
COL_STRAIN = 11

KINGDOM = "Fungi"

# -----------------------------
# Load CSV metadata
# -----------------------------
metadata = {}
with open(metadata_csv, newline='') as csvfile:
    reader = csv.reader(csvfile)
    next(reader)  # Skip header
    for row in reader:
        ome = row[COL_OME].strip()
        metadata[ome] = {
            "phylum": row[COL_PHYLUM].strip(),
            "class": row[COL_CLASS].strip(),
            "order": row[COL_ORDER].strip(),
            "family": row[COL_FAMILY].strip(),
            "genus": row[COL_GENUS].strip(),
            "species": row[COL_SPECIES].strip(),
            "strain": row[COL_STRAIN].strip()
        }

# Create a lowercase lookup dictionary for robust matching
metadata_keys = {k.strip().lower(): k for k in metadata.keys()}

# -----------------------------
# Write taxonomy.tsv
# -----------------------------
with open(output_tsv, "w", newline="") as tsvfile:
    writer = csv.writer(tsvfile, delimiter="\t")
    
    # Header row
    writer.writerow([
        "# Genome folder", "Kingdom", "Phylum", "Class", "Order",
        "Family", "Genus", "Species", "Organism"
    ])
    
    # Iterate over dataset folders
    for genome_dir in genome_folder_base.iterdir():
        if genome_dir.is_dir() and genome_dir.name != "taxonomy":
            ome_name = genome_dir.name.strip()
            key = ome_name.lower()
            if key not in metadata_keys:
                print(f"Warning: {ome_name} not found in metadata CSV — skipping")
                continue
            # Get original-cased key
            meta = metadata[metadata_keys[key]]
            writer.writerow([
                str(genome_dir.name) + "/",  # folder name + /
                KINGDOM,
                meta["phylum"],
                meta["class"],
                meta["order"],
                meta["family"],
                meta["genus"],
                meta["species"],
                meta["strain"]
            ])

print(f"Taxonomy TSV written to {output_tsv}")


