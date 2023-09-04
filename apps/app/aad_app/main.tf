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

resource "random_uuid" "webapp_oauth2_id" {}

resource "azuread_service_principal" "msgraph" {
  application_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph
  use_existing   = true
}

resource "random_uuid" "app_role_guids" {
  for_each = { for r in local.app_roles_safe : r.value => r }
}

resource "azuread_application" "webapp_auth" {
  display_name    = "flowehr-${var.webapp_name}"
  owners          = [data.azurerm_client_config.current.object_id]
  identifier_uris = [local.app_identifier_uri]

  required_resource_access {
    resource_app_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph

    resource_access {
      id   = azuread_service_principal.msgraph.oauth2_permission_scope_ids["User.Read"]
      type = "Scope"
    }
  }

  api {
    oauth2_permission_scope {
      admin_consent_description  = "Allow the application to access ${var.webapp_name} on behalf of the signed-in user."
      admin_consent_display_name = "Access ${var.webapp_name}"
      enabled                    = true
      id                         = random_uuid.webapp_oauth2_id.result
      type                       = "User"
      user_consent_description   = "Allow the application to access ${var.webapp_name} on your behalf."
      user_consent_display_name  = "Access ${var.webapp_name}"
      value                      = "user_impersonation"
    }
  }

  dynamic "web" {
    for_each = var.auth_settings.easy_auth ? [1] : []

    content {
      homepage_url = "https://${var.webapp_name}.azurewebsites.net"
      redirect_uris = compact(concat([
        "https://${var.webapp_name}.azurewebsites.net/.auth/login/aad/callback",
        length(var.testing_slot_webapp_name) > 0 ? "https://${var.testing_slot_webapp_name}.azurewebsites.net/.auth/login/aad/callback" : null
      ]))

      implicit_grant {
        id_token_issuance_enabled = true
      }
    }
  }

  dynamic "single_page_application" {
    for_each = try(var.auth_settings.single_page_application, null) != null ? [1] : []

    content {
      redirect_uris = compact(concat([
        "https://${var.webapp_name}.azurewebsites.net/",
        length(var.testing_slot_webapp_name) > 0 ?
        "https://${var.testing_slot_webapp_name}.azurewebsites.net/" :
        null
        ],
        var.auth_settings.single_page_application.additional_redirect_uris
      ))
    }
  }

  dynamic "app_role" {
    for_each = toset(local.app_roles_safe)

    content {
      id                   = random_uuid.app_role_guids[app_role.value.value].result
      value                = app_role.value.value
      display_name         = app_role.value.display_name
      description          = app_role.value.description
      allowed_member_types = ["User", "Application"]
      enabled              = true
    }
  }
}

resource "azuread_application_password" "webapp_auth" {
  application_object_id = azuread_application.webapp_auth.object_id
}

# store client ID and secret in serve key vault for cross-app authentication
resource "azurerm_key_vault_secret" "client_id" {
  name         = "${var.webapp_name}-client-id"
  value        = azuread_application.webapp_auth.application_id
  key_vault_id = var.serve_key_vault_id
}

resource "azurerm_key_vault_secret" "client_secret" {
  name         = "${var.webapp_name}-client-secret"
  value        = azuread_application_password.webapp_auth.value
  key_vault_id = var.serve_key_vault_id
}
