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

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# If suffix env var isn't set (i.e. by build agent), use bootstrap output
SUFFIX=${SUFFIX_OVERRIDE:="$(cd "${SCRIPT_DIR}"/../bootstrap/local && terragrunt output naming_suffix | tr -d '"')"}

az group list -o table | while read -r line ; do

  if echo "$line" | grep -q "${SUFFIX}"; then
    rg_name=$(echo "$line" | awk '{print $1;}')

    # Skip databricks-managed rgs as these are deleted automatically
    if [[ "$line" != rg-dbks* ]]; then
      echo "Deleting ${rg_name}..."
      az group delete --resource-group "$rg_name" --yes
    fi
  fi

done
