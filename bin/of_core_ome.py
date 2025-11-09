import pandas as pd

"""
Match core species accession IDs to OME entries.

This script:
- Loads a list of selected core species and a larger OME list.
- Matches entries based on accession IDs (portal_acc ↔ assembly_acc).
- Outputs a TSV file of successfully matched entries including their OME IDs.
- Reports any core species accessions that were not matched.

Author: Brooke Allen
Date: 2024-10-01
"""

# Input files
CORE_SPECIES_FILE = "/home/brooke.allen/hypo/data/selected_64_core_species.tsv"
OME_LIST_FILE = "/home/brooke.allen/hypo/data/02_ome_list.csv"
OUTPUT_FILE = "/home/brooke.allen/hypo/data/matched_ome_list.tsv"

# Load core species and OME list
core_df = pd.read_csv(CORE_SPECIES_FILE, sep='\t')
ome_df = pd.read_csv(OME_LIST_FILE)

# Clean whitespace from matching columns
core_df['portal_acc'] = core_df['portal_acc'].str.strip()
ome_df['assembly_acc'] = ome_df['assembly_acc'].str.strip()

# Merge dataframes on matching accession columns
merged_df = pd.merge(core_df, ome_df, left_on='portal_acc', right_on='assembly_acc', how='inner')

# Select relevant columns to save
output_df = merged_df[['portal_acc', 'assembly_acc', 'OME']]

# Save as TSV
output_df.to_csv(OUTPUT_FILE, sep='\t', index=False)
print(f"Matched {len(output_df)} rows saved to {OUTPUT_FILE}")

# Find portal_acc without matches
matched_portal_acc = set(output_df['portal_acc'])
all_portal_acc = set(core_df['portal_acc'])
unmatched_portal_acc = all_portal_acc - matched_portal_acc

if unmatched_portal_acc:
    print("\nportal_acc values with NO match in assembly_acc:")
    for acc in sorted(unmatched_portal_acc):
        print(acc)
else:
    print("\nAll portal_acc values had matches in assembly_acc.")

