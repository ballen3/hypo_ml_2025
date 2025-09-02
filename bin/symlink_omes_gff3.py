import os
import pandas as pd

# Load OME list
ome_csv_path = "/project/arsef/projects/hypo_ml_2025/data/02_ome_list.csv"
df_ome = pd.read_csv(ome_csv_path)
ome_set = set(df_ome['OME'].astype(str).str.strip())  # Clean up any whitespace

# Define source and destination directories
input_dir = "/project/arsef/databases/mycotools/mycotoolsdb/data/gff3"
output_dir = "/project/arsef/projects/hypo_ml_2025/data/gff3"

# Make sure output directory exists
os.makedirs(output_dir, exist_ok=True)

# Loop through files in the input directory
for filename in os.listdir(input_dir):
    # Skip non-gff3 files (optional)
    if not filename.endswith(".gff3"):
        continue

    # Get base name without extension
    base_name = os.path.splitext(filename)[0]

    if base_name in ome_set:
        source_path = os.path.join(input_dir, filename)
        link_path = os.path.join(output_dir, filename)

        try:
            os.symlink(source_path, link_path)
            print(f"Linked: {filename}")
        except FileExistsError:
            print(f"Symlink already exists: {filename}")
        except Exception as e:
            print(f"Error linking {filename}: {e}")
