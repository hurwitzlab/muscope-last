#!/bin/bash
#SBATCH -J build-contigs-last-dbs
#SBATCH -N 1 
#SBATCH -n 1
#SBATCH -p normal
#SBATCH -e build-contigs-last-dbs.e%j
#SBATCH -o build-contigs-last-dbs.o%j
#SBATCH -t 24:00:00
#SBATCH -A iPlant-Collabs
#SBATCH --mail-type BEGIN,END,FAIL
#SBATCH --mail-user jklynch@email.arizona.edu
#------------------------------------------------------

module load gcc/4.9.3

ls -l $WORK/ohana_lastdb/
rm $WORK/ohana_lastdb/HOT_contigs*
lastdb -cR01 -v $WORK/ohana_lastdb/HOT_contigs /work/03137/kyclark/ohana/HOT/HOT*/contigs.fa
ls -l $WORK/ohana_lastdb/

