#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

echo "Creating resource group..."
az group create --name $CORE_RESOURCE_GROUP --location $ARM_LOCATION

echo "Creating storage account..."
az storage account create --resource-group $CORE_RESOURCE_GROUP --name $CORE_STORAGE_ACCOUNT --sku Standard_LRS --encryption-services blob

echo "Creating blob container for TF state..."
az storage container create --name $TF_BACKEND_CONTAINER --account-name $CORE_STORAGE_ACCOUNT --auth-mode login -o table
