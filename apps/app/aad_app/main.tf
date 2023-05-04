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

resource "azuread_application" "webapp_auth" {
  display_name    = "flowehr-${var.auth_webapp_name}"
  owners          = [data.azurerm_client_config.current.object_id]
  identifier_uris = ["api://${var.auth_webapp_name}"]

  required_resource_access {
    resource_app_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph

    resource_access {
      id   = azuread_service_principal.msgraph.oauth2_permission_scope_ids["User.Read"]
      type = "Scope"
    }
  }

  api {
    oauth2_permission_scope {
      admin_consent_description  = "Allow the application to access ${var.auth_webapp_name} on behalf of the signed-in user."
      admin_consent_display_name = "Access ${var.auth_webapp_name}"
      enabled                    = true
      id                         = random_uuid.webapp_oauth2_id.result
      type                       = "User"
      user_consent_description   = "Allow the application to access ${var.auth_webapp_name} on your behalf."
      user_consent_display_name  = "Access ${var.auth_webapp_name}"
      value                      = "user_impersonation"
    }
  }

  web {
    homepage_url  = "https://${var.auth_webapp_name}.azurewebsites.net"
    redirect_uris = ["https://${var.auth_webapp_name}.azurewebsites.net/.auth/login/aad/callback"]

    implicit_grant {
      id_token_issuance_enabled = true
    }
  }
}

resource "azuread_application_password" "webapp_auth" {
  application_object_id = azuread_application.webapp_auth.object_id
}

# store client ID and secret in serve key vault for cross-app authentication
resource "azurerm_key_vault_secret" "client_id" {
  name         = "${var.auth_webapp_name}-client-id"
  value        = azuread_application.webapp_auth.application_id
  key_vault_id = var.serve_key_vault_id
}

resource "azurerm_key_vault_secret" "client_secret" {
  name         = "${var.auth_webapp_name}-client-secret"
  value        = azuread_application_password.webapp_auth.value
  key_vault_id = var.serve_key_vault_id
}
