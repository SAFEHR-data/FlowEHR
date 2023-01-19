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

core_rg="${PREFIX}-${ENVIRONMENT}-rg-core"
core_storage="${PREFIX}${ENVIRONMENT}strcore"

echo "Boostrapping Terraform..."
echo "Creating resource group..."
az group create --name $core_rg --location $ARM_LOCATION

echo "Creating storage account..."
az storage account create --resource-group $core_rg --name $core_storage --sku Standard_LRS --encryption-services blob

echo "Creating blob container for TF state..."
az storage container create --name $TF_BACKEND_CONTAINER --account-name $core_storage --auth-mode login -o table

echo "Bootstrapping complete."
