#!/bin/bash
#SBATCH -J build-proteins-last-dbs
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -p largemem
#SBATCH -e build-proteins-last-dbs.e%j
#SBATCH -o build-proteins-last-dbs.o%j
#SBATCH -t 24:00:00
#SBATCH -A iPlant-Collabs
#SBATCH --mail-type BEGIN,END,FAIL
#SBATCH --mail-user jklynch@email.arizona.edu
#------------------------------------------------------

ls -l $WORK/ohana_lastdb/
rm $WORK/ohana_lastdb/HOT_proteins*
lastdb -cR01 -p -v $WORK/ohana_lastdb/HOT_proteins /work/03137/kyclark/ohana/HOT/HOT*/proteins.faa
ls -l $WORK/ohana_lastdb/
