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

terraform {
  # Pass arguments to terraform commands
  extra_arguments "auto_approve" {
    commands  = ["apply"]
    arguments = ["-auto-approve"]
  }
}

generate "terraform" {
  path      = "terraform.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = "1.3.7"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.32"
    }
  }
}
EOF
}

remote_state {
  backend = "azurerm"
  config = {
    resource_group_name  = get_env("MGMT_RG")
    storage_account_name = get_env("MGMT_STORAGE")
    container_name       = get_env("STATE_CONTAINER")
    key                  = "${path_relative_to_include()}/terraform.tfstate"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "azurerm" {
  features {
    key_vault {
      # Don't purge on destroy (this would fail due to purge protection being enabled on keyvault)
      purge_soft_delete_on_destroy               = false
      purge_soft_deleted_secrets_on_destroy      = false
      purge_soft_deleted_certificates_on_destroy = false
      purge_soft_deleted_keys_on_destroy         = false
      # When recreating an environment, recover any previously soft deleted secrets - set to true by default
      recover_soft_deleted_key_vaults   = true
      recover_soft_deleted_secrets      = true
      recover_soft_deleted_certificates = true
      recover_soft_deleted_keys         = true
    }
  }
}
EOF
}

# Here we can define additional variables to be inhereted by each module
inputs = {

  location = get_env("LOCATION")
  naming_prefix = get_env("NAMING_PREFIX")
  truncated_naming_prefix = get_env("TRUNCATED_NAMING_PREFIX")

  tags = {
    environment = get_env("ENVIRONMENT")
  }
}
