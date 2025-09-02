import pandas as pd
import glob

# === PATHS ===
search_path = "/project/arsef/projects/hypo_ml_2025/tests/test_outputs/dbs_batch_output/*/overview.tsv"
output_path = "/project/arsef/projects/hypo_ml_2025/tests/test_outputs/dbs_batch_output/cazyme_matrix.tsv"

# === LOAD AND COMBINE ALL overview.tsv FILES ===
file_list = glob.glob(search_path)
if not file_list:
    raise FileNotFoundError(f"No overview.tsv files found in path: {search_path}")

dfs = []
for file in file_list:
    try:
        df = pd.read_csv(file, sep="\t")
        dfs.append(df)
    except Exception as e:
        print(f"Skipped {file}: {e}")

if not dfs:
    raise ValueError("No valid overview.tsv files could be loaded.")

df = pd.concat(dfs, ignore_index=True)

# EXTRACT GENOME NAME FROM GENE ID
df["Genome"] = df["Gene ID"].apply(lambda x: x.split("_")[0] if isinstance(x, str) else "unknown")

# EXTRACT CAZy FAMILIES FROM 'Recommend Results' COLUMN ONLY 
def extract_families(val):
    families = set()
    if pd.notna(val) and val != "-":
        entries = val.replace("|", ",").split(",")
        for entry in entries:
            if entry.strip():
                base_family = entry.split("_")[0]  # Remove subfamily suffix (_eXXX)
                families.add(base_family)
    return list(families)

df["CAZy_families"] = df["Recommend Results"].apply(extract_families)

# EXPLODE TO (Genome, Family) ROWS
exploded = df.explode("CAZy_families")
exploded = exploded[exploded["CAZy_families"].notna()]

# REATE GENOME × FAMILY MATRIX
matrix = pd.crosstab(exploded["Genome"], exploded["CAZy_families"])

# === SAVE TO FILE ===
matrix.to_csv(output_path, sep="\t")
print(f"Matrix saved: {output_path}")
print("Matrix shape:", matrix.shape)




