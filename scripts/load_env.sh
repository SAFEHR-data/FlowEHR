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

# Get IP address for "local" deployments
if [[ "${LOCAL_MODE}" == "true" ]];
then
    echo "Local Mode: TRUE"
    if [[ -z "${DEPLOYER_IP_ADDRESS+x}" ]];
    then
        echo "No IP address assigned in config, getting client IP and setting in ENV"
        this_ip="$(curl -s 'https://api64.ipify.org')"
        export DEPLOYER_IP_ADDRESS="${this_ip}"
    else
        echo "Have IP address from config.yaml"
    fi
    echo "IP Address: ${DEPLOYER_IP_ADDRESS}"
else
    echo "Local Mode: FALSE"
fi

CORE_ADDRESS_SPACE=$(PYTHONHASHSEED=0 "${SCRIPT_DIR}/core_address_space.py")
echo "Using core address space: $CORE_ADDRESS_SPACE"
export CORE_ADDRESS_SPACE

# Export Terraform state vars
# TODO: where do we get these from now?
export MGMT_RG="rg-mgmt-${NAMING_SUFFIX}"
export MGMT_STORAGE="strgm${TRUNCATED_NAMING_SUFFIX}"
export STATE_CONTAINER="tfstate"

# Get IP address for local deployments
if [[ "${LOCAL_MODE}" == "true" ]];
then
    echo "Local Mode: TRUE"
    if [[ -z "${DEPLOYER_IP_ADDRESS+x}" ]];
    then
        echo "No IP address assigned in config, getting client IP and setting in ENV"
        this_ip="$(curl -s 'https://api64.ipify.org')"
        export DEPLOYER_IP_ADDRESS="${this_ip}"
    else
        echo "Have IP address from config.yaml"
    fi
    echo "IP Address: ${DEPLOYER_IP_ADDRESS}"
else
    echo "Local Mode: FALSE"
fi
