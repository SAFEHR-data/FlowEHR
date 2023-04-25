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

resource "github_branch" "all" {
  for_each   = local.branches_and_envs
  repository = local.github_repository_name
  branch     = each.key

  depends_on = [
    # Need the codeowners file on each branch
    github_repository_file.codeowners
  ]
}

resource "github_branch_protection" "deployment" {
  for_each            = local.branches_and_envs
  repository_id       = local.github_repository_name
  pattern             = each.value
  allows_deletions    = false
  allows_force_pushes = false

  required_status_checks {
    strict   = var.accesses_real_data
    contexts = ["Code Scanning"]
  }

  required_pull_request_reviews {
    dismiss_stale_reviews           = var.accesses_real_data ? true : var.app_config.branch.dismiss_stale_reviews
    restrict_dismissals             = var.accesses_real_data
    require_code_owner_reviews      = var.accesses_real_data
    required_approving_review_count = var.accesses_real_data ? max(var.app_config.branch.num_of_approvals, 1) : var.app_config.branch.num_of_approvals
  }

  depends_on = [
    github_repository.app
  ]
}

resource "github_repository_environment" "all" {
  for_each    = local.branches_and_envs
  repository  = local.github_repository_name
  environment = each.value

  deployment_branch_policy {
    custom_branch_policies = true
    protected_branches     = false
  }

  # TODO: remove when https://github.com/integrations/terraform-provider-github/pull/1530 is merged
  provisioner "local-exec" {
    command = <<EOF
curl https://api.github.com/repos/${var.github_owner}/${local.github_repository_name}/environments/${each.value}/deployment-branch-policies \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  -H "Authorization: Bearer ${var.github_access_token}" \
  -d '{"name":"${each.key}"}'
EOF
  }

  depends_on = [
    github_repository.app
  ]
}

resource "github_actions_environment_secret" "acr_name" {
  for_each        = local.branches_and_envs
  repository      = local.github_repository_name
  environment     = each.value
  secret_name     = "ACR_NAME"
  plaintext_value = data.azurerm_container_registry.serve.name

  depends_on = [
    github_repository_environment.all
  ]
}

resource "github_actions_environment_secret" "acr_token_username" {
  for_each        = local.branches_and_envs
  repository      = local.github_repository_name
  environment     = each.value
  secret_name     = "ACR_USERNAME"
  plaintext_value = azurerm_container_registry_token.app_access.name

  depends_on = [
    github_repository_environment.all
  ]
}

resource "github_actions_environment_secret" "acr_token_password" {
  for_each        = local.branches_and_envs
  repository      = local.github_repository_name
  environment     = each.value
  secret_name     = "ACR_PASSWORD"
  plaintext_value = azurerm_container_registry_token_password.app_access.password1[0].value

  depends_on = [
    github_repository_environment.all
  ]
}

resource "github_actions_environment_secret" "acr_image_name" {
  for_each        = local.branches_and_envs
  repository      = local.github_repository_name
  environment     = each.value
  secret_name     = "IMAGE_NAME"
  plaintext_value = local.acr_repository

  depends_on = [
    github_repository_environment.all
  ]
}

# If there is a testing environment defined then the SP is needed to bump the deployed
# docker version tag and in the production slot to slot swap
resource "github_actions_environment_secret" "sp_client_id" {
  for_each        = var.app_config.add_testing_slot ? local.branches_and_envs : {}
  repository      = local.github_repository_name
  environment     = each.value
  secret_name     = "ARM_CLIENT_ID"
  plaintext_value = azuread_application.webapp_sp[0].application_id

  depends_on = [
    github_repository_environment.all
  ]
}

resource "github_actions_environment_secret" "sp_client_secret" {
  for_each        = var.app_config.add_testing_slot ? local.branches_and_envs : {}
  repository      = local.github_repository_name
  environment     = each.value
  secret_name     = "ARM_CLIENT_SECRET"
  plaintext_value = azuread_application_password.webapp_sp[0].value

  depends_on = [
    github_repository_environment.all
  ]
}

resource "github_actions_environment_secret" "tenant_id" {
  for_each        = var.app_config.add_testing_slot ? local.branches_and_envs : {}
  repository      = local.github_repository_name
  environment     = each.value
  secret_name     = "ARM_TENANT_ID"
  plaintext_value = data.azurerm_client_config.current.tenant_id

  depends_on = [
    github_repository_environment.all
  ]
}

resource "github_actions_environment_secret" "subscription_id" {
  for_each        = var.app_config.add_testing_slot ? local.branches_and_envs : {}
  repository      = local.github_repository_name
  environment     = each.value
  secret_name     = "ARM_SUBSCRIPTION_ID"
  plaintext_value = data.azurerm_client_config.current.subscription_id

  depends_on = [
    github_repository_environment.all
  ]
}

resource "github_actions_environment_secret" "webapp_id" {
  for_each        = var.app_config.add_testing_slot ? local.branches_and_envs : {}
  repository      = local.github_repository_name
  environment     = each.value
  secret_name     = "WEBAPP_ID"
  plaintext_value = azurerm_linux_web_app.app.id

  depends_on = [
    github_repository_environment.all
  ]
}

resource "github_actions_environment_secret" "slot_name" {
  for_each        = var.app_config.add_testing_slot ? local.branches_and_envs : {}
  repository      = local.github_repository_name
  environment     = each.value
  secret_name     = "SLOT_NAME"
  plaintext_value = local.testing_slot_name

  depends_on = [
    github_repository_environment.all
  ]
}

resource "github_repository_file" "deploy_workflows" {
  for_each            = local.envs_and_workflow_templates
  repository          = local.github_repository_name
  branch              = "main"
  file                = ".github/workflows/deploy_${each.key}.yml"
  content             = each.value
  commit_message      = "Add workflow (managed by Terraform)"
  commit_author       = "Terraform"
  commit_email        = "terraform@flowehr.io"
  overwrite_on_create = true

  depends_on = [
    # Only create these on main otherwise they will be triggered on push
    github_branch.all
  ]
}
