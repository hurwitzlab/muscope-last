#!/bin/bash
#SBATCH -J build-test-last-dbs
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -p skx-normal
#SBATCH -e build-test-last-dbs.e%j
#SBATCH -o build-test-last-dbs.o%j
#SBATCH -t 01:00:00
#SBATCH -A iPlant-Collabs
#SBATCH --mail-type BEGIN,END,FAIL
#SBATCH --mail-user jklynch@email.arizona.edu
#------------------------------------------------------

module load tacc-singularity

OHANA_HOT_DIR=/work/05066/imicrobe/iplantc.org/data/ohana/HOT
OHANA_HOT_SAMPLE=$OHANA_HOT_DIR/HOT224_1_0025m
LAST_DB_DIR=/work/05066/imicrobe/iplantc.org/data/ohana/last/test_db

ls -l $LAST_DB_DIR
rm -f $LAST_DB_DIR/HOT224_1_0025m_contigs*
singularity exec ../stampede2/muscope-last.img lastdb -cR01 -P0 -v $LAST_DB_DIR/HOT224_1_0025m_contigs $OHANA_HOT_SAMPLE/contigs.fa
ls -l $LAST_DB_DIR

ls -l $LAST_DB_DIR
rm -f $LAST_DB_DIR/HOT224_1_0025m_genes*
singularity exec ../stampede2/muscope-last.img lastdb -cR01 -P0 -v $LAST_DB_DIR/HOT224_1_0025m_genes $OHANA_HOT_SAMPLE/genes.fa
ls -l $LAST_DB_DIR

ls -l $LAST_DB_DIR
rm -f $LAST_DB_DIR/HOT224_1_0025m_proteins*
singularity exec ../stampede2/muscope-last.img lastdb -cR01 -P0 -v $LAST_DB_DIR/HOT224_1_0025m_proteins $OHANA_HOT_SAMPLE/proteins.fa
ls -l $LAST_DB_DIR
