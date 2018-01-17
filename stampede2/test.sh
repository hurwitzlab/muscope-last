#!/bin/bash

#SBATCH -A iPlant-Collabs
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -t 02:00:00
#SBATCH -p normal
#SBATCH -J muscope-last-test
#SBATCH --mail-type BEGIN,END,FAIL
#SBATCH --mail-user jklynch@email.arizona.edu

OUT_DIR="$SCRATCH/muscope-last/test"

if [[ -d $OUT_DIR ]]; then
  rm -rf $OUT_DIR
fi

run.sh -q "$SCRATCH/muscope-last/test.fa" -o $OUT_DIR
