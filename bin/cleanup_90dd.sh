#!/bin/bash 
#SBATCH --account=arsef
#SBATCH --job-name="cleanup_90dd_3"
#SBATCH -p ceres
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --cpus-per-task=8
#SBATCH --mem=15G
#SBATCH -t 24:00:00
#SBATCH --mail-user=bma66@cornell.edu
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH -o /project/arsef/projects/hypo_ml_2025/logs/%x.%j.%N.o
#SBATCH -e /project/arsef/projects/hypo_ml_2025/logs/%x.%j.%N.e

cd /90daydata/arsef/ips_output/

for dir in ./ips_*; do
    find "$dir" -maxdepth 1 -name "*.faa" -type f -print #change print to delete to remove .faa files

    if [ -d "$dir/temp" ]; then
        rm -r "$dir/temp"
    fi
done
