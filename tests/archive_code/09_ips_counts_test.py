import pandas as pd
import glob
import os
import sys

if len(sys.argv) != 3:
    print("Usage: python script.py /path/to/input_dir /path/to/output_dir")
    sys.exit(1)

input_folder = sys.argv[1]
output_folder = sys.argv[2]
os.makedirs(output_folder, exist_ok=True)

file_pattern = os.path.join(input_folder, "*_clean.tsv")

all_processed_rows = []
all_protein_records = []

def merge_intervals(intervals):
    # intervals: list of (start, end) tuples
    if not intervals:
        return []
    # Sort intervals by start coordinate
    intervals.sort(key=lambda x: x[0])
    merged = [intervals[0]]
    for current in intervals[1:]:
        prev = merged[-1]
        if current[0] <= prev[1]:  # overlap or contiguous
            # merge intervals
            merged[-1] = (prev[0], max(prev[1], current[1]))
        else:
            merged.append(current)
    return merged

for filepath in glob.glob(file_pattern):
    genome_id = os.path.basename(filepath).replace("_clean.tsv", "")
    # Read columns: protein_id (0), start (7), end (8), ipa_accession (11)
    df = pd.read_csv(filepath, sep="\t", header=None, usecols=[0,6,7,11], dtype={0:str,7:int,8:int,11:str})
    df.columns = ["protein_id", "start", "end", "ipa_accession"]
    df["genome_id"] = genome_id
    
    # Save all proteins (including those without IPA)
    df_all_proteins = df[["protein_id", "genome_id"]].drop_duplicates()
    all_protein_records.append(df_all_proteins)
    
    # Filter valid IPA rows
    df_valid_ipa = df[df["ipa_accession"] != "-"]
    
    # Group by protein_id and ipa_accession, merge overlapping intervals
    rows = []
    for (protein, ipa), group in df_valid_ipa.groupby(["protein_id", "ipa_accession"]):
        intervals = list(zip(group["start"], group["end"]))
        merged_intervals = merge_intervals(intervals)
        # For each merged interval, create a record
        for start_, end_ in merged_intervals:
            rows.append({
                "genome_id": genome_id,
                "protein_id": protein,
                "ipa_accession": ipa,
                "start": start_,
                "end": end_
            })
    all_processed_rows.extend(rows)

# Create DataFrame from processed rows
processed_df = pd.DataFrame(all_processed_rows)

# Now group by genome_id and ipa_accession counting unique proteins
matrix = (
    processed_df.groupby(["genome_id", "ipa_accession"])["protein_id"]
    .nunique()
    .reset_index()
    .pivot(index="genome_id", columns="ipa_accession", values="protein_id")
    .fillna(0)
)

protein_df = pd.concat(all_protein_records, ignore_index=True)
total_proteins = protein_df.groupby("genome_id").size()

matrix = matrix.reindex(total_proteins.index).fillna(0)
norm_matrix = matrix.div(total_proteins, axis=0).round(5)

raw_outfile = os.path.join(output_folder, "genome_ipa_matrix_raw.tsv")
matrix.to_csv(raw_outfile, sep="\t", index=True, index_label="genome")

norm_outfile = os.path.join(output_folder, "genome_ipa_matrix_normalized.tsv")
norm_matrix.to_csv(norm_outfile, sep="\t", index=True, index_label="genome")

print(f"Raw counts saved to: {raw_outfile}")
print(f"Normalized counts saved to: {norm_outfile}")




