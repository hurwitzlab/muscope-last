#!/bin/bash

echo "Started $(date)"
ARGS="-o $(pwd)"

if [[ ${#OUT_DIR} -gt 1 ]]; then
  ARGS="$ARGS -o ${OUT_DIR}"
else
  ARGS="$ARGS -o $(pwd)"
fi

sh run.sh -q ${QUERY} $ARGS
echo "Ended $(date)"
