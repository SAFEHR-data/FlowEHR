#!/bin/bash
# shellcheck disable=SC2001
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

module="$1"
resource_abbreviation="$2"

if echo "management core transform serve" | grep -v -q "${module}"; then
    echo "Unrecognised module: ${module}. Must be e.g. core"
    exit 1
fi

if echo "rg str" | grep -v -q "$resource_abbreviation"; then
    echo "Unrecognised resource abbreviation: ${resource_abbreviation}"
    exit 1
fi

case "$module" in
management)
    suffix="mgmt";;
*)
    suffix=$module
esac

case "$resource_abbreviation" in
rg)
    echo "${PREFIX}-${ENVIRONMENT}-rg-${suffix}"
    exit;;
str)
    str_name="${PREFIX}-${ENVIRONMENT}-str-${suffix}"
    str_name=$( echo "$str_name" | sed 's/-//g')             # Remove hyphens
    str_name=$( echo "$str_name" | sed -e 's/\(.*\)/\L\1/')  # Lowercase
    tail -c 24 <<<"$str_name"                                # Truncate to <25 characters
esac
