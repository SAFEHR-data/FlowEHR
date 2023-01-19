#!/bin/bash
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
