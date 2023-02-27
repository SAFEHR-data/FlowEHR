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

echo "Registering GH runner.."

# See: https://docs.github.com/en/rest/actions/self-hosted-runners#create-a-registration-token-for-a-repository
REGISTRATION_TOKEN=$(curl \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${GITHUB_RUNNER_TOKEN}" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/repos/${GITHUB_REPOSITORY}/actions/runners/registration-token" | awk '/token/ { gsub(/[",]/,""); print $2}')

if [ "${REGISTRATION_TOKEN}" != "" ]; then
  echo "Created registration token"
else
  echo "Failed to obtain a registration token. Check the scope of \$GITHUB_RUNNER_TOKEN"
  exit 1
fi

# See https://docs.github.com/en/actions/hosting-your-own-runners/about-self-hosted-runners
# The GH_RUNNER_NAME must be unique within the repositry.
/tmp/actions-runner/config.sh --ephemeral \
    --url "https://github.com/${GITHUB_REPOSITORY}" \
    --token "${REGISTRATION_TOKEN}" \
    --name "${GITHUB_RUNNER_NAME}" \
    --labels "${GITHUB_RUNNER_NAME}" \
    --unattended \
    --disableupdate

/tmp/actions-runner/run.sh
