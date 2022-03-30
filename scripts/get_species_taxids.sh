#!/bin/bash -x
set -euo pipefail
TAXID="${1}"

docker run --rm \
    -v "$(pwd):/blast/blastdb_custom":rw \
    -w /blast/blastdb_custom \
    ncbi/blast \
    get_species_taxids.sh -t ${TAXID} > ${TAXID}.txids