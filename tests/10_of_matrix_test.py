import pandas as pd

# FILE PATHS 
input_path = "/project/arsef/projects/hypo_ml_2025/tests/test_outputs/of_test_output/July11/Results_Jul11/Orthogroups/Orthogroups.GeneCount.tsv"
output_path = "/project/arsef/projects/hypo_ml_2025/tests/test_outputs/of_test_output/July11/Results_Jul11/Orthogroups/Orthogroups_transposed.tsv"

# LOAD AND PROCESS 
# Load the orthogroup gene count matrix
df = pd.read_csv(input_path, sep="\t")

# Remove the 'Total' column if it exists
if "Total" in df.columns:
    df = df.drop(columns=["Total"])

# Set 'Orthogroup' as index so orthogroup IDs become columns after transpose
df = df.set_index("Orthogroup")

# Transpose: genomes become rows, orthogroups become columns
df_transposed = df.transpose()

# Save the result
df_transposed.to_csv(output_path, sep="\t")

print(f"Transposed matrix saved to:\n{output_path}")
print("Matrix shape:", df_transposed.shape)
