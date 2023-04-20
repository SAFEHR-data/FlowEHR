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

include "shared" {
  path = "${get_repo_root()}/shared.hcl"
}

locals {
  providers = read_terragrunt_config("${get_repo_root()}/providers.hcl")
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
    ${local.providers.locals.required_provider_random}
    ${local.providers.locals.required_provider_http}
  }
}
EOF
}

inputs = {
  ci_vnet_name    = get_env("CI_PEERING_VNET", "")
  ci_rg_name      = get_env("CI_RESOURCE_GROUP", "")
  suffix_override = get_env("SUFFIX_OVERRIDE", "")
}
