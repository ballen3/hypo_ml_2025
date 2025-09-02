import os
import pandas as pd
from collections import defaultdict
import argparse

# command line arguments
parser = argparse.ArgumentParser(description='Process pathway <genome>_clean.tsv files and build a genome x pathway matrix.')
parser.add_argument('-i', '--input', required=True, help='Input folder containing *_clean.tsv files')
parser.add_argument('-o', '--output', required=True, help='Output folder where result will be saved')
parser.add_argument('--outfile', default='pwy_matrix.tsv', help='Name of output CSV file (default: go_matrix.csv)')
args = parser.parse_args()

input_dir = args.input
output_dir = args.output
outfile_name = args.outfile

# Process each folder 
# defaultdict gives every new key a default of 0 (prevents errors and having to write more lines)
# this is a nested defaultdict: genome has a dictionary of GO counts
    # eg. genome_go_counts = {"fusbra1": {"PWY_1234": 3,"PWY_5678": 5}
genome_pwy_counts = defaultdict(lambda: defaultdict(int))

tsv_files = [f for f in os.listdir(input_dir) if f.endswith('_clean.tsv')]
total_files = len(tsv_files)

for idx, filename in enumerate(tsv_files, start=1):
    print(f"{idx}/{total_files} processed: {filename}")
    genome = filename.replace('_clean.tsv', '') 
    filepath = os.path.join(input_dir, filename)
    df = pd.read_csv(filepath, sep='\t', dtype=str).fillna('-')

    grouped = df.groupby(df.columns[0])  # group by protein_accession

    for protein_id, group in grouped:
        unique_pathways = set()

        for _, row in group.iterrows():
            raw_pathway_str = row[14]
            if raw_pathway_str == '-' or raw_pathway_str.strip() == '':
                continue

            raw_pathway_list = raw_pathway_str.split('|')
            metacyc_pathways = {
                p.replace('MetaCyc:PWY-', 'PWY-') for p in raw_pathway_list if p.startswith('MetaCyc:PWY-')
            }
            unique_pathways.update(metacyc_pathways)

        for pathway_id in unique_pathways:
            genome_pwy_counts[genome][pathway_id] += 1


# Build matrix
matrix_df = pd.DataFrame.from_dict(genome_pwy_counts, orient='index').fillna(0).astype(int)
matrix_df = matrix_df.sort_index().reindex(sorted(matrix_df.columns), axis=1)

# Save result
os.makedirs(output_dir, exist_ok=True)
output_path = os.path.join(output_dir, outfile_name)
matrix_df.to_csv(output_path, sep='\t')

print(f"Matrix saved to: {output_path}")