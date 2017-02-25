#!/bin/bash

#SBATCH -A iPlant-Collabs
#SBATCH -N 1
#SBATCH -n 4
#SBATCH -t 00:30:00
#SBATCH -p development
#SBATCH -J mulast
#SBATCH --mail-type BEGIN,END,FAIL
#SBATCH --mail-user jklynch@email.arizona.edu

OUT_DIR="$SCRATCH/muscope-last/test"

if [[ -d $OUT_DIR ]]; then
  rm -rf $OUT_DIR
fi

run.sh -q "$SCRATCH/muscope-last/test.fa" -o $OUT_DIR -n 2
