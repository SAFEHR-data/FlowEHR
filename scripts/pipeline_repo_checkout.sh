#!/bin/bash
set -o errexit
set -o pipefail
# Uncomment this line to see each command for debugging (careful: this will show secrets!)
set -o xtrace

ROOT=/workspaces/FlowEHR
PIPELINE_DIR="${ROOT}"/transform/pipelines

if [[ -n "${ORG_GH_TOKEN}" ]]; then
  echo "${ORG_GH_TOKEN}" | gh auth login --with-token
else
  gh auth login # Interactive login
fi
pushd "${PIPELINE_DIR}" > /dev/null

while IFS=$'\n' read -r repo _; do
  echo "Repo:  $repo"
  # Name for the directory to check out to,
  # e.g. git@github.com:UCLH-Foundry/Data-Pipeline.git becomes Data-Pipeline 
  # If the directory with checked out repo already exists, remove it
  dir_name=$(basename "${repo}" | sed -e 's/\.git$//')
  if [ -d "${dir_name}" ]; then
    rm -rf "${dir_name}"
  fi

  gh repo clone "${repo}"
done < <(yq e -I=0 '.repositories[]'  ${ROOT}/config.transform.yaml)

popd > /dev/null