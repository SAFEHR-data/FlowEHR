terraform {

  # Pass arguments to terraform commands
  extra_arguments "auto_approve" {
    commands = [ "plan" ]
    arguments = [ "-auto-approve" ]
  }
}

generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
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
