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
CONFIG_PATH="${SCRIPT_DIR}/../config.yaml"
GITHUB_TOKEN="${GITHUB_TOKEN:-}" # May be unset

if [[ -n "${GITHUB_TOKEN}" ]]; then
  GIT_COMMAND="GH_TOKEN=${GITHUB_TOKEN} git -c credential.helper= -c credential.helper='!gh auth git-credential'"
else
  GIT_COMMAND="git"
fi

pushd "${PIPELINE_DIR}" > /dev/null

while IFS=$'\n' read -r repo _; do
  # Name for the directory to check out to,
  # e.g. git@github.com:UCLH-Foundry/Data-Pipeline.git becomes Data-Pipeline 
  # If the directory with checked out repo already exists, pull the latest
  dir_name=$(basename "${repo}" | sed -e 's/\.git$//')
  if [ -d "${dir_name}" ]; then
    # This will fail if there are local changes present
    eval "${GIT_COMMAND} pull ${repo}"
  else
    eval "${GIT_COMMAND} clone ${repo}"
  fi

done < <(yq e -I=0 '.transform.repositories[]' "${CONFIG_PATH}")

popd > /dev/null
