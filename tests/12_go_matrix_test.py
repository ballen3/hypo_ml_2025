import os
import pandas as pd
from collections import defaultdict
import argparse

# command line arguments
parser = argparse.ArgumentParser(description='Process GO <genome>_clean.tsv files and build a genome x GO matrix.')
parser.add_argument('-i', '--input', required=True, help='Input folder containing *_clean.tsv files')
parser.add_argument('-o', '--output', required=True, help='Output folder where result will be saved')
parser.add_argument('--outfile', default='go_matrix.tsv', help='Name of output CSV file (default: go_matrix.csv)')
args = parser.parse_args()

input_dir = args.input
output_dir = args.output
outfile_name = args.outfile

# Process each folder 
# defaultdict gives every new key a default of 0 (prevents errors and having to write more lines)
# this is a nested defaultdict: genome has a dictionary of GO counts
    # eg. genome_go_counts = {"fusbra1": {"GO:1234": 3,"GO:5678": 5}
genome_go_counts = defaultdict(lambda: defaultdict(int))

for filename in os.listdir(input_dir):
    if not filename.endswith('.tsv'):
        continue
    genome = filename.replace('_clean.tsv', '') 
    filepath = os.path.join(input_dir, filename)
    df = pd.read_csv(filepath, sep='\t', dtype=str).fillna('-')

    grouped = df.groupby(df.columns[0]) # group by protein_accession

    for protein_id, group in grouped:
        go_terms_for_protein = set()

        for _, row in group.iterrows(): #the _ variable is for the index, python convention for an unused variable. We care about row here, not the index, have to include both bc interrows returns (index,row)
            go_field = row[13]
            if go_field == '-' or go_field.strip() == '':
                continue

            gos = go_field.split('|')
            interpro_gos = {r.split('(')[0] for r in gos if r.endswith('(InterPro)')}
            go_terms_for_protein.update(interpro_gos)

        for go_term in go_terms_for_protein:
            genome_go_counts[genome][go_term] += 1

# Build matrix
matrix_df = pd.DataFrame.from_dict(genome_go_counts, orient='index').fillna(0).astype(int)
matrix_df = matrix_df.sort_index().reindex(sorted(matrix_df.columns), axis=1)

# Save result
os.makedirs(output_dir, exist_ok=True)
output_path = os.path.join(output_dir, outfile_name)
matrix_df.to_csv(output_path, sep='\t')

print(f"Matrix saved to: {output_path}")