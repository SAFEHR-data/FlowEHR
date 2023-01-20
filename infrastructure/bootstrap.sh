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

mgmt_rg="${PREFIX}-${ENVIRONMENT}-rg-mgmt"
mgmt_acr="${PREFIX}${ENVIRONMENT}acrmgmt"
mgmt_storage="${PREFIX}${ENVIRONMENT}strgmgmt"
state_container="tfstate"

while getopts ":d" option; do
   case $option in
      d) # destroy bootstrap rg
        echo "Destroying management resource group..."
        az group delete --resource-group $mgmt_rg --yes
        echo "Management rg destroyed."
        exit;;
   esac
done

echo "Creating management resource group..."
az group create --resource-group "$mgmt_rg" --location "$LOCATION"

echo "Creating management storage account..."
az storage account create --resource-group "$mgmt_rg" --name "$mgmt_storage" --sku Standard_LRS --encryption-services blob

echo "Creating blob container for TF state..."
az storage container create --name "$state_container" --account-name "$mgmt_storage" --auth-mode login -o table

echo "Creating management container registry..."
az acr create --resource-group "$mgmt_rg" --name "$mgmt_acr" --sku Standard

echo "Bootstrapping complete."
