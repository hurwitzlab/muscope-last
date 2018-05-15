#!/bin/bash

# Author: Ken Youens-Clark <kyclark@email.arizona.edu>
# Author: Joshua Lynch <jklynch@email.arizona.edu>

echo "command line arguments: $@"

module load tacc-singularity

# the next two lines load 'testing' version
# of the TACC launcher
module use /scratch/01255/siliu/modulefiles
module load launcher/3.2

IMICROBE_DATA_DIR=/work/05066/imicrobe/iplantc.org/data

LAST_IMG=/work/05066/imicrobe/singularity/muscope-last-0.0.4.img

QUERY=""
OUT_DIR=$(pwd)  ##"$BIN"
# SKX nodes have 48 cores
# let two tasks run at once and give each task 24 cores
NUM_THREADS=24
# this is the default LAST database
LAST_DB_DIR="$IMICROBE_DATA_DIR/ohana/last"

# is the singularity image here?
ls -l

set -u

function lc() {
  wc -l "$1" | cut -d ' ' -f 1
}

function HELP() {
  printf "Usage:\n  %s -q QUERY -o OUT_DIR -d LAST_DB_DIR\n\n" $(basename $0)

  echo "Required arguments:"
  echo " -q QUERY"
  echo
  echo "Options:"
  echo
  echo " -p PCT_ID ($PCT_ID)"
  echo " -o OUT_DIR ($OUT_DIR)"
  echo " -n NUM_THREADS ($NUM_THREADS)"
  echo " -d path to LAST database"
  echo
  exit 0
}

if [[ $# -eq 0 ]]; then
  HELP
fi

while getopts :o:n:p:q:d:h OPT; do
  case $OPT in
    h)
      HELP
      ;;
    n)
      NUM_THREADS="$OPTARG"
      ;;
    o)
      OUT_DIR="$OPTARG"
      ;;
    p)
      PCT_ID="$OPTARG"
      ;;
    q)
      QUERY="$OPTARG"
      ;;
    d)
      LAST_DB_DIR="$OPTARG"
      ;;
    :)
      echo "Error: Option -$OPTARG requires an argument."
      exit 1
      ;;
    \?)
      echo "Error: Invalid option: -${OPTARG:-""}"
      exit 1
  esac
done

echo "LAST_DB_DIR: \"$LAST_DB_DIR\""

if [[ $NUM_THREADS -lt 1 ]]; then
  echo "NUM_THREADS \"$NUM_THREADS\" cannot be less than 1"
  exit 1
fi

if [[ -d "$OUT_DIR" ]]; then
  mkdir -p "$OUT_DIR"
fi

LAST_OUT_DIR="$OUT_DIR/last-out"
if [[ ! -d "$LAST_OUT_DIR" ]]; then
  mkdir -p "$LAST_OUT_DIR"
fi

INPUT_FILES=$(mktemp)
if [[ -d $QUERY ]]; then
  find "$QUERY" -type f > "$INPUT_FILES"
else
  echo "$QUERY" > $INPUT_FILES
fi
NUM_INPUT=$(lc "$INPUT_FILES")

if [[ $NUM_INPUT -lt 1 ]]; then
  echo "No input files found"
  exit 1
fi

# Here is a place for fasplit.py to ensure not too
# many sequences in each query.
# is it necessary to split the query since we have multithreading?

if [[ ! -d "$LAST_DB_DIR" ]]; then
  echo "LAST_DB_DIR \"$LAST_DB_DIR\" does not exist."
  exit 1
fi

#LAST_DB_DIR="$IMICROBE_DATA_DIR/ohana/last"
LAST_ARGS="-v -f BlastTab+ -P$NUM_THREADS"
LAST_PARAM="$$.last.param"

cat /dev/null > $LAST_PARAM # make sure it's empty

