#!/bin/bash
#SBATCH -J build-genes-last-dbs
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -p skx-normal
#SBATCH -e build-genes-last-dbs.e%j
#SBATCH -o build-genes-last-dbs.o%j
#SBATCH -t 06:00:00
#SBATCH -A iPlant-Collabs
#SBATCH --mail-type BEGIN,END,FAIL
#SBATCH --mail-user jklynch@email.arizona.edu

module load tacc-singularity

OHANA_HOT_DIR=/work/05066/imicrobe/iplantc.org/data/ohana/HOT
LAST_DB_DIR=/work/05066/imicrobe/iplantc.org/data/ohana/last

ls -l $LAST_DB_DIR
rm -f $LAST_DB_DIR/HOT_genes*
singularity exec ../stampede2/muscope-last.img lastdb -cR01 -v $LAST_DB_DIR/HOT_genes $OHANA_HOT_DIR/HOT*/genes.fna
ls -l $LAST_DB_DIR
