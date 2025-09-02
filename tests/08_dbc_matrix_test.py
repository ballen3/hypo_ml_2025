import os
import pandas as pd
from collections import defaultdict
import argparse

# command line arguments
parser = argparse.ArgumentParser(description='Process dbCAN overview.tsv files and build a genome x recommended CAZy matrix.')
parser.add_argument('-i', '--input', required=True, help='Input folder containing *_dbcan subdirectories')
parser.add_argument('-o', '--output', required=True, help='Output folder where result will be saved')
parser.add_argument('--outfile', default='dbcan_matrix.tsv', help='Name of output CSV file (default: dbcan_matrix.csv)')
args = parser.parse_args()

input_dir = args.input
output_dir = args.output
outfile_name = args.outfile

# Prepare folder list 
# list comprehension: shorthand version of for loop
    # making a list of the DBcan sub-directories
folders = [f for f in os.listdir(input_dir)
           if f.endswith('_dbcan') and os.path.isdir(os.path.join(input_dir, f))]

if not folders:
    print("No *_dbcan folders found in the input directory.")
    exit()

# Process each folder 
# defaultdict gives every new key a default of 0 (prevents errors and having to write more lines)
# this is a nested defaultdict: genome has a dictionary of CAZyme counts
    # eg. genome_reco_counts = {"fusbra1": {"DCB_GH18": 3,"DCB_CBM50": 5}
genome_reco_counts = defaultdict(lambda: defaultdict(int))

for folder in folders:
    genome = folder.split('_')[0] 
    filepath = os.path.join(input_dir, folder, 'overview.tsv')

    if not os.path.exists(filepath):
        print(f"File not found: {filepath}")
        continue

    df = pd.read_csv(filepath, sep='\t', dtype=str).fillna('-')

    for _, row in df.iterrows(): #the _ variable is for the index, python convention for an unused variable. We care about row here, not the index, have to include both bc interrows returns (index,row)
        reco_field = row['Recommend Results']
        if reco_field == '-' or reco_field.strip() == '':
            continue

        recos = reco_field.split('|')
        simplified_recos = set(r.split('_')[0] for r in recos) #set ensures uniqueness

        for reco in simplified_recos:
            genome_reco_counts[genome][f'DBC_{reco}'] += 1

# Build matrix
matrix_df = pd.DataFrame.from_dict(genome_reco_counts, orient='index').fillna(0).astype(int)
matrix_df = matrix_df.sort_index().reindex(sorted(matrix_df.columns), axis=1)

# Save result
os.makedirs(output_dir, exist_ok=True)
output_path = os.path.join(output_dir, outfile_name)
matrix_df.to_csv(output_path, sep='\t')

print(f"Matrix saved to: {output_path}")



