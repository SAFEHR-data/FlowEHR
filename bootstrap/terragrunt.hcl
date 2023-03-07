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
  providers = read_terragrunt_config("${get_repo_root()}/providers.hcl")
}

terraform {
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
  required_version = "${local.providers.locals.terraform_version}"

  required_providers {
    ${local.providers.locals.required_provider_azure}
    ${local.providers.locals.required_provider_azuread}
  }
}
EOF
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = local.providers.locals.azure_provider
}

remote_state {
  backend = "local"
  config = {}
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

inputs = merge(
  yamldecode(file(find_in_parent_folders("config.yaml"))), {
  tf_in_automation = get_env("TF_IN_AUTOMATION", false)
})
