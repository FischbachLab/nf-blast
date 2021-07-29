#!/usr/bin/bash -x

set -euo pipefail
DBTYPE=${1:-"nt"}
LOCAL_DB_HOME="/mnt/efs/databases/Blast/${DBTYPE}"
mkdir -p "${LOCAL_DB_HOME}/db"
docker run --rm \
  -v "${LOCAL_DB_HOME}/db":/blast/blastdb:rw \
  -w /blast/blastdb \
  ncbi/blast \
  update_blastdb.pl --source aws "${DBTYPE}"

echo "Updated on: $(TZ='America/Los_Angeles' date)" >> ${LOCAL_DB_HOME}/${DBTYPE}_updates.txt