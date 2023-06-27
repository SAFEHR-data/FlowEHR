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

resource "github_repository" "app" {
  count       = local.create_repo ? 1 : 0
  name        = var.app_id
  description = var.app_config.description
  visibility  = var.app_config.managed_repo.private ? "private" : "public"

  template {
    owner      = split("/", var.app_config.managed_repo.template)[0]
    repository = split("/", var.app_config.managed_repo.template)[1]
  }
}

resource "github_team" "owners" {
  count       = local.create_repo ? 1 : 0
  name        = "${var.app_id} - owners"
  description = "Owners of the ${var.app_id} FlowEHR app with push and PR/deployment approval permissions."
  privacy     = "closed"
}

resource "github_team_membership" "owners" {
  for_each = local.create_repo ? var.app_config.owners : tomap({})
  team_id  = github_team.owners[0].id
  username = each.key
  role     = "maintainer"
}

resource "github_team_repository" "owners_repo_permissions" {
  count      = local.create_repo ? 1 : 0
  team_id    = github_team.owners[0].id
  repository = local.github_repository_name
  permission = "push"
}

resource "github_repository_file" "codeowners" {
  count               = local.create_repo ? 1 : 0
  repository          = local.github_repository_name
  branch              = "main"
  file                = "CODEOWNERS"
  content             = <<EOF
# Owners for branch protection
# Users within this team are required reviewers for this deployment branch
*       @${var.github_owner}/${github_team.owners[0].slug}
EOF
  commit_message      = "Add codeowners (managed by Terraform)"
  commit_author       = "Terraform"
  commit_email        = "terraform@flowehr.io"
  overwrite_on_create = true

  depends_on = [
    github_repository.app
  ]
}

resource "github_team" "contributors" {
  count       = local.create_repo ? 1 : 0
  name        = "${var.app_id} - contributors"
  description = "Contributors to the ${var.app_id} FlowEHR app with push permissions."
  privacy     = "closed"
}

resource "github_team_membership" "contributors" {
  for_each = local.create_repo ? var.app_config.contributors : tomap({})
  team_id  = github_team.contributors[0].id
  username = each.key
  role     = "member"
}

resource "github_team_repository" "contributors_repo_permissions" {
  count      = local.create_repo ? 1 : 0
  team_id    = github_team.contributors[0].id
  repository = local.github_repository_name
  permission = "push"
}
