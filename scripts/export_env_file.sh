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
ENV_FILE_PATH="${SCRIPT_DIR}/../.env"

if [ -f "$ENV_FILE_PATH" ]; then  # if a .env file exits
    if [ "${TF_IN_AUTOMATION:-}" ]; then
        echo "Found .env file while TF_IN_AUTOMATION was true. Expecting set env vars"
        exit 1
    fi

    echo "Exporting varaibles in .env file into envrionment"

    read -ra args < <(grep -v '^#' "$ENV_FILE_PATH" | xargs)
    export "${args[@]}"

elif [ ! "${TF_IN_AUTOMATION:-}" ]; then
  echo "Not in automation but found no .env file"
  exit 1

fi
