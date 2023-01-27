#!/bin/bash
# Run this script as follows:
# DATABRICKS_URI=https://adb-177476396091008.8.azuredatabricks.net ./setup_cli.sh
# You need to have databricks CLI already installed

set +e

# Resource ID here is the same for all Databricks workspaces
# (see https://learn.microsoft.com/en-us/azure/databricks/dev-tools/api/latest/aad/service-prin-aad-token)
token_response=$(az account get-access-token --resource 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d)
DATABRICKS_AAD_TOKEN=$(jq .accessToken -r <<< "$token_response")
export DATABRICKS_AAD_TOKEN

databricks configure --host "${DATABRICKS_URI}" --aad-token
