#!/bin/bash
#  Copyright (c) University College London Hospitals NHS Foundation Trust
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
# limitations under the License.

set -o errexit
set -o pipefail
set -o nounset
# Uncomment this line to see each command for debugging (careful: this will show secrets!)
# set -o xtrace

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PIPELINE_DIR="${SCRIPT_DIR}/../transform/pipelines"
CONFIG_PATH="${SCRIPT_DIR}/../config.transform.yaml"
ORG_GH_TOKEN="${ORG_GH_TOKEN:-}" # May be unset

if [[ -n "${ORG_GH_TOKEN}" ]]; then
  REPO_CHECKOUT_COMMAND="GH_TOKEN=${ORG_GH_TOKEN} git -c credential.helper= -c credential.helper='!gh auth git-credential' clone"
else
  REPO_CHECKOUT_COMMAND="git clone"
fi

pushd "${PIPELINE_DIR}" > /dev/null

while IFS=$'\n' read -r repo _; do
  # Name for the directory to check out to,
  # e.g. git@github.com:UCLH-Foundry/Data-Pipeline.git becomes Data-Pipeline 
  # If the directory with checked out repo already exists, remove it
  dir_name=$(basename "${repo}" | sed -e 's/\.git$//')
  if [ -d "${dir_name}" ]; then
    rm -rf "${dir_name}"
  fi

  eval "${REPO_CHECKOUT_COMMAND}" "${repo}"
done < <(yq e -I=0 '.repositories[]' "${CONFIG_PATH}")

popd > /dev/null
