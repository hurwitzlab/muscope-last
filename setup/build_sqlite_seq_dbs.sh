#!/bin/bash
#
# Simple SLURM script for submitting multiple serial
# jobs (e.g. parametric studies) using a script wrapper
# to launch the jobs.
#
# To use, build the launcher executable and your
# serial application(s) and place them in your WORKDIR
# directory.  Then, edit the CONTROL_FILE to specify 
# each executable per process.
#-------------------------------------------------------
#-------------------------------------------------------
# 
#         <------ Setup Parameters ------>
#
#SBATCH -J build-sqlite-seq-dbs
#SBATCH -N 1 
#SBATCH -n 2
#SBATCH -p development
#SBATCH -e build-sqlite-seq-dbs.e%j
#SBATCH -o build-sqlite-seq-dbs.o%j
#SBATCH -t 00:30:00
#          <------ Account String ----->
# <--- (Use this ONLY if you have MULTIPLE accounts) --->
#SBATCH -A iPlant-Collabs
#------------------------------------------------------

module load python3
export LAUNCHER_DIR=~/src/launcher

SQLITE_DB_JOBS="$$.sqlite.db.jobs"
cat /dev/null > $SQLITE_DB_JOBS

HOT_DIR=/work/03137/kyclark/ohana/HOT/HOT224*
OUT_DIR=$SCRATCH/ohana/seq_db
mkdir -p $OUTDIR

SEQ_FILES=$(mktemp)
find $HOT_DIR -size +0c -name contigs.fa > $SEQ_FILES
find $HOT_DIR -size +0c -name genes.fna >> $SEQ_FILES
find $HOT_DIR -size +0c -name proteins.faa >> $SEQ_FILES
while read FILE; do
  BASENAME=$(basename $FILE '.tab')
  echo "Building SQLite db with $FILE"
  echo "python scripts/build_sqlite_seq_db.py -i \"$FILE\" -o \"${OUT_DIR}/ohana\"" >> $SQLITE_DB_JOBS
done < $SEQ_FILES

echo "Starting launcher"
echo "  SLURM_JOB_NUM_NODES=$SLURM_JOB_NUM_NODES"
echo "  SLURM_NTASKS=$SLURM_NTASKS"
echo "  SLURM_JOB_CPUS_PER_NODE=$SLURM_JOB_CPUS_PER_NODE"
echo "  SLURM_TASKS_PER_NODE=$SLURM_TASKS_PER_NODE"

export LAUNCHER_DIR="$HOME/src/launcher"
export LAUNCHER_PLUGIN_DIR=$LAUNCHER_DIR/plugins
export LAUNCHER_WORKDIR=.
export LAUNCHER_RMI=SLURM
export LAUNCHER_NHOSTS=$SLURM_JOB_NUM_NODES
export LAUNCHER_NPROCS=$SLURM_TASKS_PER_NODE
export LAUNCHER_PPN=$SLURM_TASKS_PER_NODE
export LAUNCHER_SCHED=dynamic

export LAUNCHER_JOB_FILE=$SQLITE_DB_JOBS
export LAUNCHER_NJOBS=$(wc -l $SQLITE_DB_JOBS)

echo "  LAUNCHER_NJOBS=$LAUNCHER_NJOBS"
echo "  LAUNCHER_NHOSTS=$LAUNCHER_NHOSTS"
echo "  LAUNCHER_NPROCS=$LAUNCHER_NPROCS"
echo "  LAUNCHER_PPN=$LAUNCHER_PPN"

$LAUNCHER_DIR/paramrun
echo "Ended launcher"
