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

generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  backend "azurerm" {
    resource_group_name  = "${get_env("PREFIX")}-${get_env("ENVIRONMENT")}-rg-mgmt"
    storage_account_name = "${get_env("PREFIX")}${get_env("ENVIRONMENT")}strmgmt"
    container_name       = "tfstate"
    key                  = "bootstrap.tfstate"
  }
}
EOF
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
  tags = {
    environment = get_env("ENVIRONMENT")
  }
}
