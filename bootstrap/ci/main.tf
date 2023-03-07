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

module "naming" {
  source      = "../shared/naming"
  id          = var.id
  environment = "ci"
}

module "management" {
  source                  = "../shared/management"
  naming_suffix           = module.naming.suffix
  naming_suffix_truncated = module.naming.suffix_truncated
  location                = var.location
}

# Get the MS Graph app 
resource "azuread_service_principal" "msgraph" {
  application_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph
  use_existing   = true
}

resource "azuread_application" "ci_app" {
  display_name = "sp-flowehr-cicd-${lower(module.naming.suffix)}"
  owners       = [data.azurerm_client_config.current.object_id]

  required_resource_access {
    resource_app_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph

    resource_access {
      id   = azuread_service_principal.msgraph.app_role_ids["Application.ReadWrite.All"]
      type = "Role"
    }

    resource_access {
      id   = azuread_service_principal.msgraph.app_role_ids["AppRoleAssignment.ReadWrite.All"]
      type = "Role"
    }
  }
}

resource "azuread_application_password" "ci_app" {
  application_object_id = azuread_application.ci_app.object_id
}

resource "azuread_service_principal" "ci_app" {
  application_id = azuread_application.ci_app.application_id
  owners         = [data.azurerm_client_config.current.object_id]
}

# app role assignments for service principals to grant admin consent
resource "azuread_app_role_assignment" "app_readwrite_all" {
  app_role_id         = azuread_service_principal.msgraph.app_role_ids["Application.ReadWrite.All"]
  principal_object_id = azuread_service_principal.ci_app.id
  resource_object_id  = azuread_service_principal.msgraph.object_id
}

resource "azuread_app_role_assignment" "approleassignment_readwrite_all" {
  app_role_id         = azuread_service_principal.msgraph.app_role_ids["AppRoleAssignment.ReadWrite.All"]
  principal_object_id = azuread_service_principal.ci_app.id
  resource_object_id  = azuread_service_principal.msgraph.object_id
}

# make owner of Azure sub
resource "azurerm_role_assignment" "ci_app_owner" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Owner"
  principal_id         = azuread_service_principal.ci_app.id
}
