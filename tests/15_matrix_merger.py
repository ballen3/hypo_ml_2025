import pandas as pd
import os

# Folder where your normalized matrices are stored
input_folder = "/project/arsef/projects/hypo_ml_2025/tests/test_outputs/normalized_matrices_test"

# List all matrix files, e.g., .tsv files
files = [f for f in os.listdir(input_folder) if f.endswith(".tsv")]

# Initialize combined_df as None
combined_df = None

for f in files:
    path = os.path.join(input_folder, f)
    df = pd.read_csv(path, sep="\t", index_col=0)
    
    if combined_df is None:
        combined_df = df
    else:
        combined_df = combined_df.join(df, how="outer")

# Replace NaNs with zeros
combined_df = combined_df.fillna(0)

# Save combined matrix
output_path = os.path.join(input_folder, "combined_normalized_features.tsv")
combined_df.to_csv(output_path, sep="\t")
print("Combined matrix saved to:", output_path)
print("Combined matrix shape:", combined_df.shape)


