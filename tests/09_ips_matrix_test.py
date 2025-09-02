import pandas as pd
import os
from collections import defaultdict

# Check if two ranges overlap
def ranges_overlap(s1, e1, s2, e2):
    return max(s1, s2) <= min(e1, e2)

# Deduplicate InterPro accessions per protein
def deduplicate_interpros(df):
    protein_groups = df.groupby(0)  
    interpro_counts = defaultdict(int)

    for _, group in protein_groups:
        ipr_ranges = defaultdict(list)

        for _, row in group.iterrows():
            ipr = row[11]
            if ipr == '-' or pd.isna(ipr):
                continue
            try:
                start = int(row[6])
                end = int(row[7])
            except ValueError:
                continue

            ipr_ranges[ipr].append((start, end))

        for ipr, ranges in ipr_ranges.items():
            ranges.sort()
            kept = []
            for s, e in ranges:
                if not any(ranges_overlap(s, e, ks, ke) for ks, ke in kept):
                    kept.append((s, e))
            interpro_counts[ipr] += len(kept)

    return interpro_counts

# Process all .tsv files in input folder
def process_all_genomes(folder_path):
    genome_matrix = {}
    all_iprs = set()

    for filename in os.listdir(folder_path):
        if not filename.endswith("clean.tsv"):
            continue

        filepath = os.path.join(folder_path, filename)
        df = pd.read_csv(filepath, sep="\t", header=None, dtype=str)

        genome_name = filename.split('_')[0]
        counts = deduplicate_interpros(df)
        genome_matrix[genome_name] = counts
        all_iprs.update(counts.keys())

    all_iprs = sorted(all_iprs)
    matrix = pd.DataFrame(index=genome_matrix.keys(), columns=all_iprs).fillna(0)

    for genome, counts in genome_matrix.items():
        for ipr, count in counts.items():
            matrix.at[genome, ipr] = count

    return matrix

# Hardcoded Paths 
if __name__ == "__main__":
    input_dir = "/project/arsef/projects/hypo_ml_2025/tests/test_outputs/ips_test_output"  # Folder containing .tsv files
    output_file = "/project/arsef/projects/hypo_ml_2025/tests/test_outputs/interpro_matrix.tsv"  # Path to save output

    # Create output directory if it doesn't exist
    os.makedirs(os.path.dirname(output_file), exist_ok=True)

    result = process_all_genomes(input_dir)
    result.to_csv(output_file, sep="\t")
    print(f"==IPS Matrix Saved to {output_file}==")


