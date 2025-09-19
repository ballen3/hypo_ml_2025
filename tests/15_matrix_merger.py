import pandas as pd
import os

version = "1"  # file version for output naming (mainly for testing purposes)

# Folder where your normalized matrices are stored
input_folder = "/project/arsef/projects/hypo_ml_2025/tests/test_outputs/normalized_matrices_test"
output_folder = "/project/arsef/projects/hypo_ml_2025/tests/test_outputs/normalized_matrices_test/combined"

# Create output directory if it doesn't exist
os.makedirs(output_folder, exist_ok=True)

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

# Construct a representative output filename using the version
check_filename = f"combined_normalized_features_{version}.tsv"
check_path = os.path.join(output_folder, check_filename)

# If it already exists, stop the script
if os.path.exists(check_path):
    raise FileExistsError(f"A file with version {version} already exists: {check_path}")


# Save combined matrix
output_path = os.path.join(output_folder, f"combined_normalized_features_{version}.tsv")
combined_df.to_csv(output_path, sep="\t")
print("Combined matrix saved to:", output_path)
print("Combined matrix shape:", combined_df.shape)


