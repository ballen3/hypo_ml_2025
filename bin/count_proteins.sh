#!/bin/bash
for file_name in $(</project/arsef/projects/hypo_ml_2025/data/faa_list.txt); do
    echo -n "$file_name," >> protein_counts.csv
    grep -c '>' /project/arsef/projects/hypo_ml_2025/data/faa/$file_name >> protein_counts.csv
done
