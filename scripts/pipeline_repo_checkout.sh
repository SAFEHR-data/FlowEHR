#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset
# Uncomment this line to see each command for debugging (careful: this will show secrets!)
# set -o xtrace

ROOT=/workspaces/FlowEHR
PIPELINE_DIR="${ROOT}"/transform/pipelines

# shellcheck disable=SC1090
source "${ROOT}/scripts/load_env.sh"

pushd "${PIPELINE_DIR}" > /dev/null
export IFS=";"
for repo in $REPOSITORIES; do
  # Name for the directory to check out to,
  # e.g. git@github.com:UCLH-Foundry/Data-Pipeline.git becomes Data-Pipeline 
  dir_name=$(basename "${repo}" | sed -e 's/\.git$//')

  # If the directory with checked out repo already exists, remove it
  if [ -d "${dir_name}" ]; then
    rm -rf "${dir_name}"
  fi

  git clone "${repo}"
done

popd > /dev/null