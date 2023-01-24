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
script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
env_file_path="${script_dir}/../config.yaml"

if [ ! -f "$env_file_path" ]; then
  if [ -z "${TF_IN_AUTOMATION:-}" ]; then
      echo -e "\e[31m»»» 💥 Unable to find config.yaml file. Please create and try again.\e[0m"
      exit 1
  fi
else
  # Validate no duplicate keys in config
  has_dupes=$(yq e '.. | select(. == "*") | {(path | .[-1]): .}| keys' config.yaml | sort| uniq -d)
  if [ -n "${has_dupes:-}" ]; then
    echo -e "\e[31m»»» 💥 There are duplicate keys in your config, please fix and try again!\e[0m"
    exit 1
  fi

  # Validate config schema
  if [[ $(pajv validate -s config_schema.json -d config.yaml) != *valid* ]]; then
    echo -e "\e[31m»»» ⚠️ Your config.yaml is invalid 😥 Please fix the errors and retry."
    exit 1
  fi

  # Get leaf keys yq query
  GET_LEAF_KEYS=".. | select(. == \"*\") | {(path | .[-1]): .}"
  # Map keys to uppercase yq query
  UPCASE_KEYS="with_entries(.key |= upcase)"
  # Prefix keys with TF_VAR_ yq query
  TF_KEYS="with_entries(.key |= \"TF_VAR_\" + .)"
  # Yq query to format the output to be in form: key=value
  FORMAT_FOR_ENV_EXPORT="to_entries| map(.key + \"=\" +  .value)|join(\" \")"

  # Export as UPPERCASE keys env vars
  # shellcheck disable=SC2046
  export $(yq e "$GET_LEAF_KEYS|$UPCASE_KEYS| $FORMAT_FOR_ENV_EXPORT" config.yaml)
  # Export as Terraform keys env vars
  # shellcheck disable=SC2046
  export $(yq e "$GET_LEAF_KEYS|$TF_KEYS| $FORMAT_FOR_ENV_EXPORT" config.yaml)

fi

NAMING_PREFIX=$("${script_dir}/name_prefix.py")
echo "Naming resources with prefixed with: ${NAMING_PREFIX}"

TRUNCATED_NAMING_PREFIX=$("${script_dir}/name_prefix.py" --truncated)
MGMT_RG="${NAMING_PREFIX}-rg-mgmt"
MGMT_STORAGE="${TRUNCATED_NAMING_PREFIX}strm"

export NAMING_PREFIX TRUNCATED_NAMING_PREFIX MGMT_RG MGMT_STORAGE STATE_CONTAINER="tfstate"
