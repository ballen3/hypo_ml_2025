import pandas as pd
from collections import defaultdict
import os

# Load BiG-SCAPE output
input_file = "/home/brooke.allen/hypo/tests/test_outputs/bs_test_output/output_files/2025-09-08_18-51-00_c0.3/record_annotations.tsv"
output_dir = "/home/brooke.allen/hypo/tests/test_outputs/bs_test_output/"
df = pd.read_csv(input_file, sep='\t')

# Function to extract genome name (e.g., "beaaus1" from "beaaus1_scaffold_1435")
def extract_genome(description):
    return description.split('_scaffold')[0]

# Initialize nested dictionary: genome -> class -> count
genome_class_counts = defaultdict(lambda: defaultdict(int))

# Iterate through the dataframe
for _, row in df.iterrows():
    genome = extract_genome(row['Description'])
    bgc_class = row['Class']
    genome_class_counts[genome][bgc_class] += 1

# Convert to DataFrame for output
output_df = pd.DataFrame.from_dict(genome_class_counts, orient='index').fillna(0).astype(int)
# Sort for readability (optional)
output_df = output_df.sort_index().sort_index(axis=1)

# Save bgc class counts per genome
os.makedirs(output_dir, exist_ok=True) # Ensure output directory exists
output_file = os.path.join(output_dir, "bgc_class_counts_by_genome.tsv")

output_df.to_csv(output_file, sep='\t')

print(f"Saved TSV to: {output_file}")

# Save total BGC counts per genome
total_bgcs_df = output_df.sum(axis=1).to_frame(name='total_bgcs')
total_output_file = os.path.join(output_dir, "total_bgcs_by_genome.tsv")
total_bgcs_df.to_csv(total_output_file, sep='\t')

print(f"Saved total BGC count TSV to: {total_output_file}")
