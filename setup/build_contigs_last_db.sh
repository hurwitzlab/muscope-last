#!/bin/bash
#SBATCH -J build-contigs-last-dbs
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -p skx-normal
#SBATCH -e build-contigs-last-dbs.e%j
#SBATCH -o build-contigs-last-dbs.o%j
#SBATCH -t 24:00:00
#SBATCH -A iPlant-Collabs
#SBATCH --mail-type BEGIN,END,FAIL
#SBATCH --mail-user jklynch@email.arizona.edu
#------------------------------------------------------

module load tacc-singularity

OHANA_HOT_DIR=/work/05066/imicrobe/iplantc.org/data/ohana/HOT
LAST_DB_DIR=/work/05066/imicrobe/iplantc.org/data/ohana/last

ls -l $LAST_DB_DIR
rm -f $LAST_DB_DIR/HOT_proteins*
singularity exec ../stampede2/muscope-last.img lastdb -cR01 -P 0 -v $LAST_DB_DIR/HOT_contigs $OHANA_HOT_DIR/HOT*/contigs.fa
ls -l $LAST_DB_DIR
