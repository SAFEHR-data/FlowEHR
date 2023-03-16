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
GITHUB_TOKEN="${ORG_GITHUB_TOKEN:-}" # May be unset
ENVIRONMENT="${ENVIRONMENT:=local}"
CONFIG_PATH="${SCRIPT_DIR}/../config.yaml"

# Get either the environment-specific config file if contains repositories, otherwise fall back to core config
env_config="config.${ENVIRONMENT}.yaml"
env_config_path="$SCRIPT_DIR/../$env_config"
if [ -f "$env_config_path" ]; then
  if [[ $(yq '.transform | has("repositories")' "$env_config") == "true" ]]; then
    echo "Transform repositories config found in $env_config"
    CONFIG_PATH="$env_config_path"
  else
    echo "No transform repositories config found in $env_config. Using root config.yaml"
  fi
else
  echo "No environment-specific config file found (searched for $env_config_path). Using root config.yaml"
fi

if [[ -n "${GITHUB_TOKEN}" ]]; then
  GIT_COMMAND="GH_TOKEN=${GITHUB_TOKEN} git -c credential.helper= -c credential.helper='!gh auth git-credential'"
else
  GIT_COMMAND="git"
fi

pushd "${PIPELINE_DIR}" > /dev/null

readarray repositories < <(yq e -o=j -I=0 '.transform.repositories[]' "${CONFIG_PATH}" )
for repository in "${repositories[@]}"; do 
  url=$(yq '.url' - <<< "${repository}" )

  dir_name=$(basename "${url}" | sed -e 's/\.git$//')
  if [[ -d "${dir_name}" ]]; then
    echo "Repo already exists, skipping"
  else
    eval "${GIT_COMMAND} clone ${url}"
    if [[ $(yq '. | has("sha")' <<< "${repository}") == "true" ]]; then
      sha=$(yq '.sha' - <<< "${repository}" )
      pushd "${dir_name}"
      git checkout "${sha}"
      popd > /dev/null
    fi
  fi
done

popd > /dev/null
