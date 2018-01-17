#!/bin/bash
#
#-------------------------------------------------------
#SBATCH -J build-sqlite-seq-dbs
#SBATCH -N 1
#SBATCH -n 16
#SBATCH -p normal
#SBATCH -e build-sqlite-seq-dbs.e%j
#SBATCH -o build-sqlite-seq-dbs.o%j
#SBATCH -t 01:00:00
#SBATCH -A iPlant-Collabs
#SBATCH --mail-type BEGIN,END,FAIL
#SBATCH --mail-user jklynch@email.arizona.edu
#------------------------------------------------------

export LAUNCHER_DIR=~/src/launcher

HOT_DIR=/work/03137/kyclark/ohana/HOT
OUT_DIR=$SCRATCH/ohana/seq_db
mkdir -p $OUT_DIR

SQLITE_DB_JOBS="${SLURM_JOB_ID}.sqlite.db.jobs"
cat /dev/null > $SQLITE_DB_JOBS

SEQ_FILES=$(mktemp)
find $HOT_DIR -size +0c -name contigs.fa > $SEQ_FILES
find $HOT_DIR -size +0c -name genes.fna >> $SEQ_FILES
find $HOT_DIR -size +0c -name proteins.faa >> $SEQ_FILES
while read FILE; do
  BASENAME=$(basename $FILE '.tab')
  echo "Building SQLite db with $FILE"
  echo "python scripts/build_sqlite_seq_db.py -i \"$FILE\" -o \"${OUT_DIR}\"" >> $SQLITE_DB_JOBS
done < $SEQ_FILES

echo "Starting launcher"
echo "  SLURM_JOB_NUM_NODES=$SLURM_JOB_NUM_NODES"
echo "  SLURM_NTASKS=$SLURM_NTASKS"
echo "  SLURM_JOB_CPUS_PER_NODE=$SLURM_JOB_CPUS_PER_NODE"
echo "  SLURM_TASKS_PER_NODE=$SLURM_TASKS_PER_NODE"

BIN=$( cd "$( dirname "%0" )" $$ pwd)
echo " BIN dir: $BIN"

export LAUNCHER_DIR="$HOME/src/launcher"
export LAUNCHER_PLUGIN_DIR=$LAUNCHER_DIR/plugins
export LAUNCHER_WORKDIR=$BIN
export LAUNCHER_RMI=SLURM
export LAUNCHER_NHOSTS=$SLURM_JOB_NUM_NODES
export LAUNCHER_NPROCS=$SLURM_TASKS_PER_NODE
export LAUNCHER_PPN=$SLURM_TASKS_PER_NODE
export LAUNCHER_SCHED=dynamic

export LAUNCHER_JOB_FILE=$SQLITE_DB_JOBS
export LAUNCHER_NJOBS=$(wc -l < $SQLITE_DB_JOBS)

echo "  LAUNCHER_NJOBS=$LAUNCHER_NJOBS"
echo "  LAUNCHER_NHOSTS=$LAUNCHER_NHOSTS"
echo "  LAUNCHER_NPROCS=$LAUNCHER_NPROCS"
echo "  LAUNCHER_PPN=$LAUNCHER_PPN"

$LAUNCHER_DIR/paramrun
echo "Ended launcher"