i=0
while read INPUT_FILE; do
  BASENAME=$(basename "$INPUT_FILE")

  let i++
  printf "%3d: %s\n" "$i" "$BASENAME"
  EXT="${BASENAME##*.}"
  TYPE="unknown"
  if [[ $EXT == 'fa'    ]] || \
     [[ $EXT == 'fna'   ]] || \
     [[ $EXT == 'fas'   ]] || \
     [[ $EXT == 'fasta' ]] || \
     [[ $EXT == 'ffn'   ]];
  then
    TYPE="dna"
  elif [[ $EXT == 'faa' ]]; then
    TYPE="prot"
  elif [[ $EXT == 'fra' ]]; then
    TYPE="rna"
  fi

  LAST_TO_DNA=""
  if [[ $TYPE == 'dna' ]]; then
    LAST_TO_DNA="singularity exec ${LAST_IMG} lastal"
  #elif [[ $TYPE == 'prot' ]]; then
  #  LAST_TO_DNA='lastal'
  else
    echo "Cannot LAST $BASENAME to DNA (not DNA)"
  fi

  if [[ ${#LAST_TO_DNA} -gt 0 ]]; then
    echo "$LAST_TO_DNA $LAST_ARGS $LAST_DB_DIR/HOT_contigs $INPUT_FILE > $LAST_OUT_DIR/$BASENAME-contigs.tab" >> $LAST_PARAM
    echo "$LAST_TO_DNA $LAST_ARGS $LAST_DB_DIR/HOT_genes   $INPUT_FILE > $LAST_OUT_DIR/$BASENAME-genes.tab" >> $LAST_PARAM
  fi

  LAST_TO_PROT=""
  if [[ $TYPE == 'dna' ]]; then
    LAST_TO_PROT="singularity exec ${LAST_IMG} lastal -F15"
  elif [[ $TYPE == 'prot' ]]; then
    LAST_TO_PROT="singularity exec ${LAST_IMG} lastal"
  else
    echo "Cannot LAST $BASENAME to PROT (not DNA or prot)"
  fi

  if [[ ${#LAST_TO_PROT} -gt 0 ]]; then
    echo "$LAST_TO_PROT $LAST_ARGS $LAST_DB_DIR/HOT_proteins $INPUT_FILE > $LAST_OUT_DIR/$BASENAME-proteins.tab" >> $LAST_PARAM
  fi
done < "$INPUT_FILES"
rm "$INPUT_FILES"

echo "Starting launcher for LAST"
echo "  NUM_THREADS=$NUM_THREADS"
echo "  SLURM_JOB_NUM_NODES=$SLURM_JOB_NUM_NODES"
echo "  SLURM_NTASKS=$SLURM_NTASKS"
echo "  SLURM_JOB_CPUS_PER_NODE=$SLURM_JOB_CPUS_PER_NODE"
echo "  SLURM_TASKS_PER_NODE=$SLURM_TASKS_PER_NODE"

export LAUNCHER_DIR=${TACC_LAUNCHER_DIR}
export LAUNCHER_PLUGIN_DIR=$LAUNCHER_DIR/plugins
#export LAUNCHER_WORKDIR=$BIN
export LAUNCHER_RMI=SLURM
export LAUNCHER_JOB_FILE=${LAST_PARAM}
# run two tasks at once
export LAUNCHER_PPN=2
export LAUNCHER_SCHED=dynamic

echo "  LAUNCHER_PPN=${LAUNCHER_PPN}"

${LAUNCHER_DIR}/paramrun
echo "Ended launcher for LAST"

rm ${LAST_PARAM}

#
# Now we need to add Eggnog (and eventually Pfam, KEGG, etc.)
# annotations to the "*-genes.tab" files.
#
ANNOT_PARAM="$$.annot.param"
cat /dev/null > $ANNOT_PARAM

GENE_PROTEIN_HITS=$(mktemp)
find $LAST_OUT_DIR -size +0c -name \*-genes.tab > $GENE_PROTEIN_HITS
find $LAST_OUT_DIR -size +0c -name \*-proteins.tab >> $GENE_PROTEIN_HITS
while read FILE; do
  BASENAME=$(basename $FILE '.tab')
  echo "Annotating $FILE"
  echo "singularity exec ${LAST_IMG} python3 /app/scripts/annotate.py -l \"$FILE\" -a \"${IMICROBE_DATA_DIR}/ohana/sqlite\" -o \"${OUT_DIR}/annotations\"" >> $ANNOT_PARAM
done < $GENE_PROTEIN_HITS

echo "Starting launcher for annotation"
export LAUNCHER_JOB_FILE=$ANNOT_PARAM

# one core per task
export LAUNCHER_PPN=48
export LAUNCHER_SCHED=dynamic

echo "  LAUNCHER_PPN=$LAUNCHER_PPN"

$LAUNCHER_DIR/paramrun
echo "Ended launcher for annotation"

rm $ANNOT_PARAM

#
# Now we need to extract the Ohana sequences for the LAST hits.
#
EXTRACTSEQS_PARAM="$$.extractseqs.param"
cat /dev/null > $EXTRACTSEQS_PARAM

LAST_HITS=$(mktemp)
find $LAST_OUT_DIR -size +0c -name \*.tab > $LAST_HITS
while read FILE; do
  BASENAME=$(basename $FILE '.tab')
  echo "Extracting Ohana sequences of LAST hits for $FILE"
  echo "singularity exec ${LAST_IMG} python3 /app/scripts/extractseqs.py \"$FILE\"  \"${IMICROBE_DATA_DIR}/ohana/HOT\" \"${OUT_DIR}/ohana_hits\"" >> $EXTRACTSEQS_PARAM
done < $LAST_HITS

echo "Starting launcher for Ohana sequence extraction"
# one thread per task here
export LAUNCHER_NJOBS=$(lc $EXTRACTSEQS_PARAM)
export LAUNCHER_JOB_FILE=$EXTRACTSEQS_PARAM

# one core per task
export LAUNCHER_PPN=48
export LAUNCHER_SCHED=dynamic
echo "  LAUNCHER_PPN=$LAUNCHER_PPN"

$LAUNCHER_DIR/paramrun
echo "Ended launcher for Ohana sequence extraction"
rm "$EXTRACTSEQS_PARAM"

#
# Finally add a header row to the LAST output files.
#
INSERTHDR_PARAMS="$$.inserthdr.param"
cat /dev/null > $INSERTHDR_PARAMS

LAST_HITS=$(mktemp)
find $LAST_OUT_DIR -size +0c -name \*.tab > $LAST_HITS
while read FILE; do
  BASENAME=$(basename $FILE '.tab')
  echo "Inserting header in LAST output $FILE"
  echo "singularity exec ${LAST_IMG} python3 /app/scripts/inserthdr.py \"$FILE\"" >> $INSERTHDR_PARAMS
done < $LAST_HITS

echo "Starting launcher for LAST header insertion"
# one thread per task here
export LAUNCHER_NJOBS=$(lc $INSERTHDR_PARAMS)
export LAUNCHER_JOB_FILE=$INSERTHDR_PARAMS

# one core per task
export LAUNCHER_PPN=48
export LAUNCHER_SCHED=dynamic
echo "  LAUNCHER_PPN=$LAUNCHER_PPN"

$LAUNCHER_DIR/paramrun
echo "Ended launcher for LAST header insertion"
rm "$INSERTHDR_PARAMS"
