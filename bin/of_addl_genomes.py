import os
import pandas as pd

# Parameters 
# (if you don't use tsv, you will have to change loading steps)
MATCHED_OME_FILE = "/home/brooke.allen/hypo/data/matched_ome_list.tsv"
FAA_LIST_FILE = "/home/brooke.allen/hypo/data/faa_list.txt"
SOURCE_DIR = "/project/arsef/databases/mycotools/mycotoolsdb/data/faa"
TARGET_DIR = "/home/brooke.allen/hypo/data/of_addl_faa"

# Ensure target directory exists
os.makedirs(TARGET_DIR, exist_ok=True)

# Load matched OME list (these should NOT be linked) 
# if you don't use tsv, you will have to change this step
matched_df = pd.read_csv(MATCHED_OME_FILE, sep='\t')
matched_omes = set(matched_df['OME'].dropna().unique())

# Load FAA list and strip ".faa" extension if present
# my FAA_LIST_FILE had .faa extensions, so I stripped them here- might not be necessary for you but should work regardless
with open(FAA_LIST_FILE) as f:
    faa_list = set(
        line.strip()[:-4] if line.strip().endswith(".faa") else line.strip()
        for line in f if line.strip()
    )

# lists to track results
linked = []
not_linked = []
skipped_matched = []

# Process all .faa files in source directory
for filename in sorted(os.listdir(SOURCE_DIR)):
    if not filename.endswith(".faa"): # only process .faa files
        continue
    # Extract OME ID (assuming filename is OME.faa)
    ome_id = filename.replace(".faa", "")

    # Only link if:
    # - In FAA list
    # - NOT in matched list
    if ome_id not in faa_list:
        continue
    if ome_id in matched_omes:
        skipped_matched.append(ome_id)
        continue

    # Create symlink
    src_file = os.path.join(SOURCE_DIR, filename)
    dst_file = os.path.join(TARGET_DIR, filename)

    try:
        if os.path.islink(dst_file):
            os.remove(dst_file)
        elif os.path.exists(dst_file):
            print(f"Skipping {ome_id}: destination exists and is not a symlink.")
            not_linked.append(ome_id)
            continue

        os.symlink(src_file, dst_file)
        linked.append(ome_id)
    except Exception as e:
        print(f"Failed to create symlink for {ome_id}: {e}")
        not_linked.append(ome_id)


# Reporting
print(f"\n Linked {len(linked)} eligible FAA OME files to {TARGET_DIR}.")

if skipped_matched:
    print(f"\n Skipped {len(skipped_matched)} OME files because they are in the matched list.")
    # Optional: print the list
    # for ome_id in skipped_matched:
    #     print(ome_id)

if not_linked:
    print(f"\n {len(not_linked)} OME files could not be linked due to existing conflicts or errors:")
    for ome_id in not_linked:
        print(ome_id)
else:
    print("\n All eligible OME files were linked successfully.")
