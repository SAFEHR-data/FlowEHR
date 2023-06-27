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
#  limitations under the License.

set -o errexit
set -o pipefail
set -o nounset

WAIT_TIME="${WAIT_TIME:=30}"  # seconds
NUMBER_OF_RETRYS="${NUMBER_OF_RETRYS:=3}"

for ((i=1; i<="$NUMBER_OF_RETRYS"; i++)); do
  if "$@"; then
    break
  fi
  if [[ "$i" -lt "$NUMBER_OF_RETRYS" ]]; then
    echo "Command failed. Retrying in ${WAIT_TIME} seconds..."
    sleep "$WAIT_TIME"
  else
    echo "Failed with the maximum number of retrys: ${NUMBER_OF_RETRYS}"
    exit 1
  fi
done
