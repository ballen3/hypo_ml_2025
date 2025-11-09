import pandas as pd
import os

#!/usr/bin/env python3
"""
Select a core set of 64 fungal species for OrthoFinder analysis.

This script:
- Loads genome metadata with BUSCO completeness scores.
- Deduplicates species within genera based on the highest BUSCO scores.
- Prioritizes genera with ≥3 species by selecting one representative from each.
- Fills remaining slots from other genera to reach a total of 64 species.
- Saves the selected core set and a summary of genus representation.

Author: Brooke Allen
Date: 2024-10-01
"""

# Parameters 
INPUT_FILE = "/home/brooke.allen/hypo/data/04_dedup_no_sp.csv" 
OUTPUT_FILE = "/home/brooke.allen/hypo/data/selected_64_core_species.tsv"
SUMMARY_FILE = "/home/brooke.allen/hypo/data/genus_summary_core64.tsv"
N_TOTAL = 64  # Total species to select

os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)

# Load data
df = pd.read_csv(INPUT_FILE)
df['genus'] = df['genus'].str.strip().str.lower()
df['species'] = df['species'].str.strip().str.lower()

# Deduplicate by species, keeping entry with highest BUSCO.Complete.Percent
df_dedup = df.sort_values('BUSCO.Complete.Percent', ascending=False).drop_duplicates(subset='species')

# Total unique genera after deduplication
total_genera = df_dedup['genus'].nunique()
print(f"Total unique genera after BUSCO-based deduplication: {total_genera}")

# Count deduplicated species per genus
genus_counts = df_dedup['genus'].value_counts()

# Split genera by species count threshold (≥3 species)
genera_ge3 = genus_counts[genus_counts >= 3].index
genera_lt3 = genus_counts[genus_counts < 3].index

# Priority group: one species per genus with ≥3 species
df_priority = df_dedup[df_dedup['genus'].isin(genera_ge3)]
priority_selection = df_priority.drop_duplicates(subset='genus')

print(f"Number of genera with ≥3 species: {len(genera_ge3)}")
print(f"Number of species selected from priority genera: {len(priority_selection)}")

# Calculate how many slots remain
slots_left = N_TOTAL - len(priority_selection)

# Exclude priority genera from random selection pool
remaining_genera = set(genera_lt3) - set(priority_selection['genus'])
df_remaining = df_dedup[df_dedup['genus'].isin(remaining_genera)]

# Keep only one species per genus in remaining pool
df_remaining_unique = df_remaining.drop_duplicates(subset='genus')

# Check if enough unique genera remain
if slots_left > len(df_remaining_unique):
    raise ValueError(f"Not enough unique genera in the random pool to fill {slots_left} slots")

# Randomly sample remaining species
random_selection = df_remaining_unique.sample(n=slots_left, random_state=42)

# Combine final core set
core_set = pd.concat([priority_selection, random_selection], ignore_index=True)

# Sanity check
assert len(core_set) == N_TOTAL, f"Selected {len(core_set)} species, expected {N_TOTAL}"

# Select and save relevant columns
columns_to_keep = ['genus', 'species', 'portal_acc', 'Genome_entry', 'jgi_portal', 'BUSCO.Complete.Percent']
core_set = core_set[columns_to_keep]
core_set.to_csv(OUTPUT_FILE, index=False, sep='\t')
print(f"\nCore set of {N_TOTAL} species saved to {OUTPUT_FILE}")

# ----- Genus Summary Report -----

# Get raw (non-deduplicated) species/genome count per genus
raw_counts = df['genus'].value_counts()

# Get deduplicated species count per genus
dedup_counts = df_dedup['genus'].value_counts()

# Create combined summary
genus_summary = pd.DataFrame({
    'Raw Genome Count': raw_counts,
    'Deduplicated Species Count': dedup_counts
})

# Calculate relative and scaled proportions
genus_summary['% of Total'] = 100 * genus_summary['Deduplicated Species Count'] / len(df_dedup)

# Add final allocation from selected core set
selected_genus_counts = core_set['genus'].value_counts()
genus_summary['Final Allocation'] = selected_genus_counts

# Clean up and save summary
genus_summary['Final Allocation'] = genus_summary['Final Allocation'].fillna(0).astype(int)
genus_summary = genus_summary.sort_values(by='Deduplicated Species Count', ascending=False)
genus_summary.to_csv(SUMMARY_FILE, sep='\t')
print(f"\nGenus summary saved to {SUMMARY_FILE}")

# Print genus counts in final core set
print("\nGenus counts in core set:")
print(core_set['genus'].value_counts().sort_values(ascending=False).to_string())

