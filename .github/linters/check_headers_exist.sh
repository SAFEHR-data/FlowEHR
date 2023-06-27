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

for ext in ".tf" ".yml" ".sh" "Dockerfile" ".py" ".hcl" ".js"
do
    # shellcheck disable=SC2044
    for path in $(find . -type f -name "*$ext")
    do
        if git check-ignore -q "$path" ; then  # Ignore any .gitignored files
            continue
        fi
        if [[ "$path" == *".lock.hcl"* ]]; then # Ignore any lock files
            continue
        fi

        if ! grep -q "Copyright" "$path"; then
            echo -e "\n\e[31m»»» ⚠️  No copyright/license header in $path"
            exit 1
        fi
    done || exit 1
done
