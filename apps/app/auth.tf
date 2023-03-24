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

resource "azuread_service_principal" "msgraph" {
  application_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph
  use_existing   = true
}

resource "random_uuid" "webapp_oauth2_id" {
  for_each = local.auth_webapp_names
}

resource "azuread_application" "webapp_auth" {
  for_each        = local.auth_webapp_names
  display_name    = "flowehr-${each.value}"
  owners          = [data.azurerm_client_config.current.object_id]
  identifier_uris = ["api://${each.value}"]

  required_resource_access {
    resource_app_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph

    resource_access {
      id   = azuread_service_principal.msgraph.oauth2_permission_scope_ids["User.Read"]
      type = "Scope"
    }
  }

  api {
    oauth2_permission_scope {
      admin_consent_description  = "Allow the application to access ${each.value} on behalf of the signed-in user."
      admin_consent_display_name = "Access ${each.value}"
      enabled                    = true
      id                         = random_uuid.webapp_oauth2_id[each.value].result
      type                       = "User"
      user_consent_description   = "Allow the application to access ${each.value} on your behalf."
      user_consent_display_name  = "Access ${each.value}"
      value                      = "user_impersonation"
    }
  }

  web {
    homepage_url  = "https://${each.value}.azurewebsites.net"
    redirect_uris = ["https://${each.value}.azurewebsites.net/.auth/login/aad/callback"]

    implicit_grant {
      id_token_issuance_enabled = true
    }
  }
}

resource "azuread_application_password" "webapp_auth" {
  for_each              = local.auth_webapp_names
  application_object_id = azuread_application.webapp_auth[each.value].object_id
}
