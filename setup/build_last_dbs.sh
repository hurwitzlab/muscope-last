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
#SBATCH -J build-last-dbs
#SBATCH -N 1 
#SBATCH -n 2
#SBATCH -p development
#SBATCH -e build-last-dbs.e%j
#SBATCH -o build-last-dbs.o%j
#SBATCH -t 00:30:00
#          <------ Account String ----->
# <--- (Use this ONLY if you have MULTIPLE accounts) --->
#SBATCH -A TG-ASC160037
#------------------------------------------------------

module load launcher
module load gcc/4.9.3

export LAUNCHER_PLUGIN_DIR=$TACC_LAUNCHER_DIR/plugins
export LAUNCHER_RMI=SLURM
export LAUNCHER_JOB_FILE=$WORK/cyverse-apps/muscope-last/setup/jobfile
 
$TACC_LAUNCHER_DIR/paramrun

