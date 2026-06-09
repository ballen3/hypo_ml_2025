#!/bin/bash


DB_FILE="/home/brooke.allen/hypo/output/bigslice_output_basic_flat/result/data.db"      # Path to your data.db
OUTPUT_CSV="/home/brooke.allen/hypo/output/matrices/bgc_class_counts.csv"  # Path to save CSV

# Optional: navigate to DB folder (not strictly needed if DB_FILE is full path)
cd "$(dirname "$DB_FILE")"

# Export BGC counts per genome and class
sqlite3 -header -csv "$DB_FILE" "
SELECT d.name AS genome, cc.name AS bgc_class, COUNT(*) AS count
FROM bgc_class bc
JOIN bgc b ON bc.bgc_id = b.id
JOIN chem_subclass cs ON bc.chem_subclass_id = cs.id
JOIN chem_class cc ON cs.class_id = cc.id
JOIN dataset d ON b.dataset_id = d.id
GROUP BY d.name, cc.name
ORDER BY d.name, cc.name;
" > "$OUTPUT_CSV"

echo "BGC class counts exported to $OUTPUT_CSV"
