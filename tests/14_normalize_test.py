import os
import pandas as pd
import argparse

# Command-line arguments
parser = argparse.ArgumentParser(
    description='Normalize a feature matrix by dividing each count by the genome\'s total protein count.'
)
parser.add_argument('-i', '--input', required=True, help='Input matrix file (TSV with genome IDs in first column)')
parser.add_argument('-p', '--protein_counts', required=True, help='CSV file with genome ID and total protein counts')
parser.add_argument('-o', '--output', required=True, help='Output folder to save the normalized matrix')
parser.add_argument('--outfile', default='normalized_{}.tsv', help='Output filename format. Use {} to insert original base name.')

args = parser.parse_args()

# Read input matrix
matrix = pd.read_csv(args.input, sep='\t', index_col=0)

# Read protein counts
protein_counts = pd.read_csv(args.protein_counts, header=None, names=['genome_id', 'protein_count'])
protein_counts.set_index('genome_id', inplace=True)

# Align and join data
matrix = matrix.join(protein_counts, how='left')

# Warn if any genomes were missing
missing = matrix['protein_count'].isna()
if missing.any():
    print(f"Warning: Missing protein counts for {missing.sum()} genomes:")
    print(matrix[missing].index.tolist())

# Normalize
normalized_matrix = matrix.drop(columns=['protein_count']).div(matrix['protein_count'], axis=0)

# Create output filename
base_name = os.path.splitext(os.path.basename(args.input))[0]
outfile_name = args.outfile.format(base_name)
outfile_path = os.path.join(args.output, outfile_name)

# Save
os.makedirs(args.output, exist_ok=True)
normalized_matrix.to_csv(outfile_path, sep='\t')
print(f"Normalized matrix saved to: {outfile_path}")

