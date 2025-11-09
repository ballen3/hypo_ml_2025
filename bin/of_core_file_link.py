import os
import pandas as pd

"""
Link matched OME FAA files for OrthoFinder analysis.

This script:
- Loads a list of matched OME genome identifiers from a TSV file.
- For each OME ID, attempts to create a symbolic link to its corresponding .faa file
  from a central MycoTools database into a local target directory.
- Skips any missing files and logs unlinked OME IDs at the end.

Author: Brooke Allen
Date: 2024-10-01
"""

# Parameters
MATCHED_OME_FILE = "/home/brooke.allen/hypo/data/matched_ome_list.tsv"
SOURCE_DIR = "/project/arsef/databases/mycotools/mycotoolsdb/data/faa"   
TARGET_DIR = "/home/brooke.allen/hypo/data/OF_core_faa"  

os.makedirs(TARGET_DIR, exist_ok=True)

# Load matched OME list (just the OME column)
df = pd.read_csv(MATCHED_OME_FILE, sep='\t')
omes = df['OME'].dropna().unique()

not_linked = []

for ome_id in sorted(omes):
    src_file = os.path.join(SOURCE_DIR, f"{ome_id}.faa")
    dst_file = os.path.join(TARGET_DIR, f"{ome_id}.faa")
    
    if not os.path.exists(src_file):
        print(f"Source file not found for OME: {ome_id}")
        not_linked.append(ome_id)
        continue
    
    try:
        if os.path.exists(dst_file):
            os.remove(dst_file)  # Remove existing symlink or file
        os.symlink(src_file, dst_file)
    except Exception as e:
        print(f"Failed to create symlink for {ome_id}: {e}")
        not_linked.append(ome_id)

if not_linked:
    print("\nOME IDs that were NOT linked successfully:")
    for ome_id in not_linked:
        print(ome_id)
else:
    print("\nAll OME files were linked successfully.")
