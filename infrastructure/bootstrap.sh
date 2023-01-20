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

while getopts ":d" option; do
   case $option in
      d) # destroy bootstrap rg
        echo "Destroying management resource group..."
        az group delete --resource-group $MGMT_RG --yes
        echo "Management rg destroyed."
        exit;;
   esac
done

echo "Creating management resource group..."
az group create --resource-group "$MGMT_RG" --location "$LOCATION"

echo "Creating management storage account..."
az storage account create --resource-group "$MGMT_RG" --name "$MGMT_STORAGE" --sku Standard_LRS --encryption-services blob

echo "Creating blob container for TF state..."
az storage container create --name "$STATE_CONTAINER" --account-name "$MGMT_STORAGE" --auth-mode login -o table

echo "Creating management container registry..."
az acr create --resource-group "$MGMT_RG" --name "$MGMT_ACR" --sku Standard

echo "Bootstrapping complete."
