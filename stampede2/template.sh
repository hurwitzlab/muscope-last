#!/bin/bash

echo "Started $(date)"

#if [[ ${#OUT_DIR} -gt 1 ]]; then
#  ARGS="$ARGS -o ${OUT_DIR}"
#else
#  ARGS="$ARGS -o $(pwd)"
#fi

# always use current directory for output
sh run.sh ${QUERY} ${PCT_ID} ${__LAST_DB_DIR} -o $(pwd)

echo "Ended $(date)"
