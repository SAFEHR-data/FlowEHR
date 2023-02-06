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
#  limitations under the License.

# Run this script as follows:
# DATABRICKS_URI=https://<your-databricks-instance>.azuredatabricks.net ./setup_cli.sh

set +e

# Resource ID here is the same for all Databricks workspaces
# (see https://learn.microsoft.com/en-us/azure/databricks/dev-tools/api/latest/aad/service-prin-aad-token)
token_response=$(az account get-access-token --resource 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d)
DATABRICKS_AAD_TOKEN=$(jq .accessToken -r <<< "$token_response")
export DATABRICKS_AAD_TOKEN

databricks configure --host "${DATABRICKS_URI}" --aad-token
