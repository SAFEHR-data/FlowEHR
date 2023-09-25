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

# Required diagnostics for Application Insights Dashboard
resource "azurerm_monitor_diagnostic_setting" "logs_and_metrics" {
  name                       = "metrics-logs-diagnostics-${replace(var.app_id, "_", "-")}"
  target_resource_id         = azurerm_linux_web_app.app.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.core.id


  dynamic "enabled_log" {
    for_each = toset(["AppServiceHTTPLogs", "AppServiceConsoleLogs", "AppServiceAppLogs", "AppServiceAuditLogs", "AppServiceIPSecAuditLogs", "AppServicePlatformLogs"])

    content {
      category = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = toset(["AllMetrics"])

    content {
      category = metric.value
    }
  }
}
