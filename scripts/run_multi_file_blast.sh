#!/bin/bash -x
# DEFUNCT: This script is no longer used. It was used to run blast on multiple files at once.
#          Use the nextflow pipeline with the `--seedfile` parameter instead.

set -euo pipefail

PROJECT_NAME="MITI-MCB"
DB_NAME="immeDB"
BASE_PATH="s3://maf-users/Daisy_Lee/abricate/20230614"

GENOME_FILE=$1
GENOME_BASE_NAME=$(basename ${GENOME_FILE} .fasta)

## DO NOT MAKE CHANGES BEYOND THIS POINT ##

aws batch submit-job \
    --job-name nf-blast-${GENOME_BASE_NAME} \
    --job-queue priority-maf-pipelines \
    --job-definition nextflow-production \
    --container-overrides command=fischbachlab/nf-blast,\
"--query","${BASE_PATH}/${GENOME_FILE}",\
"--db","${DB_NAME}",\
"--project","${PROJECT_NAME}",\
"--prefix","${GENOME_BASE_NAME}"
