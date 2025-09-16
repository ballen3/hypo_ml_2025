import os
import glob
import pandas as pd
from collections import defaultdict

# === Set paths ===
input_dir = "/home/brooke.allen/hypo/tests/test_outputs/phobius_test_output"
output_file = "/home/brooke.allen/hypo/tests/test_outputs/phobius_test_output/phobius_secreted_counts.tsv"

# === Initialize genome -> secreted protein count ===
secreted_counts = defaultdict(int)

# === Iterate through all *_phobius.out files ===
for filepath in glob.glob(os.path.join(input_dir, "*_phobius.out")):
    with open(filepath) as f:
        for line in f:
            line = line.strip()
            if line.startswith("SEQENCE") or not line:
                continue  # skip header or blank lines

            parts = line.split()
            if len(parts) < 4:
                continue  # malformed line

            seq_id, tm, sp = parts[0], parts[1], parts[2]
            genome = seq_id.split("_")[0]

            # Count only secreted (SP=Y) and non-membrane-bound (TM=0)
            if sp == 'Y' and tm == '0':
                secreted_counts[genome] += 1

# === Convert to DataFrame ===
df = pd.DataFrame.from_dict(secreted_counts, orient='index', columns=["Secreted_Proteins"])
df.index.name = "Genome"
df = df.sort_index()

# === Save to TSV ===
os.makedirs(os.path.dirname(output_file), exist_ok=True)
df.to_csv(output_file, sep='\t')

print(f"Saved secreted protein counts to: {output_file}")
