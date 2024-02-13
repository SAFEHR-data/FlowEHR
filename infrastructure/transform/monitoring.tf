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


resource "azurerm_application_insights" "transform" {
  name                = "transform-ai-${var.naming_suffix}"
  location            = var.core_rg_location
  resource_group_name = var.core_rg_name
  application_type    = "web"
  tags                = var.tags
}

resource "azurerm_portal_dashboard" "pipeline_status_dashboard" {
  for_each             = { for pipeline in local.pipelines : pipeline.name => pipeline.json }
  name                 = "${each.value.name}StatusDashboard"
  location             = var.core_rg_location
  resource_group_name  = var.core_rg_name
  dashboard_properties = <<EOF
{
    "lenses": {
      "0": {
        "order": 0,
        "parts": {
          "0": {
            "position": {
              "x": 0,
              "y": 0,
              "colSpan": 6,
              "rowSpan": 4
            },
            "metadata": {
              "inputs": [
                {
                  "name": "options",
                  "isOptional": true
                },
                {
                  "name": "sharedTimeRange",
                  "isOptional": true
                }
              ],
              "type": "Extension/HubsExtension/PartType/MonitorChartPart",
              "settings": {
                "content": {
                  "options": {
                    "chart": {
                      "metrics": [
                        {
                          "resourceMetadata": {
                            "id": "${azurerm_data_factory.adf.id}"
                          },
                          "name": "PipelineSucceededRuns",
                          "aggregationType": 1,
                          "namespace": "microsoft.datafactory/factories",
                          "metricVisualization": {
                            "displayName": "Succeeded pipeline runs metrics",
                            "resourceDisplayName": "${azurerm_data_factory.adf.name}"
                          }
                        }
                      ],
                      "title": "Succeeded pipeline runs metrics for ${each.value.name}",
                      "titleKind": 1,
                      "visualization": {
                        "chartType": 2,
                        "legendVisualization": {
                          "isVisible": true,
                          "position": 2,
                          "hideSubtitle": false
                        },
                        "axisVisualization": {
                          "x": {
                            "isVisible": true,
                            "axisType": 2
                          },
                          "y": {
                            "isVisible": true,
                            "axisType": 1
                          }
                        },
                        "disablePinning": true
                      }
                    }
                  }
                }
              }
            }
          },
          "1": {
            "position": {
              "x": 6,
              "y": 0,
              "colSpan": 6,
              "rowSpan": 4
            },
            "metadata": {
              "inputs": [
                {
                  "name": "options",
                  "isOptional": true
                },
                {
                  "name": "sharedTimeRange",
                  "isOptional": true
                }
              ],
              "type": "Extension/HubsExtension/PartType/MonitorChartPart",
              "settings": {
                "content": {
                  "options": {
                    "chart": {
                      "metrics": [
                        {
                          "resourceMetadata": {
                            "id": "${azurerm_data_factory.adf.id}"
                          },
                          "name": "PipelineFailedRuns",
                          "aggregationType": 1,
                          "namespace": "microsoft.datafactory/factories",
                          "metricVisualization": {
                            "displayName": "Failed pipeline runs metrics",
                            "resourceDisplayName": "${azurerm_data_factory.adf.name}"
                          }
                        }
                      ],
                      "title": "Failed pipeline runs for ${each.value.name}",
                      "titleKind": 1,
                      "visualization": {
                        "chartType": 2,
                        "legendVisualization": {
                          "isVisible": true,
                          "position": 2,
                          "hideSubtitle": false
                        },
                        "axisVisualization": {
                          "x": {
                            "isVisible": true,
                            "axisType": 2
                          },
                          "y": {
                            "isVisible": true,
                            "axisType": 1
                          }
                        },
                        "disablePinning": true
                      }
                    }
                  }
                }
              }
            }
          },
          "2": {
            "position": {
              "x": 0,
              "y": 4,
              "colSpan": 6,
              "rowSpan": 4
            },
            "metadata": {
              "inputs": [
                {
                  "name": "options",
                  "isOptional": true
                },
                {
                  "name": "sharedTimeRange",
                  "isOptional": true
                }
              ],
              "type": "Extension/HubsExtension/PartType/MonitorChartPart",
              "settings": {
                "content": {
                  "options": {
                    "chart": {
                      "metrics": [
                        {
                          "resourceMetadata": {
                            "id": "${azurerm_application_insights.transform.id}"
                          },
                          "name": "${each.key}/${local.predefined_metric_name}",
                          "aggregationType": 4,
                          "namespace": "${each.key}/${local.predefined_metric_name}",
                          "metricVisualization": {
                            "displayName": "${each.key}/${local.predefined_metric_name}"
                          }
                        }
                      ],
                      "title": "Rows inserted by table_name",
                      "titleKind": 1,
                      "visualization": {
                        "chartType": 2,
                        "legendVisualization": {
                          "isVisible": true,
                          "position": 2,
                          "hideSubtitle": false
                        },
                        "axisVisualization": {
                          "x": {
                            "isVisible": true,
                            "axisType": 2
                          },
                          "y": {
                            "isVisible": true,
                            "axisType": 1
                          }
                        },
                        "disablePinning": true
                      },
                      "grouping": {
                        "dimension": "table_name",
                        "sort": 2,
                        "top": 30
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    },
    "metadata": {
      "model": {
        "timeRange": {
          "value": {
            "relative": {
              "duration": 24,
              "timeUnit": 1
            }
          },
          "type": "MsPortalFx.Composition.Configuration.ValueTypes.TimeRange"
        },
        "filterLocale": {
          "value": "en-us"
        },
        "filters": {
          "value": {
            "MsPortalFx_TimeRange": {
              "model": {
                "format": "utc",
                "granularity": "auto",
                "relative": "24h"
              },
              "displayCache": {
                "name": "UTC Time",
                "value": "Past 24 hours"
              }
            }
          }
        }
      }
    }
}
EOF
}
