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

locals {
  terraform_version = "1.3.7"
  azure_provider    = <<EOF
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = var.accesses_real_data
    }
    key_vault {
      # Only purge on destroy when purge protection is not enabled
      purge_soft_delete_on_destroy               = !var.accesses_real_data
      purge_soft_deleted_secrets_on_destroy      = !var.accesses_real_data
      purge_soft_deleted_certificates_on_destroy = !var.accesses_real_data
      purge_soft_deleted_keys_on_destroy         = !var.accesses_real_data
      # When recreating an environment, recover any previously soft deleted secrets if in prod
      recover_soft_deleted_key_vaults   = var.accesses_real_data
      recover_soft_deleted_secrets      = var.accesses_real_data
      recover_soft_deleted_certificates = var.accesses_real_data
      recover_soft_deleted_keys         = var.accesses_real_data
    }
  }
}
EOF

  required_provider_azure = <<EOF
azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.47.0"
    }
EOF

  required_provider_azuread = <<EOF
azuread = {
      source  = "hashicorp/azuread"
      version = "2.35.0"
    }
EOF

  required_provider_random = <<EOF
random = {
      source = "hashicorp/random"
      version = "3.4.3"
    }
EOF

  required_provider_databricks = <<EOF
databricks = {
      source = "databricks/databricks"
      version = "1.9.1"
    }
EOF

  required_provider_external = <<EOF
external = {
      source = "hashicorp/external"
      version = "2.3.1"
    }
EOF

  required_provider_null = <<EOF
null = {
      source = "hashicorp/null"
      version = "3.2.1"
    }
EOF

  required_provider_github = <<EOF
github = {
      source  = "integrations/github"
      version = "5.18.3"
    }
EOF

  required_provider_time = <<EOF
time = {
      source = "hashicorp/time"
      version = "0.9.1"
    }
EOF

  required_provider_http = <<EOF
http = {
      source = "hashicorp/http"
      version = "3.2.1"
    }
EOF

  required_provider_local = <<EOF
local = {
  source = "hashicorp/local"
  version = "2.4.0"
}
EOF

  required_provider_azapi = <<EOF
azapi = {
  source = "Azure/azapi"
  version = "1.5.0"
}
EOF
}
